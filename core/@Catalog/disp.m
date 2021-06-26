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
                N = obj(c).numberOfEvents;
                %if obj(c).numberOfEvents <= 50 || showall
                    rows_to_show = unique([1:5 N-4:N]);
                    rows_to_show = rows_to_show(rows_to_show > 0 & rows_to_show < N);
                %else
                %    rows_to_show = 50;
                %    disp('* Only showing first 50 rows/events - to see all rows/events use:')
                %    disp('*      catalogObject.disp(true)')
                %end
                for eventnum=rows_to_show
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
        fprintf('\t   Lat');
    end    
    if sum(~isnan(obj.lon))
        fprintf('\t   Lon');
    end 
    if sum(~isnan(obj.depth))
        fprintf('\t\tDepth');
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
        if ~isnan(obj.offtime(eventnum))
            fprintf('\t%s',datestr(obj.offtime(eventnum), 'yyyy-mm-dd HH:MM.SS.FFF') );
        else
            fprintf('\t%s','                       ' );
        end
    end
    if sum(~isnan(obj.offtime))
        if ~isnan(obj.offtime(eventnum))        
            fprintf('\t%6.2f s', obj.duration(eventnum) );
        else
            fprintf('\t%        ');
        end            
    end        
    if sum(~isnan(obj.lat))
        fprintf('\t%7.4f', obj.lat(eventnum) );
    end    
    if sum(~isnan(obj.lon))
        fprintf('\t%8.4f', obj.lon(eventnum) );
    end 
    if sum(~isnan(obj.depth))
        fprintf('\t%6.2f', obj.depth(eventnum) );
    end        
    if sum(~isnan(obj.mag))
        fprintf('\t%3.1f', obj.mag(eventnum) );
    end 
    if sum(~strcmp(obj.magtype,'u'))
        fprintf('\t%s', obj.magtype{eventnum} );
    end  
    if sum(~strcmp(obj.etype,'u'))
        fprintf('\t%s', obj.etype{eventnum} );
    end  
    fprintf('\n');    
end
