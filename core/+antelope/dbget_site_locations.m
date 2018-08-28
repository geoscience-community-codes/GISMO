function sites = dbget_site_locations(sitesdb, channeltags, snum, enum)
%DBGET_SITE_LOCATIONS Get sites from an Antelope database
% sites = DBGET_SITE_LOCATIONS(sitesdb, channeltags)
% sites = DBGET_SITE_LOCATIONS(sitesdb, channeltags, snum, enum)

% AUTHOR: Glenn Thompson
% $Date: $
% $Revision: -1 $
    debug.printfunctionstack('>')
    
    % If channeltags given as strings, convert to ChannelTag objects
    if isa(channeltags, 'cell')
        for c=1:numel(channeltags)
            ctag(c) = ChannelTag(channeltags{c});
        end
        channeltags = ctag;
    end

    debug.print_debug(1,sprintf('sites db is %s',sitesdb));
    dbptr = dbopen(sitesdb, 'r');

    % Filter the site table
    dbptr_site = dblookup_table(dbptr, 'site');
    nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
    debug.print_debug(2,sprintf('Site table has %d records', nrecs));


    if ~exist('snum', 'var')
        % No start time given, so assume we just want sites that exist today.
        % Remove any sites that have been decommissioned
        debug.print_debug(2,sprintf('offdate == NULL'));
        dbptr_site = dbsubset(dbptr_site, sprintf('offdate == NULL'));
    else
        % Remove any sites that were decommissioned before the start time
        debug.print_debug(2,sprintf('offdate == NULL || offdate > ''%d'' ',datenum2julday(snum)));
        dbptr_site = dbsubset(dbptr_site, sprintf('offdate == NULL || offdate > ''%d\'' ',datenum2julday(snum)));
    end
    nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
    debug.print_debug(2,sprintf('After startTime subset: %d records', nrecs));

    % Remove any sites that were installed after the end time (this may remove
    % some sites that exist today)
    if exist('enum', 'var')
        debug.print_debug(2, sprintf('ondate  < ''%d'' ',datenum2julday(enum)));
        dbptr_site = dbsubset(dbptr_site, sprintf('ondate  < ''%d'' ',datenum2julday(enum)));
    end

    nrecs = dbquery(dbptr_site, 'dbRECORD_COUNT');
    debug.print_debug(2,sprintf('After endTime subset: %d records', nrecs));
    if nrecs==0
        sites=struct();
        return
    end

    sta = dbgetv(dbptr_site, 'sta');
    %chan = dbgetv(dbptr_site, 'chan');
    lat = dbgetv(dbptr_site, 'lat');
    lon = dbgetv(dbptr_site, 'lon');
    elev = dbgetv(dbptr_site, 'elev');
    ondate = dbgetv(dbptr_site, 'ondate');
    offdate = dbgetv(dbptr_site, 'offdate');
    % calib = dbgetv(dbptr_calibration, 'calibration.calib');
    % units = dbgetv(dbptr_calibration, 'calibration.units');
    dbclose(dbptr);

    sites = struct();
    for c=1:numel(channeltags)
        ctag = channeltags(c);
        thissta = get(ctag,'station');
        i = find(strcmp(sta, thissta));
        if length(i)>0
            sites(c).channeltag = ctag;
            sites(c).lat = lat(i);
            sites(c).lon = lon(i);
            sites(c).elev = elev(i);
        else
            sites(c).channeltag = ctag;
            sites(c).lat = NaN;
            sites(c).lon = NaN;
            sites(c).elev = NaN;            
        end
    end


%     % Reformat data into sites return structure
%     numsites = numel(lat);
%     for c=1:numsites
%         yyyy = floor(ondate(c)/1000);
%         if yyyy>1900
%             jjj = ondate(c)-yyyy*1000;
%             ondnum(c) = datenum(yyyy,1,jjj);
%         else
%             ondnum(c)=-Inf;
%         end
%     end
% 
%     for c=1:numsites
%         yyyy = floor(offdate(c)/1000);
%         if yyyy>1900
%             jjj = offdate(c)-yyyy*1000;
%             offdnum(c) = datenum(yyyy,1,jjj);
%         else
%            offdnum(c) = Inf; 
%         end
%     end
% 
% 
%     % remove any duplicate sites
%     [~,j]=unique({sites.string});
%     sites = sites(j);


    debug.printfunctionstack('<')
end