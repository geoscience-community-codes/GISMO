% Class that describes data in a Seisan S-file
classdef Sfile
    properties
        etime = NaN
        mainclass = 'U'
        subclass = 'u'
        wavfiles = {}
        year = NaN
        month = NaN
        otime = NaN
        magnitude = NaN
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
        arrivals 
    end
    
    methods
        function s = Sfile(fileContents)
		%Sfile Constructor for Sfile
        % s = SFILE(fileContents)
        % Example: Read a Seisan S-file from a local file:
        %     sfileObject = SFILE(fullfile('/raid/data/MONTSERRAT/seisan/REA/MVOE_/2002/02', '27-2109-46L.S200202SACPZ.IU.COLA.BHZ'))
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
                help(mfilename);
                return
            end

            % Initialize
            aef = struct();
            aeflinenum = 0;
            magnum = 0;

            % Read lines into cell array
            lines = strread(fileContents, '%s', 'delimiter', sprintf('\n'));
            linenum = 1;
            numorigins = 0; alls = [];

			while linenum <= numel(lines),
                tline = fileContents(1+(linenum-1)*82:min([length(fileContents) 80+(linenum-1)*82]));
                linenum = linenum + 1;
                %disp(sprintf('*%s*',tline));
                linelength=length(tline); 
                if ischar(tline) & linelength == 80
                    lineend = tline(80);
                else
                    continue
                end
                
                if lineend == '1'
                    numorigins = numorigins + 1
                    if numorigins > 1
                        alls = [alls s];
                        clear s;
                    end
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
                        s.magnitude(magnum).type = tline(60);
                        s.magnitude(magnum).agency = strtrim(tline(61:63));
                    end
                    if ~isempty(strtrim(tline(64:67)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(64:67));
                        s.magnitude(magnum).type = tline(68);
                        s.magnitude(magnum).agency = strtrim(tline(69:71));
                    end
                    if ~isempty(strtrim(tline(72:75)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(72:75));
                        s.magnitude(magnum).type = tline(76);
                        s.magnitude(magnum).agency = strtrim(tline(77:79));
                    end                
                end

                % Process Type 2 line, Macroseismic Intensity Information
                if lineend == '2'
                   s.maximum_intensity=str2num(tline(28:29));
                end

                if lineend == '3'   % This is SEISAN identifier for summary lines in the Sfile                
                    if strfind(tline,'VOLC')                   
                        if strfind(tline,'MAIN')  % This identifies the volcanic type 
                            s.subclass=tline(12);
                        else % A TYPE 3 LINE LIKE "VOLC STA"
                            if strcmp(sta,'*') || strfind(tline,sta)
                                if strcmp(chan,'*') ||  strfind(tline(14:15),chan(end))
                                    aeflinenum = aeflinenum + 1;
                                    thissta = strtrim(tline(7:10));
                                    thischan = strtrim(tline(12:15));
                                    aef.ctag(aeflinenum) = ChannelTag('', thissta, '', thischan);
                                    try
                                        %aef.amp(aeflinenum)=str2num(tline(20:27));
                                        aef.amp(aeflinenum)=str2num(tline(18:25));
                                    catch
                                        tline
                                        tline(20:27)
                                        aeflinenum
                                        aef.amp
                                        error('aef.amp')
                                    end
                                    %aef.eng(aeflinenum)=str2num(tline(30:37));
                                    aef.eng(aeflinenum)=str2num(tline(28:35));
                                    for i = 1:11
                                        %startindex = (i-1)*3 + 40;
                                        startindex = (i-1)*3 + 38;
                                        ssam(i) = str2num(tline(startindex:startindex+1));
                                    end
                                    aef.ssam{aeflinenum} = ssam;
                                    aef.pkf(aeflinenum)=str2num(tline(73:77));   % Peak frequency (Frequency of the largest peak
                                end
                            end
                        end
                    elseif strcmp(tline(2:7), 'ExtMag')
                        magnum = magnum + 1;
                        s.magnitude(magnum).value = str2num(tline(9:12));
                        s.magnitude(magnum).type = tline(13);
                        s.magnitude(magnum).agency = strtrim(tline(14:16));   
                    elseif strcmp(tline(1:4), 'URL')
                        s.url = strtrim(tline(6:78));
                    end

                end

                if lineend == '6'
                    s.wavfiles = strread(strtrim(tline(2:79)), '%s');
                    %wavfile{1} = tline(2:36);
                end
                
                if lineend == '7'
                    s.arrivals = Arrival.retrieve_seisan(fileContents, s.otime);
                end

                % Process Type E line, Hyp error estimates
                if lineend == 'E'
                    s.gap=str2num(tline(6:8));
                    s.error.origintime=str2num(tline(15:20));
                    s.error.latitude=str2num(tline(25:30));
                    s.error.longitude=str2num(tline(33:38));
                    s.error.depth=str2num(tline(39:43));
                    s.error.covxy=str2num(tline(44:55));
                    s.error.covxz=str2num(tline(56:67));
                    s.error.covyz=str2num(tline(68:79));
                end

                % Process Type F line, Fault plane solution
                % Format has changed need to fix AAH - 2011-06-23
                if lineend == 'F' %and not s.focmec.has_key('dip'):
                    s.focmec.strike=str2num(tline(1:10));
                    s.focmec.dip=str2num(tline(11:20));
                    s.focmec.rake=str2num(tline(21:30));
                    %s.focmec.bad_pols=str2num(tline(61:66));
                    s.focmec.agency=tline(67:69);
                    s.focmec.source=tline(71:77);
                    s.focmec.quality=tline(78);
                end

                % Process Type H line, High accuracy line
                % This replaces some origin parameters with more accurate ones
                if lineend == 'H'
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
                end

                if lineend == 'I'
                    s.last_action=strtrim(tline(9:11));
                    s.action_time=strtrim(tline(13:26));
                    s.analyst = strtrim(tline(31:33));
                    s.id = str2num(tline(61:74));
                end  

                if tline(2:8)=='trigger' 
                    s.bbdur=str2num(tline(18:19)); % EARTHWORM TRIGGER DURATION (including pre & posttrigger times?)
                    s.bbdur=str2num(tline(19:23));
                elseif tline(2:7)=='sptrig'
                    s.spdur=str2num(tline(19:23));
                end

                if tline(22:24) == 'MVO' &  (lineend == '6') % DATE AND TIME OF THE EVENT
                    s.etime = datenum(sprintf('%s %s:%s:%s',tline(2:11),tline(13:14), tline(15:16), tline(18:19)));
                end
            end
            
            s.aef = aef;
            alls = [alls s];
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
            % SFILE.LIST_SFILES Load waveform files from a Seisan database 
            %   s = SFILE.LIST_SFILES(dbpath, snum, enum) search a Seisan
            %   database for Sfiles matching the time range given by snum
            %   and enum.
            %
            %   Notes:
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
            fprintf('There are %d sfiles matching your request in %s\n',numel(files),dbpath)

            debug.printfunctionstack('<')
        end

    end
end
