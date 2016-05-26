function disp(obj, showall)
% CATALOG.DISP Display Catalog object
% properties(obj)
% methods(obj)
% obj.table
% return
for c=1:numel(obj)
%     subclass = '*';
%     if numel(obj)>1
%         subclass = obj(c).table.etype{1};
%     end
    disp(sprintf('%s object: Event type: %s',class(obj(c)),obj(c).request.subclass));
    fprintf('Number of events: %d\n',obj(c).numberOfEvents);
    if obj(c).numberOfEvents > 0
        [maxmag, maxmagindex] = nanmax(obj(c).mag);
        if ~isnan(maxmag)
            fprintf('Biggest event: %f at %s\n',maxmag, datestr(obj(c).otime(maxmagindex)));
        end
        if ~exist('showall','var')
                showall = false;
        end
        if numel(obj) == 1
            if height(obj.table) <= 50 || showall
                disp(obj.table)
            else
                disp(obj.table([1:50],:))

                disp('* Only showing first 50 rows/events - to see all rows/events use:')
                disp('*      catalogObject.disp(true)')
            end
%         else
%             disp(sprintf('Event type: %s',obj(c).table.etype{1}));
        end
    end
end
end