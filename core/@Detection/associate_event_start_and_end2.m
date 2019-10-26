function catalogobj = associate(obj, maxTimeDiff, sites, source)


%     % HERE RUN AS NORMAL ON THE "D" OR "ON" DETECTIONS
%     if exist('sites', 'var')
%         if exist('source', 'var')
%             catalogobj = associate(obj, maxTimeDiff, sites, source);
%         else
%             catalogobj = associate(obj, maxTimeDiff, sites);
%         end
%     else
%         catalogobj = associate(obj, maxTimeDiff);
%     end
    
    % break up detection types HERE WE USE ONLY OFF
    event.ontime = [];
    event.offtime = [];
    event.numdetections = [];
    eventnum = 0;
    detmode = 'NONE';
    obj.state
    for dn = 1:numel(obj.time)
        if ~strcmp(obj.state(dn),detmode) % change of state
            if strcmp(obj.state(dn),'ON') 
                eventnum = eventnum + 1;
                event.ontime(eventnum) = obj.time(dn);
                event.numdetections(eventnum) = 0;
                detmode = 'ON';
            end
        end
        if strcmp(obj.state(dn),'ON') % count ON detections for each event
            event.numdetections(eventnum) = event.numdetections(eventnum) + 1;
        else
            event.offtime(eventnum) = obj.time(dn);
        end
    end
    
    
                
    event
    
    otime = event.ontime;

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
    catalogobj = Catalog(otime, olon, olat, [], [], {}, {}, 'ontime', event.ontime, 'offtime', event.offtime);

end
