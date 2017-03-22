function arrivalObj = read_antelope(dbname, subset_expr)
% LOAD_ARRIVALS Load arrivals from a CSS3.0 database
            if ~(antelope.dbtable_present(dbname, 'arrival'))
                fprintf('No arrival table belonging to %s\n',dbname);
                return
            end
            
            fprintf('Loading arrivals from %s\n',dbname);

            % Open database
            db = dbopen(dbname,'r');
            disp('- database opened');

            % Apply subset expression
            db = dblookup_table(db,'arrival');
            disp('- arrival table opened');
            if exist('subset_expr','var')
                db = dbsubset(db,subset_expr);
                disp('- subsetted database')
            end
            
            nrows = dbnrecs(db);
            if nrows > 0

                % Sort by arrival time
                db = dbsort(db,'time');
                disp('- sorted arrival table')

                % Get the values
                fprintf('- reading %d rows\n',nrows);
                [sta,chan,time,amp,signal2noise,iphase] = dbgetv(db,'sta','chan','time','amp','snr','iphase');

                % Close database link
                dbclose(db);
                disp('- database closed')

                % Create arrival object
                disp('- creating arrival object')
                arrivalObj = Arrival(cellstr(sta), cellstr(chan), epoch2datenum(time), cellstr(iphase), 'amp', amp, 'signal2noise', signal2noise);
                
                disp('- complete!')
            else
                fprintf('No arrivals found matching request\n');
            end

end
