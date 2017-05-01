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
        try
        disp(sprintf('%s object: Event type: %s',class(obj(c)),obj(c).request.subclass));
        catch

        end
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
                disp_title();
                if obj(c).numberOfEvents <= 50 || showall
                    rows_to_show = obj(c).numberOfEvents;
                else
                    rows_to_show = 50;
                    disp('* Only showing first 50 rows/events - to see all rows/events use:')
                    disp('*      catalogObject.disp(true)')
                end
                for eventnum=1:rows_to_show
                    disp_event(obj(c), eventnum);
                end

            end
        end
    end
end

function disp_title()
end

function disp_event(obj, eventnum)

end
