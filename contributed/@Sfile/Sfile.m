classdef Sfile
%SFILE  Parser for SEISAN S-files (single-event container)
%
%   The Sfile class parses a single SEISAN S-file and stores all event-level
%   metadata in a MATLAB object. It is designed primarily for use with the
%   Montserrat Volcano Observatory (MVO) SEISAN archive, which includes
%   several important non-standard extensions introduced between ~2000–2004.
%
%   STANDARD SEISAN INFORMATION PARSED:
%   -----------------------------------
%   • Origin time, latitude, longitude, depth
%   • Event classification (mainclass, subclass)
%   • Magnitudes (multiple agencies and types)
%   • Network gap, RMS, hypocentral errors
%   • Focal mechanism (if present)
%   • Macroseismic intensity
%   • Analysis metadata (analyst, agency, ID, actions)
%   • Phase arrivals (converted into GISMO Arrival objects)
%   • Associated waveform file names (WAV tree)
%
%   MVO NON-STANDARD EXTENSIONS SUPPORTED:
%   -------------------------------------
%   • Amplitude–Energy–Frequency (AEF) lines written by ampengfft.c
%       - May appear directly in S-files (VOLC STA lines)
%       - Or in parallel *.aef files stored under the AEF tree
%       - Parsed fields include:
%           aef.amp   : average or peak signal amplitude
%           aef.eng   : seismic energy proxy
%           aef.ssam  : spectral energy distribution (SSAM-style bins)
%           aef.pkf   : peak frequency
%           aef.ctag  : ChannelTag for each measurement
%
%   • Trigger-window duration lines:
%       - Broadband network trigger window (bbdur)
%       - Short-period network trigger window (spdur)
%     These durations are used to estimate waveform ontime/offtime when only
%     triggered WAV files exist (no continuous archive).
%
%   ROLE IN OVERALL ARCHITECTURE:
%   -----------------------------
%   • Sfile represents ONE atomic SEISAN event.
%   • It performs NO catalog-level logic.
%   • It performs NO waveform loading (only stores filenames).
%   • It is designed to be owned by Seisan_Catalog objects.
%
%   In other words:
%       Sfile  = single-event SEISAN parser & metadata container
%       Seisan_Catalog = multi-event container + waveform + analysis layer
%
%   This separation allows:
%     • Clean unit testing of SEISAN parsing
%     • Straightforward migration to MiniSEED/QuakeML in the future
%     • Retention of legacy MVO information not supported by standard SEISAN
%
%   ----------------------------------------------------------------------
%   CONSTRUCTOR:
%
%       s = Sfile(sfilepath)
%       s = Sfile(sfilepath, fileContents)
%
%   INPUTS:
%       sfilepath     : full path to SEISAN S-file
%       fileContents : optional text of S-file (for testing / cached reads)
%
%   OUTPUT:
%       s : Sfile object populated with parsed metadata
%
%   ----------------------------------------------------------------------
%   IMPORTANT PROPERTIES:
%       s.otime        : origin time (datenum)
%       s.ontime       : waveform ontime (from filename or trigger window)
%       s.offtime      : waveform offtime
%       s.latitude     : event latitude
%       s.longitude    : event longitude
%       s.depth        : event depth
%       s.subclass     : MVO volcanic subclass (e.g., r,e,h,l,t)
%       s.wavfiles     : cell array of SEISAN WAV-relative paths
%       s.aef          : amplitude-energy-frequency structure
%       s.arrivals     : GISMO Arrival object
%       s.bbdur        : broadband trigger-window length (s)
%       s.spdur        : short-period trigger-window length (s)
%       s.topdir       : top-level SEISAN archive directory
%       s.reldir       : relative REA/WAV directory for this event
%
%   ----------------------------------------------------------------------
%   STATIC UTILITIES:
%       Sfile.filename2datenum()   : convert S-file names to datenum
%       Sfile.list_sfiles()        : list S-files in a SEISAN database
%       Sfile.readaefline()        : parse AEF summary lines
%       Sfile.readaeffile()        : parse external AEF files
%       Sfile.read_trigger_window_line() : parse trigger durations
%
%   ----------------------------------------------------------------------
%   NOTES ON FAIR DATA & LEGACY ARCHIVES:
%   -------------------------------------
%   This class was developed to support the recovery, reconstruction,
%   and FAIR repackaging of the Montserrat Volcano Observatory SEISAN
%   archive (1995–2010), including features not represented in modern
%   QuakeML / StationXML standards.
%
%   It is therefore correctly located in:
%       contributed_seisan/
%
%   ----------------------------------------------------------------------
%   SEE ALSO:
%       Seisan_Catalog, Arrival, ChannelTag, waveform
%


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
        function s = Sfile(sfilepath, fileContents)
            %Sfile Constructor for Sfile
            %
            % s = Sfile(sfilepath)
            % s = Sfile(sfilepath, fileContents)
            %
            % Example:
            %   sfileObject = Sfile(fullfile('/raid/data/MONTSERRAT/...',
            %       '27-2109-46L.S200202SACPZ.IU.COLA.BHZ'))

            debug.printfunctionstack('>');

            % Echo path (as in original code)
            if nargin >= 1 && ~isempty(sfilepath)
                disp(sfilepath);
            end

            % Validate / load contents
            if ~exist('fileContents', 'var')
                if exist('sfilepath', 'var') && ~isempty(sfilepath)
                    if exist(sfilepath, 'file') == 2
                        fileContents = fileread(sfilepath);
                    else
                        warning('Sfile:%sNotFound', ...
                            sprintf('Sfile %s not found. quitting.', sfilepath));
                        return;
                    end
                else
                    warning('Sfile:NoPath', 'Path to Sfile not given.');
                    help(mfilename);
                    return;
                end
            end

            % Initialize core metadata
            s.sfilepath = sfilepath;

            [ddir, dfile, dext] = fileparts(sfilepath);
            pathparts = split(ddir, 'REA');
            if numel(pathparts) >= 2
                s.topdir = pathparts{1};
                s.reldir = pathparts{2};
            else
                % Fallback if REA not present in path
                s.topdir = ddir;
                s.reldir = '';
            end

            aef          = struct();
            aeflinenum   = 0;
            magnum       = 0;
            bbdur        = s.bbdur;
            spdur        = s.spdur;

            s.ontime = Sfile.filename2datenum([dfile, dext]);

            if debug.get_debug() > 0
                disp(fileContents);
                keyboard;
            end

            % Read lines into cell array (ignore empty lines, like strread did)
            lines = regexp(fileContents, '\r\n|\n|\r', 'split');
            lines = lines(~cellfun('isempty', lines));

            % Echo contents in debug mode
            if debug.get_debug() > 0
                disp(lines);
            end

            % Loop over lines and parse
            linenum          = 1;
            arrival_lines_on = false;
            arrivals         = [];
            arrivalnum       = 0;

            while linenum <= numel(lines)
                tline = lines{linenum};
                linenum = linenum + 1;

                linelength = length(tline);
                % Ensure line is at most 80 chars; S-files are fixed-width 80
                % characters, so pad on the RIGHT if shorter.
                if linelength < 80
                    tline = pad(tline, 80, 'right');
                elseif linelength > 80
                    tline = tline(1:80);
                end

                linelength = length(tline); %#ok<NASGU>

                if ~(ischar(tline) && linelength <= 80)
                    continue;
                end

                lineend = tline(end);

                % --- Type 1 line: Origin & basic event info ---
                if lineend == '1'
                    arrival_lines_on = false;

                    if length(strtrim(tline(2:20))) >= 14
                        s.year  = str2double(tline(2:5));
                        s.month = str2double(tline(7:8));
                        day     = str2double(tline(9:10));
                        hour    = str2double(tline(12:13));
                        minute  = str2double(tline(14:15));
                        second  = str2double(tline(17:20));

                        if ~isnan(second) && floor(second) == 60
                            minute = minute + 1;
                            second = second - 60.0;
                        end

                        if ~any(isnan([s.year, s.month, day, hour, minute, second]))
                            s.otime = datenum(s.year, s.month, day, hour, minute, floor(second));
                        end
                    end

                    s.mainclass = strtrim(tline(22:23));

                    lat   = str2double(tline(24:30));
                    lon   = str2double(tline(31:38));
                    depth = str2double(tline(39:43));

                    if ~isnan(lat);   s.latitude  = lat;   end
                    if ~isnan(lon);   s.longitude = lon;   end
                    if ~isnan(depth); s.depth     = depth; end

                    s.z_indicator = strtrim(tline(44));
                    s.agency      = strtrim(tline(46:48));

                    s.no_sta = str2double(tline(49:51));
                    if isnan(s.no_sta)
                        s.no_sta = 0;
                    end

                    s.rms = str2double(tline(52:55));

                    % up to 3 magnitudes
                    if ~isempty(strtrim(tline(56:59)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value  = str2double(tline(56:59));
                        s.magnitude(magnum).type   = ['m' lower(tline(60))];
                        s.magnitude(magnum).agency = strtrim(tline(61:63));
                    end

                    if ~isempty(strtrim(tline(64:67)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value  = str2double(tline(64:67));
                        s.magnitude(magnum).type   = ['m' lower(tline(68))];
                        s.magnitude(magnum).agency = strtrim(tline(69:71));
                    end

                    if ~isempty(strtrim(tline(72:75)))
                        magnum = magnum + 1;
                        s.magnitude(magnum).value  = str2double(tline(72:75));
                        s.magnitude(magnum).type   = ['m' lower(tline(76))];
                        s.magnitude(magnum).agency = strtrim(tline(77:79));
                    end

                    continue;
                end

                % --- Type 2 line: Macroseismic intensity ---
                if lineend == '2'
                    arrival_lines_on = false;
                    s.maximum_intensity = str2double(tline(28:29));
                    continue;
                end

                % --- Type 3 lines: VOLC summary, AEF, trigger, ExtMag, URL ---
                if lineend == '3'
                    arrival_lines_on = false;

                    if contains(tline, 'VOLC')
                        if contains(tline, 'MAIN')
                            % VOLC MAIN: volcanic subclass
                            s.subclass = tline(12);
                        else
                            % VOLC STA: AEF line
                            [aef, aeflinenum, bbdur, spdur] = ...
                                Sfile.readaefline(tline, aef, aeflinenum, bbdur, spdur);
                            s.bbdur = bbdur;
                            s.spdur = spdur;
                        end

                    elseif ~isempty(strfind(tline, 'trig')) %#ok<*FSTR>
                        [bbdur, spdur] = Sfile.read_trigger_window_line(tline, bbdur, spdur);
                        s.bbdur = bbdur;
                        s.spdur = spdur;

                    elseif strcmp(tline(2:7), 'ExtMag')
                        magnum = magnum + 1;
                        s.magnitude(magnum).value  = str2double(tline(9:12));
                        s.magnitude(magnum).type   = ['m' lower(tline(13))];
                        s.magnitude(magnum).agency = strtrim(tline(14:16));

                    elseif strncmp(tline, 'URL', 3)
                        s.url = strtrim(tline(6:78));
                    end

                    continue;
                end

                % --- Type 6 line: WAV / AEF info ---
                if lineend == '6'
                    arrival_lines_on = false;

                    if isempty(strfind(tline, '___'))
                        % Date/time-of-event-type line
                        s.etime = datenum(sprintf('%s %s:%s:%s', ...
                            tline(2:11), tline(13:14), tline(15:16), tline(18:19)));
                    else
                        % WAV file list line
                        tokens    = strsplit(strtrim(tline(2:79)));
                        s.wavfiles = cellstr(tokens(:));

                        for wavfilenum = 1:numel(s.wavfiles)
                            thisWav = s.wavfiles{wavfilenum};

                            % Look for associated AEF file
                            aeffile = fullfile(s.topdir, 'AEF', s.reldir, [thisWav, '.aef']);
                            if exist(aeffile, 'file') == 2
                                [aef, aeflinenum, bbdur, spdur] = ...
                                    Sfile.readaeffile(aeffile, aef, aeflinenum, bbdur, spdur);
                                s.bbdur = bbdur;
                                s.spdur = spdur;
                            end

                            % Rewrite Wav path relative to WAV/ tree
                            s.wavfiles{wavfilenum} = fullfile('WAV', s.reldir, thisWav);
                        end
                    end

                    continue;
                end

                % --- Type 7: Start of arrival lines ---
                if lineend == '7'
                    arrival_lines_on = true;
                    arrivalnum        = 0;
                    arrivals          = [];
                    clear arr; %#ok<NASGU>
                    ymd = floor(s.ontime);
                    continue;
                end

                % --- Type E: Hyp error estimates ---
                if lineend == 'E'
                    arrival_lines_on = false;

                    s.gap                  = str2double(tline(6:8));
                    s.error.origintime     = str2double(tline(15:20));
                    s.error.latitude       = str2double(tline(25:30));
                    s.error.longitude      = str2double(tline(33:38));
                    s.error.depth          = str2double(tline(39:43));
                    s.error.covxy          = str2double(tline(44:55));
                    s.error.covxz          = str2double(tline(56:67));
                    s.error.covyz          = str2double(tline(68:79));

                    continue;
                end

                % --- Type F: Focal mechanism line ---
                if lineend == 'F'
                    arrival_lines_on = false;

                    s.focmec.strike  = str2double(tline(1:10));
                    s.focmec.dip     = str2double(tline(11:20));
                    s.focmec.rake    = str2double(tline(21:30));
                    s.focmec.agency  = tline(67:69);
                    s.focmec.source  = tline(71:77);
                    s.focmec.quality = tline(78);

                    continue;
                end

                % --- Type H: High-accuracy origin line ---
                if lineend == 'H'
                    arrival_lines_on = false;

                    osec0 = str2double(tline(17:22));
                    yyyy0 = str2double(tline(2:5));
                    mm0   = str2double(tline(7:8));
                    dd0   = str2double(tline(9:10));
                    hh0   = str2double(tline(12:13));
                    mi0   = str2double(tline(14:15));

                    if ~any(isnan([yyyy0 mm0 dd0 hh0 mi0 osec0]))
                        s.otime = datenum(yyyy0, mm0, dd0, hh0, mi0, osec0);
                    end

                    s.latitude  = str2double(tline(24:32));
                    s.longitude = str2double(tline(34:43));
                    s.depth     = str2double(tline(45:52));
                    s.rms       = str2double(tline(54:59));

                    continue;
                end

                % --- Type I: Action / analyst line ---
                if lineend == 'I'
                    arrival_lines_on = false;

                    s.last_action = strtrim(tline(9:11));
                    s.action_time = strtrim(tline(13:26));

                    if ~isempty(s.action_time)
                        if s.action_time(1) == '9'
                            s.action_time = sprintf('19%s', s.action_time);
                        else
                            s.action_time = sprintf('20%s', s.action_time);
                        end
                    end

                    s.analyst = strtrim(tline(31:33));
                    s.id      = str2double(tline(61:74));

                    continue;
                end

                % --- Arrival lines (after type 7) ---
                if arrival_lines_on && lineend == ' '
                    sta = strtrim(tline(2:5));
                    if isempty(sta)
                        % blank-ish arrival line
                        continue;
                    end

                    if length(sta) > 2
                        arrivalnum = arrivalnum + 1;

                        if ~exist('arr', 'var')
                            arr.sta    = {};
                            arr.iphase = {};
                            arr.atime  = [];
                            arr.tres   = [];
                            arr.weight = [];
                        end

                        arr.sta{arrivalnum}    = sta;
                        arr.iphase(arrivalnum) = tline(11);

                        hh0 = str2double(tline(19:20));
                        mi0 = str2double(tline(21:22));
                        ss0 = str2double(tline(24:28));

                        str_tres = strtrim(tline(65:68));
                        if ~isempty(str_tres)
                            arr.tres(arrivalnum) = str2double(str_tres);
                        else
                            arr.tres(arrivalnum) = NaN;
                        end

                        str_weight = strtrim(tline(69:70));
                        if ~isempty(str_weight)
                            arr.weight(arrivalnum) = str2double(str_weight);
                        else
                            arr.weight(arrivalnum) = NaN;
                        end

                        arr.atime(arrivalnum) = ymd + hh0/24 + mi0/1440 + ss0/86400;
                    end
                end

            end % while lines

            % Store AEF
            s.aef = aef;

            % Create Arrival object
            if exist('arr', 'var') && (~exist('arrivalnum', 'var') || arrivalnum > 0)
                s.arrivals = Arrival( ...
                    cellstr(arr.sta), ...
                    cellstr(''), ...
                    arr.atime(:), ...
                    cellstr(arr.iphase(:)), ...
                    'timeres', arr.tres ...
                );
            else
                s.arrivals = Arrival();
            end

            % Compute off time from bb/sp durations (in seconds)
            wavfile_duration_seconds = nanmax([s.bbdur, s.spdur]);
            if ~isnan(wavfile_duration_seconds)
                s.offtime = s.ontime + wavfile_duration_seconds / 86400;
            end

            debug.printfunctionstack('<');
        end
    end

    methods(Static)
        function dnum = filename2datenum(sfilebasename)
            % SFILE.FILENAME2DATENUM convert Seisan S-file name to datenum
            ddstr = sfilebasename(1:2);
            hhstr = sfilebasename(4:5);
            mistr = sfilebasename(6:7);
            ssstr = sfilebasename(9:10);
            yystr = sfilebasename(14:17);
            mm    = str2double(sfilebasename(18:19));
            months = ['Jan';'Feb';'Mar';'Apr';'May';'Jun'; ...
                      'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'];
            mmstr = months(mm, :);

            datestring = [ddstr,'-',mmstr,'-',yystr,' ',hhstr,':',mistr,':',ssstr];
            try
                dnum = datenum(datestring);
            catch
                warning('Sfile:BadDate', ...
                    'Could not convert %s to datenum for sfile=%s. Returning NaN', ...
                    datestring, sfilebasename);
                dnum = NaN;
            end
        end


        function files = list_sfiles(dbpath, snum, enum)
            % SFILE.LIST_SFILES List S-files in SEISAN REA db
            %
            % files = SFILE.LIST_SFILES(dbpath, snum, enum)
            %
            %   dbpath : path to REA database (e.g., .../REA/MVOE_)
            %   snum   : start time (datenum)
            %   enum   : end time (datenum)
            %
            % Returns struct array of dir() entries with added .dir field.

            debug.printfunctionstack('>');

            files = [];

            if ~exist(dbpath, 'dir')
                fprintf('dbpath %s not found\n', dbpath);
                debug.printfunctionstack('<');
                return;
            end

            fprintf('Generating a list of S-files matching %s to %s ...\n', ...
                datestr(snum), datestr(enum));

            sdv = datevec(snum);
            edv = datevec(enum);

            for yyyy = sdv(1):edv(1)
                if yyyy == sdv(1) && yyyy == edv(1)
                    mmrange = sdv(2):edv(2);
                elseif yyyy == sdv(1)
                    mmrange = sdv(2):12;
                elseif yyyy == edv(1)
                    mmrange = 1:edv(2);
                else
                    mmrange = 1:12;
                end

                for mm = mmrange
                    seisandir = fullfile(dbpath, sprintf('%4d', yyyy), sprintf('%02d', mm));
                    if ~exist(seisandir, 'dir')
                        continue;
                    end

                    newfiles = dir(fullfile(seisandir, sprintf('*%4d%02d', yyyy, mm)));
                    for i = 1:length(newfiles)
                        dnum = Sfile.filename2datenum(newfiles(i).name);
                        if dnum >= snum && dnum <= enum
                            newfiles(i).dir = seisandir;
                            files = [files; newfiles(i)]; %#ok<AGROW>
                        elseif dnum > enum
                            break;
                        end
                    end
                end
            end

            fprintf('There are %d S-files matching your request in %s\n', ...
                numel(files), dbpath);

            debug.printfunctionstack('<');
        end


        function [aef, aeflinenum, bbdur, spdur] = readaefline(tline, aef, aeflinenum, bbdur, spdur)
            % Read amp/energy/frequency line (VOLC STA) or trigger-window line
            aeflinenum = aeflinenum + 1;

            if contains(tline(1:5), 'VOLC')
                thissta  = strtrim(tline(7:10));
                thischan = strtrim(tline(12:15));
                aef.ctag(aeflinenum) = ChannelTag('', thissta, '', thischan);

                % A field: amplitude
                idxA = strfind(tline(15:20), 'A');
                if ~isempty(idxA)
                    findamp = idxA(1) + 14;
                    aef.amp(aeflinenum) = str2double(tline(findamp+1:findamp+8));
                else
                    aef.amp(aeflinenum) = NaN;
                end

                % E field: energy
                idxE = strfind(tline(findamp+7:findamp+17), 'E');
                if ~isempty(idxE)
                    findeng = idxE(1) + findamp + 6;
                    aef.eng(aeflinenum) = str2double(tline(findeng+1:findeng+8));
                else
                    aef.eng(aeflinenum) = NaN;
                end

                % F field: SSAM bins + pkf
                idxF = strfind(tline(findeng+7:findeng+10), 'F');
                ssam = nan(1, 12);
                if ~isempty(idxF)
                    findfft = idxF(1) + findeng + 6;
                    for i = 1:12
                        startindex = findfft + 1 + (i-1)*3;
                        ssam(i) = str2double(tline(startindex:startindex+1));
                    end
                end
                aef.ssam{aeflinenum} = ssam;

                aef.pkf(aeflinenum) = str2double(tline(73:78));  % Peak frequency

            else
                % Trigger window line (eg "trigger window = 105.7 s")
                [bbdur, spdur] = Sfile.read_trigger_window_line(tline, bbdur, spdur);
            end
        end


        function [aef, aeflinenum, bbdur, spdur] = readaeffile(aeffile, aef, aeflinenum, bbdur, spdur)
            % Read a standalone AEF file and append to existing AEF struct.
            disp(aeffile);

            if ~exist('aeffile', 'var') || isempty(aeffile)
                warning('Sfile:NoAEFPath', 'Path to AEF file not given.');
                help(mfilename);
                return;
            end

            if exist(aeffile, 'file') ~= 2
                warning('Sfile:AEFNotFound', 'AEF file %s not found. quitting.', aeffile);
                return;
            end

            fileContents = fileread(aeffile);

            % Read lines into cell array
            lines = regexp(fileContents, '\r\n|\n|\r', 'split');
            lines = lines(~cellfun('isempty', lines));

            if debug.get_debug() > 0
                disp(lines);
            end

            linenum = 1;
            while linenum <= numel(lines)
                tline = lines{linenum};
                linenum = linenum + 1;

                linelength = length(tline);
                if linelength < 80
                    tline = pad(tline, 80, 'right');
                elseif linelength > 80
                    tline = tline(1:80);
                end

                if ischar(tline) && length(tline) <= 80
                    lineend = tline(end);
                    if lineend == '3'
                        [aef, aeflinenum, bbdur, spdur] = ...
                            Sfile.readaefline(tline, aef, aeflinenum, bbdur, spdur);
                    end
                else
                    continue;
                end
            end
        end


        function [bbdur, spdur] = read_trigger_window_line(tline, bbdur, spdur)
            % Parse broadband / short-period trigger window durations
            %
            % Notes:
            %   - bbdur, spdur are in seconds
            %   - We keep passing in/out previous values so we don't overwrite
            %     earlier valid durations with NaN.

            if nargin < 2 || isempty(bbdur); bbdur = NaN; end
            if nargin < 3 || isempty(spdur); spdur = NaN; end

            % broadband: "trigger window = XXXs"
            pos = strfind(tline, 'trigger window');
            if ~isempty(pos)
                durstr     = tline(pos+14:pos+19);
                durfields  = split(durstr, '=');
                if numel(durfields) == 2
                    durstr2    = durfields{2};
                    durfields2 = split(durstr2, 's');
                    tmp        = str2double(durfields2{1});
                    if ~isnan(tmp)
                        bbdur = tmp;
                    end
                end
            end

            % short-period: "sptrig=XXXs" or "sptrig window=XXXs"
            pos = strfind(tline, 'sptrig');
            if ~isempty(pos)
                durstr     = tline(pos+6:pos+10);
                durfields  = split(durstr, '=');
                if numel(durfields) == 2
                    durstr2    = durfields{2};
                    durfields2 = split(durstr2, 's');
                    tmp        = str2double(durfields2{1});
                    if ~isnan(tmp)
                        spdur = tmp;
                    end
                end
            end
        end

    end % static methods

end
