function [catalogobj, arrivalobj] = associate(arrivalobj, maxTimeDiff, sites, source)
%ASSOCIATE Associate arrivals into events
% [catalogobj] = associate(arrivals, maxTimeDiff) will scan through an
% arrivals object and look for times where there are at least 2 arrivals on
% within maxTimeDiff seconds of each other, and declare an event. No 
% checking is done to see if arrivals are on different channels
%
% [catalogobj, arrivalobj] = associate(arrivals, maxTimeDiff, sites) will
% reduce the arrival times by traveltimes in the sites structure. This
% allows a smaller maxTimeDiff to be used (since all airwaves should now
% line up, and all P waves etc.). These traveltimes are in the returned
% arrivalobj.
%
% Example: Imagine you have an infrasound array and you have marked
% infrasound events manually (or automatically) with an "N" phase, picking
% an "N" on at least two channels. You also notice that the time to cross
% the array is less than 0.1s (e.g. array less than 34m across if sound
% speed is 340m/s). Then the following code will load the arrivals, subset
% for "N" phases, and associate into events wherever 2 channels have an "N"
% pick within 0.1s. The final line returns a Catalog object - the GISMO
% container for multiple events.
%   
%   dbpath = '/raid/data/sakurajima/db'; 
%   arrivalobj = Arrival.retrieve('antelope', dbpath); 
%   arrivalobj = arrivalobj.subset('iphase', 'N'); 
%   catalogobj = arrivalobj.associate(0.1);        

%% REDUCE BY SUBTRACTING TRAVEL TIME
% If sites exist, let's correct the arrival times first
%
% Author: Glenn Thompson

if exist('sites','var')
    arrivalobj.traveltime = NaN(size(arrivalobj.time));

    for c = 1:numel(sites)
        thischanstr = sites(c).channeltag.string();

        if strcmp(thischanstr(end-2),'_')
            thischanstr = thischanstr(1:end-3);
        end

        i = strcmp(arrivalobj.channelinfo, thischanstr);
        arrivalobj.traveltime(i) = sites(c).traveltime;
        arrivalobj.time(i) = arrivalobj.time(i) - sites(c).traveltime/86400;
    end
end

[arrtimes,indices] = sort(arrivalobj.time);
arrivalobj = arrivalobj.subset(indices);

fprintf('\nFinding arrivals within %.3f s\n', maxTimeDiff);

for c = 1:numel(arrtimes)
    associated_indices{c} = ...
        find(arrtimes >= arrtimes(c) & ...
             arrtimes <= arrtimes(c)+maxTimeDiff/86400); %#ok<AGROW>

    numarrivals(c) = numel(associated_indices{c}); %#ok<AGROW>
end

numarrivals = [numarrivals(1) diff(numarrivals)+1];
numarrivals(numarrivals<=1) = 0;

eventnum = 0;
duplicatecount = 0;

for c = 1:numel(numarrivals)

    if numarrivals(c) > 0
        eventarrivalobj = arrivalobj.subset(c:c+numarrivals(c)-1);

        [uc,ia] = unique(eventarrivalobj.channelinfo,'stable');
        duplicatecount = duplicatecount + ...
            numel(eventarrivalobj.channelinfo) - numel(uc);

        if numel(ia) > 1
            eventarrivalobj = eventarrivalobj.subset(ia);

            eventnum = eventnum + 1;
            otime(eventnum) = arrtimes(c); %#ok<AGROW>

            arrivalobj2{eventnum} = eventarrivalobj; %#ok<AGROW>
            firstArrivalTime(eventnum) = min(eventarrivalobj.time); %#ok<AGROW>
            lastArrivalTime(eventnum)  = max(eventarrivalobj.time); %#ok<AGROW>
        end
    end
end

if exist('sites','var')
    arrivalobj.time = arrivalobj.time + arrivalobj.traveltime/86400;
end

if exist('source','var')
    olon = source.lon * ones(size(otime));
    olat = source.lat * ones(size(otime));
else
    olon = NaN(size(otime));
    olat = NaN(size(otime));
end

catalogobj = Catalog(otime, olon, olat, [], [], {}, {}, ...
    'ontime', firstArrivalTime, ...
    'offtime', lastArrivalTime);

catalogobj.arrivals = arrivalobj2;

fprintf('%d duplicates removed\n', duplicatecount);
end

