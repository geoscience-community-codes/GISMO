function s=read_sfile(sfiledir, sfilebase,sta,chan);
% read_sfile import data from a single MVO SFILE generated in SEISAN.
% USAGE: s=read_sfile(sfiledir, sfilebase,sta,chan)
% INPUT VARIABLES:
%   sfiledir = directory of the S-file
%   sfilebase = basename of the S-file
%   sta = the station to load, or can be set to '*' for all
%   chan = the channel to load, or can be set to '*' for all
%       note: only last character of chan is used for matching presently
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
%
% EXAMPLE:
%   s = read_sfile('/raid/data/seisan/REA/MVOE_/2002/02', '27-2109-46L.S200202','*', '*')
%   s = read_sfile('/raid/data/seisan/AEF/MVOE_/2002/02', '2002-02-27-2311-34S.MVO___014.aef','*','*')
    
    debug.printfunctionstack('>')

    % Validate    
    fullpath = fullfile(sfiledir, sfilebase);
    if ~ischar(fullpath) || ~exist(fullpath)
        warning(sprintf('readEvents:notFound','%s not found',fullpath));
        % eval(['help ' mfilename]);
        help(mfilename);
    end

    % initialize
    s = struct();
    s.aef = struct('amp', [], 'eng', [], 'ssam', {}, 'pkf', [], 'ctag', []);
    s.subclass='_';                  
    s.bbdur=NaN; 
    s.stime = '';
    s.dnum = sfile2dnum(sfilebase);
    s.wavfiles = '';
    s.error = NaN;
    s.gap = NaN;
    s.magnitude = struct();
    s.longitude = NaN;
    s.latitude = NaN;
    s.depth = NaN;
    aef = struct();
    
    % open file 
    fid=fopen(fullpath,'r');
    patternstr = ['VOLC',' ',sta];
  
    linenum = 1;
    aeflinenum = 0;
    magnum = 0;
    while fid ~= -1,
        tline = fgetl(fid);
        %disp(sprintf('line = %d',linenum));
        %disp(tline);
        linelength=length(tline);    
        if ischar(tline) & linelength == 80 % must be an 80 character string, or close file
            
            if tline(80) == '1'
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
            if tline(80) == '2'
               s.maximum_intensity=str2num(tline(28:29));
            end
               
            if tline(80) == '3'   % This is SEISAN identifier for summary lines in the Sfile                
                if strfind(tline,'VOLC')                   
                    if strfind(tline,'MAIN')  % This identifies the volcanic type 
                        s.subclass=tline(12);
                    else % A TYPE 3 LINE LIKE "VOLC STA"
                        if strcmp(sta,'*') || strfind(tline,sta)
                            if strcmp(chan,'*') ||  strfind(tline(14:15),chan(end))
                                aeflinenum = aeflinenum + 1;
                                thissta = strtrim(tline(7:10));
                                thischan = strtrim(tline(12:15));
                                aef.ctag(aeflinenum) = channeltag('', thissta, '', thischan);
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
            
            if tline(80) == '6'
                s.wavfiles = tline(2:79);
                wavfile{1} = tline(2:36);
            end
            
            % Process Type E line, Hyp error estimates
            if tline(80) == 'E'
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
            if tline(80) == 'F' %and not s.focmec.has_key('dip'):
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
            if tline(80) == 'H'
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
            
            if tline(80) == 'I'
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

            if tline(22:24) == 'MVO' &  (tline(80) == '6') % DATE AND TIME OF THE EVENT
                s.stime=tline(2:19);
            end
        else
            fclose(fid);
            break
        end
        linenum = linenum + 1;
    end
    s.aef = aef;
    debug.printfunctionstack('<')
end