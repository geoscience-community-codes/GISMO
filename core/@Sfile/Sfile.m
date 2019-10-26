% Class that parses a Seisan S-file. 
classdef Sfile
    properties(Access = public)
        sfilepath = ''
        etime = NaN
        mainclass = 'U'
        subclass = 'u'
        wavfiles = {}
        year = NaN
        month = NaN
        otime = NaN
        ontime = NaN
        offtime = NaN
        magnitude = struct()
        longitude = NaN
        latitude = NaN
        depth = NaN
        z_indicator = ''
        no_sta = NaN
        gap = NaN
        error = struct()
        rms = NaN
        focmec = struct()
        maximum_intensity = ''
        url = ''
        last_action = ''
        action_time = ''
        analyst = ''
        agency = ''
        id = ''
        bbdur = NaN
        spdur = NaN
        aef = struct()
        topdir
        reldir
        arrivals
    end
    
    methods
        function s = Sfile(sfilepath,fileContents)
            disp(sfilepath)
		%Sfile Constructor for Sfile
        % s = Sfile(SfileContents)
        % Example: Read a Seisan S-file from a local file:
        %     sfileObject = Sfile(fullfile('/raid/data/MONTSERRAT/seisan/REA/MVOE_/2002/02', '27-2109-46L.S200202SACPZ.IU.COLA.BHZ'))
        %
        % OUTPUT VARIABLES:
        %   s = a structure containing
        %       aef = a structure with vector fields        
        %           amp = MAX AVERAGE AMPLITUDE OF SIGNAL
        %           eng = SEISMIC ENERGY
        %           ssam = percentage of energy in 11 different frequency bins
        %           pkf = PEAK FREQUENCY
        %           ctag = CHANNELTAG
        %       stime = EVENT TIME
        %       ...and many more variables...
    
            debug.printfunctionstack('>')

            % Validate    
            if ~exist('fileContents','var')
                if exist('sfilepath','var')
                    if exist(sfilepath, 'file')
                        fileContents = fileread(sfilepath);
                    else
                        warning(sprintf('Sfile %s not found. quitting.',sfilepath))
                        return
                    end
                else
                    warning('path to sfile not given')
                    help(mfilename)
                    return
                end
            end

            % Initialize
            s.sfilepath = sfilepath;
            [ddir,dfile,dext] = fileparts(sfilepath);
            pathparts = split(ddir,'REA');
            s.topdir = pathparts{1};
            s.reldir = pathparts{2};
            aef = struct();
            aeflinenum = 0;
            magnum = 0;
            s.ontime = Sfile.filename2datenum([dfile,dext]);
            if debug.get_debug()>0
                disp(fileContents)
                stop
            end

            % Read lines into cell array
            lines = strread(fileContents, '%s', 'delimiter', sprintf('\n'));
            
            % echo the Sfile contents
            if debug.get_debug()>0
                lines
            end
            
            % loop over each line, identifying and parsing as we go
            linenum = 1;
			while linenum <= numel(lines),
                tline = lines{linenum};
                linenum = linenum + 1;
                linelength=length(tline);
                tline = pad(tline, 80, 'left');
                linelength=length(tline);
                if ischar(tline) & linelength <= 80
                    lineend = tline(end)
                    tline
                else
                    continue
                end
                
                if lineend == '1'
                    arrival_lines_on = false;
                    if length(strtrim(tline(2:20)))  >= 14
                        s.year = str2num(tline(2:5));
                        s.month = str2num(tline(7:8));
                        day = str2num(tline(9:10));
                        hour = str2num(tline(12:13));
                        minute = str2num(tline(14:15));
                        second = str2num(tline(17:20));
                        if floor(second) == 60
                            minute = minute + 1;
                            second = second - 60.0;
                        end
                        s.otime = datenum(s.year, s.month, day, hour, minute, floor(second));
                    end
                    s.mainclass = strtrim(tline(22:23));
                    lat = str2num(tline(24:30));
                    lon = str2num(tline(31:38));
                    depth = str2num(tline(39:43));
                    if ~isempty(lat)
                        s.latitude = lat;
                    end
                    if ~isempty(lon)
                        s.longitude = lon;
                    end     
                    if ~isempty(depth)
                        s.depth = depth;
                    end                    
                    s.z_indicator = strtrim(tline(44));
                    s.agency = strtrim(tline(46:48));
                    s.no_sta=str2num(tline(49:51));
                    if isempty(s.no_sta)
                        s.no_sta=0;
                    end
                    s.rms=str2num(tline(52:55));

                    if ~isempty(strtrim(tline(56:59)));
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(56:59));
                        s.magnitude(magnum).type = ['m' lower(tline(60))];
                        s.magnitude(magnum).agency = strtrim(tline(61:63));
                    end
                    if ~isempty(strtrim(tline(64:67)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(64:67));
                        s.magnitude(magnum).type = ['m' lower(tline(68))];
                        s.magnitude(magnum).agency = strtrim(tline(69:71));
                    end
                    if ~isempty(strtrim(tline(72:75)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(72:75));
                        s.magnitude(magnum).type = ['m' lower(tline(76))];
                        s.magnitude(magnum).agency = strtrim(tline(77:79));
                    end 
                    continue
                end

                % Process Type 2 line, Macroseismic Intensity Information
                if lineend == '2'
                    arrival_lines_on = false;
                   s.maximum_intensity=str2num(tline(28:29));
                   continue
                end

                if lineend == '3'   % This is SEISAN identifier for summary lines in the Sfile
                    arrival_lines_on = false;
              
                    if strfind(tline,'VOLC')                   
                        if strfind(tline,'MAIN')  % This identifies the volcanic type 
                            s.subclass=tline(12);
                        else % A TYPE 3 LINE LIKE "VOLC STA"  
                            [aef, aeflinenum, bbdur, spdur] = Sfile.readaefline(tline, aef, aeflinenum, s.bbdur, s.spdur);
                            s.bbdur = bbdur;
                            s.spdur = spdur;
                       
                        end
                    elseif findstr(tline,'trig') 
                        [bbdur spdur] = Sfile.read_trigger_window_line(tline, bbdur, spdur);
                        s.bbdur = bbdur;
                        s.spdur = spdur;
    
                    elseif strcmp(tline(2:7), 'ExtMag')
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(9:12));
                        s.magnitude(magnum).type = ['m' lower(tline(13))];
                        s.magnitude(magnum).agency = strtrim(tline(14:16));   
                    elseif strcmp(tline(1:4), 'URL')
                        s.url = strtrim(tline(6:78));
                    end
                    continue

                end

                % This will read all wavfile strings into a cell array               
                if lineend == '6'
                    arrival_lines_on = false;
                    %tline(22:24)
                    %if strcmp(tline(22:24),'MVO')  % DATE AND TIME OF THE EVENT
                    if ~strfind(tline,'___')
                        s.etime = datenum(sprintf('%s %s:%s:%s',tline(2:11),tline(13:14), tline(15:16), tline(18:19)));
                    else
                        s.wavfiles = cellstr(strread(strtrim(tline(2:79)), '%s'));

                        % add relative path from top of Seisan DB
                        for wavfilenum=1:numel(s.wavfiles)
                            % look for aeffiles too
                            aeffile = fullfile(s.topdir, 'AEF', s.reldir, [s.wavfiles{wavfilenum},'.aef']);
                            if exist(aeffile,'file')
                                % we want to read this file too
                                [aef, aeflinenum, bbdur, spdur] = Sfile.readaeffile(aeffile, aef, aeflinenum, s.bbdur, s.spdur);
                                s.bbdur = bbdur;
 
                            end
                            s.wavfiles{wavfilenum} = fullfile('WAV', s.reldir, s.wavfiles{wavfilenum});
                        end
                    end
                    continue
                    
                end
                
                
                
                if lineend == '7'
                    arrival_lines_on = true;
                    arrivalnum=0;
                    arrivals = [];
                    clear arr
                    ymd = floor(s.ontime);
                    continue
                end
                    

                % Process Type E line, Hyp error estimates
                if lineend == 'E'
                    arrival_lines_on = false;
                    s.gap=str2num(tline(6:8));
                    s.error.origintime=str2num(tline(15:20));
                    s.error.latitude=str2num(tline(25:30));
                    s.error.longitude=str2num(tline(33:38));
                    s.error.depth=str2num(tline(39:43));
                    s.error.covxy=str2num(tline(44:55));
                    s.error.covxz=str2num(tline(56:67));
                    s.error.covyz=str2num(tline(68:79));
                    continue
                end

                % Process Type F line, Fault plane solution
                % Format has changed need to fix AAH - 2011-06-23
                if lineend == 'F' %and not s.focmec.has_key('dip'):
                    arrival_lines_on = false;
                    s.focmec.strike=str2num(tline(1:10));
                    s.focmec.dip=str2num(tline(11:20));
                    s.focmec.rake=str2num(tline(21:30));
                    %s.focmec.bad_pols=str2num(tline(61:66));
                    s.focmec.agency=tline(67:69);
                    s.focmec.source=tline(71:77);
                    s.focmec.quality=tline(78);
                    continue
                end

                % Process Type H line, High accuracy line
                % This replaces some origin parameters with more accurate ones
                if lineend == 'H'
                    arrival_lines_on = false;
                    osec0=str2num(tline(17:22));
                    yyyy0=str2num(tline(2:5));
                    mm0=str2num(tline(7:8));
                    dd0=str2num(tline(9:10));
                    hh0=str2num(tline(12:13));
                    mi0=str2num(tline(14:15));
                    s.otime=datenum(yyyy0, mm0, dd0, hh0, mi0, osec0);
                    s.latitude=str2num(tline(24:32));
                    s.longitude=str2num(tline(34:43));
                    s.depth=str2num(tline(45:52));
                    s.rms=str2num(tline(54:59));   
                    continue
                end

                if lineend == 'I'
                    arrival_lines_on = false;
                    s.last_action=strtrim(tline(9:11));
                    s.action_time=strtrim(tline(13:26));
                    if (s.action_time(1)=='9')
                        s.action_time = sprintf('19%s',s.action_time);
                    else
                        s.action_time = sprintf('20%s',s.action_time);
                    end
                    s.analyst = strtrim(tline(31:33));
                    s.id = str2num(tline(61:74));
                    continue
                end  
                
                % arrival lines?
                if arrival_lines_on & lineend == ' ' 
                    sta = strtrim(tline(2:5));
                    if ~isempty(sta)
                        if length(sta)>2
                            arrivalnum=arrivalnum+1;
                            arr.sta{arrivalnum}=sta;
                            %eori = tline(10);
                            arr.iphase(arrivalnum) = tline(11);
                            hh0=str2num(tline(19:20));
                            mi0=str2num(tline(21:22));
                            ss0=str2num(tline(24:28));
                            
                            str_tres = strtrim(tline(65:68))
                            if ~isempty(str_tres)
                                arr.tres(arrivalnum)=str2num(str_tres);
                            else
                                arr.tres(arrivalnum) = NaN;
                            end
                            str_weight = strtrim(tline(69:70))
                            if ~isempty(str_weight)
                                arr.weight(arrivalnum)=str2num(str_weight);
                            else
                                arr.weight(arrivalnum) = NaN;
                            end                           
                            %dis=str2num(tline(75));
                            %caz=str2num(tline(77:79));
                            arr.atime(arrivalnum) = ymd+hh0/24+mi0/1440+ss0/86400;
                            %arr.traveltime(arrivalnum) = (atime - s.otime) * 86400;
                        end
                    else
                        disp('blank line?')
                    end
                end                
            end
            
            s.aef = aef;
            
            %s.arrivals = arrivals;
            if exist('arr','var') & (~exist('arrivalnum','var') | arrivalnum>0 )
                s.arrivals = Arrival(cellstr(arr.sta), ...
                            cellstr(''), arr.atime, cellstr(arr.iphase), ...
                            'timeres', arr.tres);   
            else
                s.arrivals = Arrival();
            end
                
            wavfile_duration_seconds = nanmax([s.bbdur s.spdur]);
            if ~isnan(wavfile_duration_seconds)
                s.offtime = s.ontime + wavfile_duration_seconds / 86400;
            end  
            
            debug.printfunctionstack('<')
        end
    end
    
    methods(Static)
        function dnum=filename2datenum(sfilebasename)
        % SFILE.FILENAME2DATENUM convert the name of a Seisan S-file into a
        % MATLAB datenum
            ddstr=sfilebasename(1:2);
            hhstr=sfilebasename(4:5);
            mistr=sfilebasename(6:7);
            ssstr=sfilebasename(9:10);
            yystr=sfilebasename(14:17);
            mm=str2num(sfilebasename(18:19));
            months=['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'];
            mmstr=months(mm,:);
            datestring=[ddstr,'-',mmstr,'-',yystr,' ',hhstr,':',mistr,':',ssstr];
            try
                dnum=datenum(datestring);
            catch
                warning(sprintf('Could not convert %s to a datenum for sfile=%s. Returning NaN', datestring, sfilebasename));
                dnum = NaN;
            end
        end
        
        
        function files = list_sfiles(dbpath, snum, enum)
            % SFILE.LIST_SFILES List S-files 
            %   s = SFILE.LIST_SFILES(dbpath, snum, enum) search a Seisan
            %   database for Sfiles matching the time range given by snum
            %   and enum.
            %
            %   Notes:/media/sdd1/seismo
            %     Seisan Sfiles are typically stored in a Seisan
            %     Seisan database, which is a tree of 4-digit-year/2-digit-month 
            %     directories. They have a name matching DD-HHMM-SSc.SYYYYMM
            %
            %   Example:
            %       Load all data for all stations & channels between 1000 and 1100
            %       UTC on March 1st, 2001.
            %           
            %           dbpath = '/raid/data/seisan/REA/DSNC_';
            %           snum = datenum(2001,3,1,10,0,0);
            %           enum = datenum(2001,3,1,11,0,0);
            %           s = SFILE.LIST_SFILES(dbpath, snum, enum)
            %

            debug.printfunctionstack('>')

            files = [];

            % Test dbpath
            if ~exist(dbpath,'dir')
                disp(sprintf('dbpath %s not found',dbpath))
                return
            end
            
            fprintf('Generating a list of S-files matching this time range %s to %s ...',datestr(snum),datestr(enum));

            %% Compile a list from all directories from snum to enum
            sdv = datevec(snum);
            edv = datevec(enum);
            fileindex = 0;
            for yyyy=sdv(1):edv(1)
               for mm=sdv(2):edv(2)
                   seisandir = fullfile(dbpath, sprintf('%4d',yyyy), sprintf('%02d',mm) );
                   newfiles = dir(fullfile(seisandir, sprintf('*%4d%02d',yyyy,mm)));
                   for i=1:length(newfiles)
                       dnum = Sfile.filename2datenum(newfiles(i).name);
                       if dnum >= snum & dnum <= enum
                           fileindex = fileindex + 1;
                           newfiles(i).dir = seisandir;
                           files = [files; newfiles(i)];
                       elseif dnum>enum
                           break;
                       end
                   end
               end
            end

            %% Echo the list of matching sfiles
            fprintf('\nThere are %d sfiles matching your request in %s\n',numel(files),dbpath)

            debug.printfunctionstack('<')
        end

 


        function [aef, aeflinenum, bbdur, spdur] = readaefline(tline, aef, aeflinenum, bbdur, spdur)

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Glenn Thompson. This modification is for the specific
            % case of S-files from the Montserrat Volcano Observatory.
            % As Seismologist there 2000-2004, I began adding new
            % lines that included the amplitude, energy and
            % frequency information for each channel as
            % computed by ampengfft.c (written originally
            % by Richard Luckett and modified by Simon
            % Flower and myself. I believe Richard had done
            % something like this before but his work had
            % all been erased when sometime between him
            % leaving in early 1999 and Art Jolly arriving
            % in June 1999, Dave Williams had grabbed the
            % analyst computer to use as a server when the
            % main server failed. Anyway, I built the first
            % full online archive of all MVO seismic data
            % as a Seisan database and that re-ran
            % ampengfft after these modifications on the
            % full Seisan database to generate the
            % ampengfft lines which are read here. The main
            % purposes at the time was to create event
            % spectrograms (preceding Seth Moran's similar
            % ESAM system by about 5 years) and to create a
            % real-time magnitude scale that could be
            % applied to all events, not just located
            % events.
            aeflinenum = aeflinenum + 1;
            tline(1:4);
            if strfind(tline(1:5),'VOLC')
                thissta = strtrim(tline(7:10));
                thischan = strtrim(tline(12:15));
                aef.ctag(aeflinenum) = ChannelTag('', thissta, '', thischan);
                findamp = strfind(tline(15:20),'A')+14;
                aef.amp(aeflinenum)=str2num(tline(findamp+1:findamp+8));
                findeng = strfind(tline(findamp+7:findamp+17),'E')+findamp+6;
                aef.eng(aeflinenum)=str2num(tline(findeng+1:findeng+8));
                findfft = strfind(tline(findeng+7:findeng+10),'F')+findeng+6;
                for i = 1:12
                    startindex = findfft + 1 + (i-1)*3;
                    ssam(i) = str2num(tline(startindex:startindex+1));
                end
                aef.ssam{aeflinenum} = ssam;
                aef.pkf(aeflinenum)=str2num(tline(73:78));  % Peak frequency (Frequency of the largest peak
            else
                % might be a line like:
                % {'trigger window = 105.7 s                                                      3'}
                [bbdur spdur] = Sfile.read_trigger_window_line(tline, bbdur, spdur);
            end
           


        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [aef, aeflinenum, bbdur, spdur] = readaeffile(aeffile, aef, aeflinenum, bbdur, spdur)
            aeffile
            if exist('aeffile','var')
                if exist(aeffile, 'file')
                    fileContents = fileread(aeffile)
                else
                    warning(sprintf('AEFfile %s not found. quitting.',aeffile))
                    return
                end
            else
                warning('path to AEFfile not given')
                help(mfilename)
                return
            end

    %         % Initialize
    %         aef = struct();
    %         aeflinenum = 0;

            fileContents;

            % Read lines into cell array
            lines = strread(fileContents, '%s', 'delimiter', sprintf('\n'));

            % echo the AEFfile contents
            if debug.get_debug()>0
                lines
            end

            % loop over each line, identifying and parsing as we go
            linenum = 1;
            while linenum <= numel(lines),
                tline = lines{linenum};
                linenum = linenum + 1;
                linelength=length(tline);
                tline = pad(tline, 80, 'left');
                linelength=length(tline);
                if ischar(tline) & linelength <= 80
                    lineend = tline(end);
                    if lineend == '3'
                        [aef, aeflinenum, bbdur, spdur] = Sfile.readaefline(tline, aef, aeflinenum, bbdur, spdur);
                    end
                else
                    continue
                end
            end
        end
        
        
        
        function [bbdur spdur] = read_trigger_window_line(tline, bbdur, spdur)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Glenn Thompson. This modification is for the specific
            % case of S-files from the Montserrat Volcano Observatory.
            % As Seismologist there 2000-2004, I began adding a new
            % line that included the trigger window length
            % First I added "trigger window=XXXs" for Seisan WAV files
            % from the digital (broadband) network. And later I added
            % "sptrig=XXXs" or "sptrig window=XXXs" for Seisan WAV
            % files from the analog (short period) network. I try to
            % parse these here into bbdur and spdur. They also get
            % passed into Catalog to define the ontime and offtime of
            % each wavform file.
            % These durations do include a pretrigger and posttrigger
            % window, since that is the full length of the event
            % waveform file.
            pos=findstr(tline,'trigger window');
            if ~isempty(pos)
                 durstr = tline(pos+14:pos+19);
                 durfields = split(durstr,'=');
                 durstr2 = durfields{2};
                 durfields2 = split(durstr2,'s');
                 bbdur=str2num(durfields2{1});
            end
            clear pos

            pos=findstr(tline,'sptrig');
            if ~isempty(pos)
                 durstr = tline(pos+6:pos+10);
                 durfields = split(durstr,'=');
                 durstr2 = durfields{2};
                 durfields2 = split(durstr2,'s');
                 spdur=str2num(durfields2{1});
            end 

        end

    end % end of static methods
    
end
 

    

