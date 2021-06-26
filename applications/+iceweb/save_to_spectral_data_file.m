function save_to_spectral_data_file(filepattern, dnum, F, spdata, samplingIntervalSeconds, ctag)
    % ICEWEB/SAVE_TO_BOB_FILE - save spectral data to an RSAM/BOB binary
    % like file, with the difference that there are numel(F) values to save
    % for each timestep (sample).
    %
    %
    % Examples:
    %   1. save data to myfile.bob
    %       save_to_spectraldata_file('spdata.2003.MV.MBWH..SHZ',dnum,F,spdata)
    %
    %   2. save to file like spdata.YEAR.STATION.CHANNEL
    %       r.save('spdata.YYYY.SSSS.CCC',dnum,F,spdata)
    %

    if size(dnum,2)~=size(spdata,2)
            debug.print_debug(1,sprintf('%s: Cannot save to %s because data and time vectors are different lengths',mfilename,filename));
            return;
    end

    if numel(spdata)<1
            debug.print_debug(1,'No data. Aborting');
        return;
    end
    
    HEADER_BYTES = 10000;
    % round times to minute
    MINUTES_PER_DAY = 60 * 24;
    dnum = round(dnum * MINUTES_PER_DAY) / MINUTES_PER_DAY;
    
    % get list of files to which data should be saved
    filestruct = filepattern_substitute(filepattern, ctag, dnum);
  
    for filenum = 1:numel(filestruct)
        this = filestruct(filenum);

        debug.print_debug(2,sprintf('Looking for file: %s\n',this.file));
        if ~exist(this.file,'file')
                debug.print_debug(2, ['Creating ',this.file]);
                days = this.enum - this.snum;
                iceweb.make_spectral_data_file(this.file, days, MINUTES_PER_DAY, F, HEADER_BYTES);
        end            

        % subset for current file
        dnumy = dnum(dnum >= this.snum & dnum <= this.enum);
        datay = spdata(:, dnum >= this.snum & dnum <= this.enum);

        % find the next contiguous block of data
        diff=dnumy(2:end) - dnumy(1:end-1);
        i = find(diff > 1.5/MINUTES_PER_DAY | diff < 0.5/MINUTES_PER_DAY);        

        debug.print_debug(1,sprintf('Saving to %s',this.file));
        % how many days in this year?
        daysperyear = 365;
        dv=datevec(this.snum);
        yyyy=dv(1);
        if (mod(yyyy,4)==0)
                daysperyear = 366;
        end        
        
        %save savetospectraldatafile.mat

        if length(i)>0
            % slow mode

            for c=1:length(dnumy)

                % write the data, sample by sample
                startminute = round((dnumy(c) - this.snum) * MINUTES_PER_DAY);
                offset = HEADER_BYTES + startminute * 4 * numel(F);
                fid = fopen(this.file,'r+');
                frewind(fid);
                fseek(fid,offset,'bof');
                debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at minute %d',nanmean(datay),this.file,startminute,(MINUTES_PER_DAY*(daysperyear+1))));
                fwrite(fid,datay(:,c),'float32');
                fclose(fid);
            end
        else
            % fast mode

            % write the data
            startminute = round((dnumy(1) - this.snum) * MINUTES_PER_DAY);
            offset = HEADER_BYTES + startminute * 4 * numel(F);
            fid = fopen(this.file,'r+','l'); % little-endian. Anything written on a PC is little-endian by default. Sun is big-endian.
            fseek(fid,offset,'bof');
            debug.print_debug(2, sprintf('saving data with mean of %e from to file %s, starting at minute %d',nanmean(datay),this.file,startminute));
            fwrite(fid,datay,'float32');
            fclose(fid);
        end

    end
end