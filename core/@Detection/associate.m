function catalogobj = associate(obj, maxTimeDiff, sites, source)
%ASSOCIATE Associate detections into events
% catalogobj = associate(detectionObj, maxTimeDiff) will scan through an
% Detection object and look 
% for times where there are at least 2 detections on
% within maxTimeDiff seconds of each other, and declare an event. No 
% checking is done to see if arrivals are on different channels
%
% catalogobj = associate(arrivals, maxTimeDiff, sites) will
% reduce the detection times by traveltimes in the sites structure. This
% allows a smaller maxTimeDiff to be used (since all airwaves should now
% line up, and all P waves etc.). 
%
% Example: Imagine you have run dbdetect. You also notice that the time to cross
% the network is less than 30s. Then the following code will load the detections, subset
% for "D" states, and associate into events wherever 2 channels have an "D"
% detection within 30s. The final line returns a Catalog object - the GISMO
% container for multiple events.
%   
%   dbpath = '/home/t/thompsong/NEWTON/pavlof2007'; 
%   detobj = Detection.retrieve(dbpath, 'status=~/D/'); 
%   catalogobj = detobj.associate(30);
%
% A significant problem is that there may be more than 1 event in a
% 30-second window. So a different approach is to apply a differential
% travel time correction to each detection, to reduce it to a known source
% location. Then a wave might propagate across the reduced network in a
% time of 1-second, for example, allowing multiple events to be detected in
% a 30-seconds time window.
%
%   dbpath = '/home/t/thompsong/NEWTON/pavlof2007/db'; 
%   detobj = Detection.retrieve(dbpath, 'status=~/D/');
%   sites = antelope.dbget_site_locations(dbpath, unique(detobj.channelinfo))
%   source.lat = 55.4203;
%   source.lon = -161.8931;
%   wavespeed = 330; % m/s
%   difftt = calc_traveltime(source, sites, wavespeed);
%   source.lat = 55.4173; source.lon = -161.8937; elev = 2.518;
%   chantags = ChannelTag(unique(detobj.channelinfo))
%   sites = antelope.dbget_site_locations(dbpath, chantags, startTime, endTime);
%   seismicspeed = 330; infrasoundspeed = 330; % m/s
%   sites = compute_travel_times(source, sites, seismicspeed, infrasoundspeed);
%   association_time_window = 2; % max seconds from seismic to infrasound arrival
%   catalogobj = detobj.associate(maxtimediff, sites);

    % break up detection types
    detections_on = obj.subset('state', 'ON');
    detections_d = obj.subset('state', 'D');
    detections_off = obj.subset('state', 'OFF');
    if detections_d.numel > 0
        obj = detections_d;
    elseif detections_on.numel > 0
        obj = detections_on;
    end

    %% REDUCE BY SUBTRACTING TRAVEL TIME
    % If sites exist, let's correct the arrival times first
    if exist('sites', 'var')
        disp('Reducing travel times')
        obj.traveltime = NaN(size(obj.time));
        for c=1:numel(sites)
            thissite = sites(c);
            thischanstr = thissite.channeltag.string();
            i = strcmp(obj.channelinfo, thischanstr)==1;
            obj.traveltime(i) = sites(c).traveltime;
            obj.time(i) = obj.time(i) - sites(c).traveltime/86400;      
        end
    end
    % sort obj in ascending time order
    disp('Sorting')
    [detection_time,indices]=sort(obj.time);  
    obj = obj.subset(indices);

    % First we begin with each detection and find how many detections occur in the
    % maxTimeDiff seconds that follow. This way each arrival is assigned a
    % weight equal to that number of detections. The point of this is to help us
    % identify the beginning of each event.
    fprintf('\nFinding how many detections within %e sec of each detection\n',maxTimeDiff)
    for c=1:numel(detection_time)
        associated_indices{c} = find(detection_time>=detection_time(c) & detection_time<=detection_time(c)+maxTimeDiff/86400);
        numdetections(c) = numel(associated_indices{c});
    end

    % remove decrementing series, e.g. replace sequence 
    % like 6 5 4 3 2 1 with 6 0 0 0 0 0
    disp('Removing decrementing series')
    numdetections = [numdetections(1) diff(numdetections)+1];
    %numdetections(numdetections<=1)=0;


    % Now loop over numdetections and create events
    fprintf('Making events')
    eventnum = 0;
    duplicatecount = 0;
    for c=1:numel(numdetections)
        fprintf('.')
        if numdetections(c)>0
            fprintf('*')
            eventnum = eventnum + 1;
            otime(eventnum) = detection_time(c);
    %         lastDetectionTime(eventnum) = detection_time(c + numdetections(c) - 1);

            try
                eventdetobj = obj.subset([c : c + numdetections(c) - 1]);
            catch
                numdetections(c)
                c+numdetections(c)-1
                numel(numdetections)
                rethrow();
            end

            % remove the reduced time
            if exist('sites','var')
                for cc=1:numel(eventdetobj.time)
                    eventdetobj.time(cc) = eventdetobj.time(cc) + eventdetobj.traveltime(cc)/86400;
                end
            end
            
            % remove duplicate channels
            [uc,ia]  = unique(eventdetobj.channelinfo, 'stable');
            duplicatecount = duplicatecount + numel(eventdetobj.channelinfo) - numel(uc);
            eventdetobj = eventdetobj.subset(ia);
                

            % set the arrivalobj for this event
            arrivalobj{eventnum} = detection2arrival(eventdetobj);
            firstDetectionTime(eventnum) = min(eventdetobj.time);
            lastDetectionTime(eventnum) = max(eventdetobj.time);        

        end
          
        if mod(c,30) == 0
            fprintf('\nProcessed %d out of %d\n',c, numel(numdetections));
        end
    end

    %% CREATE CATALOG
    if numel(otime)==0
        % no events
        catalogobj = Catalog();
        return
    end

    fprintf('\nCreating Catalog\n')
    olon=[];
    olat=[];
    if exist('source','var')
        olon = source.lon*ones(size(otime));
        olat = source.lat*ones(size(otime));
    end
    catalogobj = Catalog(otime, olon, olat, [], [], {}, {}, 'ontime', firstDetectionTime, 'offtime', lastDetectionTime);
    catalogobj.arrivals = arrivalobj;
    fprintf('%d detections were determined to be duplicates using a time window of %.1f seconds\n',duplicatecount, maxTimeDiff);
    

end

function arrivalobj = detection2arrival(detectionobj)
    if ~isa(detectionobj.channelinfo,'ChannelTag')
        ctag = ChannelTag(detectionobj.channelinfo);
    else
        ctag = detectionobj.channelinfo;
    end
    sta = get(ctag, 'station');
    chan = get(ctag, 'channel');
    arrivalobj = Arrival(cellstr(sta), cellstr(chan), detectionobj.time, ...
        cellstr(detectionobj.state), 'signal2noise', detectionobj.signal2noise);

end

% function result = alreadyHaveArrivalFromThisChannel(ctaglist, thisctag)
%   result = sum(cellfun(@(s) ~isempty(strfind(this
% end