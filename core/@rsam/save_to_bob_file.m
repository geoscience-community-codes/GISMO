function save_to_bob_file(self, filepattern)
    % RSAM/SAVE_TO_BOB_FILE - save an rsam-like object to an RSAM/BOB binary
    % file
    %
    %
    % Examples:
    %   1. save data to myfile.bob
    %       r.save_to_bob_file('myfile.bob')
    %
    %   2. save to file like YEAR_STATION_CHANNEL_MEASURE.bob
    %       r.save('YYYY_SSSS_CCC_MMMM.bob')
    %

    for c=1:numel(self)
        dnum = self(c).dnum;
        data = self(c).data;
        file = filepattern; 

        % substitute for station
        file = regexprep(file, 'SSSS', upper(self(c).sta));

        % substitute for channel
        file = regexprep(file, 'CCC', upper(self(c).chan));

        % substitute for measure
        file = regexprep(file, 'MMMM', self(c).measure);             

        % since dnum may not be ordered and contiguous, this function
        % should write data based on dnum only

        if length(dnum)~=length(data)
                debug.print_debug(1,sprintf('%s: Cannot save to %s because data and time vectors are different lengths',mfilename,filename));
                return;
        end

        if length(data)<1
                debug.print_debug(1,'No data. Aborting');
            return;
        end

        % filename

        % set start year and month, and end year and month
      
        [syyy sm]=datevec(self(c).snum);
        [eyyy em]=datevec(self(c).enum);
    
        if syyy~=eyyy
            if ~strfind(filepattern, 'YYYY')
                error('can only save RSAM data to BOB file if all data within 1 year (or you can add YYYY in your file pattern)');
            end
        end 

        
        SECONDS_PER_DAY = 60 * 60 * 24;
        for yyyy=syyy:eyyy

            SAMPLES_PER_DAY = SECONDS_PER_DAY / self(c).sampling_interval;

            % how many days in this year?
            daysperyear = 365;
            if (mod(yyyy,4)==0)
                    daysperyear = 366;
            end

            % Substitute for year        
            fname = regexprep(file, 'YYYY', sprintf('%04d',yyyy) );
            debug.print_debug(2,sprintf('Looking for file: %s\n',fname));

            if ~exist(fname,'file')
                    debug.print_debug(2, ['Creating ',fname]);
                    rsam.make_bob_file(fname, daysperyear, SAMPLES_PER_DAY);
            end            

            SAMPLES_PER_DAY = SECONDS_PER_DAY / self(c).sampling_interval;

            % round times to minute
            dnum = round((dnum-1/SECONDS_PER_DAY) * SAMPLES_PER_DAY) / SAMPLES_PER_DAY;

            % subset for current year
            dnumy = dnum(dnum < datenum(yyyy + 1, 1, 1));
            datay = data(dnum < datenum(yyyy + 1, 1, 1));

            % find the next contiguous block of data
            diff=dnumy(2:end) - dnumy(1:end-1);
            i = find(diff > 1.5/SAMPLES_PER_DAY | diff < 0.5/SAMPLES_PER_DAY);        

            debug.print_debug(1,sprintf('Saving to %s',fname));
          
            if length(i)>0
                % slow mode

                for c=1:length(dnumy)

                    % write the data
                    startsample = round((dnumy(c) - datenum(yyyy,1,1)) * SAMPLES_PER_DAY);
                    offset = startsample*4;
                    fid = fopen(fname,'r+');
                    fseek(fid,offset,'bof');
                    debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at position %d',nanmean(datay),fname,startsample,(datapointsperday*daysperyear)));
                    fwrite(fid,datay(c),'float32');
                    fclose(fid);
                end
            else
                % fast mode

                % write the data
                startsample = round((dnumy(1) - datenum(yyyy,1,1)) * SAMPLES_PER_DAY);
                offset = startsample*4;
                fid = fopen(fname,'r+','l'); % little-endian. Anything written on a PC is little-endian by default. Sun is big-endian.
                fseek(fid,offset,'bof');
                debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at position %d/%d',nanmean(datay),fname,startsample,(SAMPLES_PER_DAY*daysperyear)));
                fwrite(fid,datay,'float32');
                fclose(fid);
            end
        end
    end
end
