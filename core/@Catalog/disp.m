function disp(obj, showall)
% CATALOG.DISP Display Catalog object
% properties(obj)
% methods(obj)
% obj.table
% return
    class(obj)
    fprintf('Number of events: %d\n',obj.numberOfEvents);
    if obj.numberOfEvents > 0
        [maxmag, maxmagindex] = nanmax(obj.mag);
        fprintf('Biggest event: %f at %s\n',maxmag, datestr(obj.otime(maxmagindex)));
        if ~exist('showall','var')
            showall = false;
        end
        if height(obj.table) <= 50 || showall
            disp(obj.table)
        else
            disp(obj.table([1:50],:))

            disp('* Only showing first 50 rows/events - to see all rows/events use:')
            disp('*      catalogObject.disp(true)')
        end
    end
end