function arrivalObj = read_antelope(dbname, subset_expr)
% LOAD_ARRIVALS Load arrivals from a CSS3.0 database
            if ~(antelope.dbtable_present(dbname, 'arrival'))
                fprintf('No arrival table belonging to %s\n',dbname);
                return
            end
            
            fprintf('Loading arrivals from %s\n',dbname);

            % Open database
            db = dbopen(dbname,'r');

            % Apply subset expression
            db = dblookup_table(db,'arrival');
            if exist('subset_expr','var')
                db = dbsubset(db,subset_expr);
            end
            
            nrows = dbnrecs(db);
            if nrows > 0

                % Sort by arrival time
                db = dbsort(db,'time');

                % Get the values
                [sta,chan,time,amp,signal2noise,iphase] = dbgetv(db,'sta','chan','time','amp','snr','iphase');

                % Close database link
                dbclose(db);

                arrivalObj = Arrival(cellstr(sta), cellstr(chan), epoch2datenum(time), cellstr(iphase), 'amp', amp, 'signal2noise', signal2noise);
            else
                fprintf('No arrivals found matching request\n');
            end

end
