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
        disp(sprintf('\n%s object: Event type: %s',class(obj(c)),obj(c).request.subclass));
        catch

        end
        fprintf('Number of events: %d\n',obj(c).numberOfEvents);
        try
        fprintf('Cumulative magnitude: %.2f\n',obj(c).cum_mag  );
        end
        if obj(c).numberOfEvents > 0
            [maxmag, maxmagindex] = nanmax(obj(c).mag);
            if ~isnan(maxmag)
                fprintf('Biggest event: %.2f at %s\n',maxmag, datestr(obj(c).otime(maxmagindex)));
            end
            if ~exist('showall','var')
                    showall = false;
            end
            if numel(obj) == 1
                disp_title(obj);
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

function disp_title(obj)
    fprintf('Event');
    %if ~isempty(obj.otime)
    if sum(~isnan(obj.otime))
        fprintf('\tOriginTime             ');
    end
    if sum(~isnan(obj.ontime))
        fprintf('\tOnTime             ');
    end  
    if sum(~isnan(obj.offtime))
        fprintf('\tOffTime             ');
    end
    if sum(~isnan(obj.offtime))
        fprintf('\tDuration');
    end    
    if sum(~isnan(obj.lat))
        fprintf('\tLat');
    end    
    if sum(~isnan(obj.lon))
        fprintf('\tLon');
    end 
    if sum(~isnan(obj.depth))
        fprintf('\tDepth');
    end        
    if sum(~isnan(obj.mag))
        fprintf('\tMag');
    end     
    if sum(~strcmp(obj.magtype,'u'))
        fprintf('\tMagType');
    end  
    if sum(~strcmp(obj.etype,'u'))
        fprintf('\tClass');
    end  
    fprintf('\n');
end

function disp_event(obj, eventnum)
    %l = length(num2str(cobj.numberOfEvents)) + 1;
    fprintf('%4d',eventnum);
    if sum(~isnan(obj.otime))
        fprintf('\t%s',datestr(obj.otime(eventnum), 'yyyy-mm-dd HH:MM.SS.FFF') );
    end
    if sum(~isnan(obj.ontime))
        fprintf('\t%s',datestr(obj.ontime(eventnum), 'yyyy-mm-dd HH:MM.SS.FFF') );
    end  
    if sum(~isnan(obj.offtime))
        fprintf('\t%s',datestr(obj.offtime(eventnum), 'yyyy-mm-dd HH:MM.SS.FFF') );
    end
    if sum(~isnan(obj.offtime))
        fprintf('\t%.4f s', obj.duration(eventnum) );
    end        
    if sum(~isnan(obj.lat))
        fprintf('\t%.4f', obj.lat(eventnum) );
    end    
    if sum(~isnan(obj.lon))
        fprintf('\t%.4f', obj.lon(eventnum) );
    end 
    if sum(~isnan(obj.depth))
        fprintf('\t%.2f', obj.depth(eventnum) );
    end        
    if sum(~isnan(obj.mag))
        fprintf('\t%.1f', obj.mag(eventnum) );
    end 
    if sum(~strcmp(obj.magtype,'u'))
        fprintf('\t%s', obj.magtype{eventnum} );
    end  
    if sum(~strcmp(obj.etype,'u'))
        fprintf('\t%s', obj.etype{eventnum} );
    end  
    fprintf('\n');    
end
