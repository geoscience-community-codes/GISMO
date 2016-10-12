function arrivalObj = read_antelope(dbname, subset_expr)
            % LOAD_ARRIVALS Load arrivals from a CSS3.0 database
            fprintf(2,'Loading arrivals from %s',dbname);

            % Open database
            db = dbopen(dbname,'r');

            % Apply subset expression
            db = dblookup_table(db,'arrival');
            if exist('subset_expr','var')
                db = dbsubset(db,subset_expr);
            end

            % Sort by arrival time
            db = dbsort(db,'time');

            % Get the values
            [sta,chan,time,amp,signal2noise,iphase] = dbgetv(db,'sta','chan','time','amp','snr','iphase');

            % Close database link
            dbclose(db);
            
            arrivalObj = Arrival(cellstr(sta), cellstr(chan), epoch2datenum(time), cellstr(iphase), 'amp', amp, 'signal2noise', signal2noise);

end
