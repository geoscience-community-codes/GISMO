%SACPZ Canonical pole-zero instrument response class for GISMO
%
%   This class is the single authoritative representation of pole-zero based
%   instrument responses in GISMO.
%
%   Supported SACPZ dialects:
%     (1) IRIS-style SACPZ with '*' header lines and ISO timestamps
%     (2) Plain "KEY : VALUE" headers with ISO timestamps (optional 'Z' and fractional seconds)
%     (3) Older SAC-style headers with START/END like "YYYY,DDD,HH:MM:SS.ssss"
%
%   Also tolerant of:
%     - END : None
%     - END : No Ending Time
%     - COMPONENT used instead of CHANNEL
%     - RATE (HZ) used instead of SAMPLE RATE
%
%   Usage:
%     pz = sacpz(fileread('SACPZ.IU.COLA.BHZ'))
%     pz = sacpz('SACPZ.IU.COLA.BHZ')
%     pz = sacpz(webread('http://...'))  % content string
%
%   One sacpz object is returned per epoch if the file contains multiple epochs.

classdef sacpz

    properties
        % Core pole-zero model
        z = complex([]);         % Zeros
        p = complex([]);         % Poles
        k = NaN;                 % Overall gain (SAC CONSTANT)

        % Validity times
        created   = NaN;
        starttime = NaN;
        endtime   = NaN;

        % Channel metadata
        network   = '';
        station   = '';
        location  = '';
        channel   = '';

        % Geometry
        latitude  = NaN;
        longitude = NaN;
        elevation = NaN;
        depth     = NaN;
        dip       = NaN;
        azimuth   = NaN;

        % Sampling + units
        samplerate = NaN;
        inputunit  = '';
        outputunit = '';

        % Instrument info
        instrumenttype = '';
        instrumentgain = '';
        instrumentgainunits = '';
        sensitivity = '';
        sensitivityunits = '';
        description = '';
        comment = '';
        a0 = NaN;
    end

    %======================================================================
    % CONSTRUCTOR
    %======================================================================
    methods
        function obj = sacpz(source)
            %SACPZ Construct from:
            %   • File path
            %   • Raw SACPZ text
            %   • IRIS URL

            if nargin == 0
                return
            end

            if ~(ischar(source) || isstring(source))
                error('sacpz:constructor:invalidInput', ...
                    'Input must be a filename, URL, or file contents string.');
            end

            source = char(source);

            if strncmpi(source,'http://',7) || strncmpi(source,'https://',8)
                txt = webread(source);
            elseif exist(source,'file')
                txt = fileread(source);
            else
                txt = source; % assume raw text
            end

            if isempty(txt)
                return
            end

            obj = obj.parse_sacpz_text(txt);
        end
    end

    %======================================================================
    % HIGH-LEVEL OPERATIONS
    %======================================================================
    methods
        function [num,den] = transfer(obj)
            %TRANSFER Return continuous-time transfer function
            [num,den] = zp2tf(obj.z, obj.p, obj.k);
        end

        function response = to_response(obj, frequencies)
            %TO_RESPONSE Create GISMO response struct compatible with the
            %+instrument_response package (e.g., response_apply).
            %
            % RESPONSE = obj.to_response(FREQUENCIES) computes complex response
            % from P/Z/K at FREQUENCIES (Hz). Uses SAC CONSTANT (obj.k) as gain.
            %
            % This yields OUTPUT UNIT per INPUT UNIT (often COUNTS per METER or
            % COUNTS per (M/S), depending on SACPZ).

            if nargin < 2 || isempty(frequencies)
                error('sacpz:to_response:missingFrequencies', ...
                    'A frequency vector (Hz) must be provided.');
            end
            if ~isfinite(obj.k)
                error('sacpz:to_response:missingConstant', ...
                    'SACPZ CONSTANT (obj.k) is missing or invalid.');
            end

            response.scnl = scnlobject(obj.station, obj.channel, obj.network, obj.location);
            response.time = obj.starttime;
            response.frequencies = frequencies(:);
            response.values = [];
            response.calib = obj.k;   % keep the gain visible
            response.units = obj.outputunit;
            response.sampleRate = obj.samplerate;
            response.source = 'sacpz.to_response';
            response.status = [];

            ws = 2*pi*response.frequencies; % rad/s
            response.values = freqs(obj.k * poly(obj.z), poly(obj.p), ws);
        end

        function response = to_response_structure(obj, frequencies)
            %TO_RESPONSE_STRUCTURE Backward-compatible alias for older code
            response = obj.to_response(frequencies);
            response.source = 'sacpz.to_response_structure';
        end

        function plot(obj)
            %PLOT Poles, impulse response, and frequency response
            figure, zplane(obj.z, obj.p), title('Poles and Zeros')
            sos = zp2sos(obj.z, obj.p, obj.k);
            figure, impz(sos), title('Impulse Response')
            figure, freqz(sos), title('Frequency Response')
        end
    end

    %======================================================================
    % STATIC LOADERS (OPTIONAL)
    %======================================================================
    methods (Static)
        function obj = from_antelope(sta, chan, time, dbName)
            %FROM_ANTELOPE Load response from Antelope database
            %
            %   pz = sacpz.from_antelope('OKSO','BHZ',datenum(...),dbName)
            %
            % Requires Antelope MATLAB toolbox.

            db = dbopen(dbName,'r');
            dbs = dblookup_table(db,'sensor');
            t = datenum2epoch(time);

            dbs = dbsubset(dbs, ...
                sprintf('sta=="%s" && chan=="%s" && time<=%f && endtime>=%f', ...
                        sta, chan, t, t));

            dbi = dblookup_table(dbs,'instrument');
            dbc = dblookup_table(dbi,'calibration');

            dbj = dbjoin(dbs,dbi);
            dbj = dbjoin(dbj,dbc);

            dbj.record = 0;
            [samprate, calib, dir, dfile] = ...
                dbgetv(dbj,'samprate','calib','dir','dfile');

            respfile = fullfile(dir,dfile);
            ro = dbresponse(respfile);

            [p,z,k] = response_to_pzk(ro);
            free_response(ro);
            dbclose(db);

            obj = sacpz();
            obj.p = p(:);
            obj.z = z(:);
            obj.k = k * calib;
            obj.station = sta;
            obj.channel = chan;
            obj.starttime = time;
            obj.samplerate = samprate;
        end
    end

    %======================================================================
    % INTERNAL PARSING
    %======================================================================
    methods (Access=private)

        function obj = parse_sacpz_text(obj, txt)
            persistent fieldmap
            if isempty(fieldmap)
                fieldmap = getFieldmap();
            end

            epochs = splitEpochsFlexible(txt);

            obj = repmat(obj, 1, numel(epochs));

            for N = 1:numel(epochs)
                epochText = epochs{N};

                [headerText, respText] = splitHeaderAndResponse(epochText);

                [obj(N).p, obj(N).z, obj(N).k] = parsePZC(respText);

                H = getHeaderLinesFlexible(headerText);
                [hFields, hValues] = cellfun(@parseHeaderLineFlexible, H, 'UniformOutput', false);

                for M = 1:numel(hFields)
                    f = hFields{M};
                    vRaw = hValues{M};
                    if isempty(f)
                        continue
                    end

                    fKey = upper(f);

                    % convert by type
                    switch fKey
                        case {'START','END','CREATED'}
                            v = parseDateFlexible(vRaw);

                        case {'LONGITUDE','LATITUDE','ELEVATION','DEPTH','DIP','AZIMUTH',...
                              'SAMPLE RATE','A0','RATE (HZ)','RATE'}
                            v = str2double(vRaw);

                        case {'INSTGAIN','SENSITIVITY'}
                            [v, units] = splitOffUnits(vRaw);
                            unitfield = [fKey, 'UNITS'];
                            if fieldmap.isKey(unitfield)
                                obj(N).(fieldmap(unitfield)) = units;
                            end

                        otherwise
                            v = vRaw;
                    end

                    if fieldmap.isKey(fKey)
                        obj(N).(fieldmap(fKey)) = v;
                    else
                        % Unknown keys vary across providers; keep tolerant.
                        warning('sacpz:unknownHeaderKey', 'Unknown SACPZ header key: "%s"', f);
                    end
                end
            end

            % ------------ nested helpers ------------

            function [val, unit] = splitOffUnits(val)
                % Handles "381407000.0 (M/S)" or "2.023580e+03 (M/S)" or "123"
                unit = '';
                if isempty(val), return, end
                val = strtrim(val);

                tok = regexp(val,'^\s*([+\-]?\d+(\.\d+)?([eE][+\-]?\d+)?)\s*(\(([^)]+)\))?\s*$','tokens','once');
                if ~isempty(tok)
                    val = str2double(tok{1});
                    if numel(tok) >= 5 && ~isempty(tok{5})
                        unit = tok{5};
                    end
                    return
                end

                tmp = textscan(val,'%f %s');
                val = tmp{1};
                if ~isempty(tmp{2}) && ~isempty(tmp{2}{1})
                    unit = tmp{2}{1};
                end
            end

            function epochs = splitEpochsFlexible(t)
                t = normalizeNewlines(t);
                chunks = regexp(t, '\n\s*\n\s*\n+', 'split');
                chunks = chunks(~cellfun(@isempty, strtrim(chunks)));
                if isempty(chunks)
                    epochs = {t};
                else
                    epochs = chunks;
                end
            end

            function [header, resp] = splitHeaderAndResponse(t)
                t = normalizeNewlines(t);

                idxZ = regexpi(t, '(^|\n)\s*ZEROS\b', 'once');
                idxP = regexpi(t, '(^|\n)\s*POLES\b', 'once');
                idxC = regexpi(t, '(^|\n)\s*CONSTANT\b', 'once');

                idxs = [idxZ idxP idxC];
                idxs(idxs==0) = NaN;
                idx = min(idxs);

                if isempty(idx) || isnan(idx)
                    header = t;
                    resp = '';
                else
                    header = t(1:idx-1);
                    resp = t(idx:end);
                end
            end

            function t = normalizeNewlines(t)
                t = strrep(t, sprintf('\r\n'), sprintf('\n'));
                t = strrep(t, sprintf('\r'), sprintf('\n'));
            end

            function lines = getHeaderLinesFlexible(headerText)
                headerText = normalizeNewlines(headerText);
                lines = textscan(headerText, '%s', 'Delimiter', '\n');
                lines = lines{1};
                lines = strtrim(lines);
                lines(cellfun(@isempty, lines)) = [];
            end

            function [field, val] = parseHeaderLineFlexible(t)
                % Accepts:
                %  "* NETWORK (KNETWK): IU"
                %  "NETWORK : AM"
                %  "DIP (SEED) : -90.0"
                t = strtrim(t);
                if startsWith(t,'*')
                    t = strtrim(t(2:end));
                end

                colLoc = find(t==':',1,'first');
                if isempty(colLoc)
                    field = ''; val = '';
                    return
                end

                field = strtrim(t(1:colLoc-1));
                val   = strtrim(t(colLoc+1:end));

                % Remove any parenthetical codes from the field name
                parenLoc = find(field=='(',1,'first');
                if ~isempty(parenLoc)
                    field = strtrim(field(1:parenLoc-1));
                end

                % Normalize whitespace in field
                field = regexprep(field, '\s+', ' ');
            end

            function d = parseDateFlexible(s)
                % Handles:
                %  "2021-05-29T05:22:04.965997Z"
                %  "1999,160,20:40:00.0000"
                %  "None" / "No Ending Time"
                s = strtrim(s);
                if isempty(s) || strcmpi(s,'None') || contains(lower(s),'no ending time')
                    d = NaN;
                    return
                end

                % Strip trailing Z
                if endsWith(s,'Z')
                    s = s(1:end-1);
                end

                % ISO: keep only yyyy-mm-ddTHH:MM:SS
                sIso = regexp(s,'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}','match','once');
                if ~isempty(sIso)
                    d = datenum(sIso, 'yyyy-mm-ddTHH:MM:SS');
                    return
                end

                % SAC julian: yyyy,ddd,HH:MM:SS(.ffff)
                tok = regexp(s,'^(\d{4}),(\d{1,3}),(\d{2}):(\d{2}):(\d{2})(\.\d+)?$','tokens','once');
                if ~isempty(tok)
                    yr  = str2double(tok{1});
                    jdy = str2double(tok{2});
                    hh  = str2double(tok{3});
                    mm  = str2double(tok{4});
                    ss  = str2double(tok{5});
                    frac = 0;
                    if ~isempty(tok{6})
                        frac = str2double(tok{6}); % e.g., .0000
                    end
                    d0 = datenum(yr,1,1,0,0,0);
                    d  = d0 + (jdy-1) + datenum(0,0,0,hh,mm,ss+frac);
                    return
                end

                % Fallback
                try
                    d = datenum(s);
                catch
                    d = NaN;
                end
            end

            function [p, z, c] = parsePZC(t)
                t = normalizeNewlines(t);
                lines = textscan(t,'%s','delimiter','\n');
                lines = strtrim(lines{:});
                lines(cellfun(@isempty,lines)) = [];

                z = getComplex('ZEROS', lines);
                p = getComplex('POLES', lines);

                ConstHeader = find(strncmpi('CONSTANT', lines, 8), 1, 'first');
                if ~isempty(ConstHeader)
                    c = str2double(strtrim(lines{ConstHeader}(9:end)));
                else
                    c = NaN;
                end
            end

            function x = getComplex(fName, lines)
                % If fewer than nValues are provided, the remainder are 0+0i
                x = complex([]);
                header = find(strncmpi(lines, fName, length(fName)), 1, 'first');
                if isempty(header)
                    return
                end

                fLen = length(fName);
                nValues = str2double(strtrim(lines{header}(fLen+1:end)));
                if isnan(nValues) || nValues < 0
                    nValues = 0;
                end

                x = complex(zeros(nValues,1));

                q = 0;
                kLine = header + 1;

                while q < nValues && kLine <= numel(lines)
                    L = strtrim(lines{kLine});
                    LU = upper(L);

                    % Stop if next section begins
                    if startsWith(LU,'POLES') || startsWith(LU,'ZEROS') || startsWith(LU,'CONSTANT')
                        break
                    end

                    vals = str2num(L); %#ok<ST2NM>
                    if numel(vals) >= 2
                        q = q + 1;
                        x(q) = vals(1) + vals(2) * 1i;
                    end

                    kLine = kLine + 1;
                end
                % Any unfilled entries remain 0+0i
            end

            function M = getFieldmap()
                % Maps many SACPZ dialect header keys -> sacpz properties
                M = containers.Map('KeyType', 'char', 'ValueType', 'char');

                % Identification
                M('NETWORK')   = 'network';
                M('STATION')   = 'station';
                M('LOCATION')  = 'location';
                M('CHANNEL')   = 'channel';
                M('COMPONENT') = 'channel'; % older SAC files

                % Times
                M('CREATED') = 'created';
                M('START')   = 'starttime';
                M('END')     = 'endtime';

                % Descriptions
                M('DESCRIPTION') = 'description';
                M('SITE NAME')   = 'description';
                M('OWNER')       = 'comment';
                M('INSTRUMENT COMMENT') = 'comment';
                M('COMMENT')     = 'comment';

                % Location/orientation
                M('LATITUDE')   = 'latitude';
                M('LONGITUDE')  = 'longitude';
                M('ELEVATION')  = 'elevation';
                M('DEPTH')      = 'depth';
                M('DIP')        = 'dip';
                M('AZIMUTH')    = 'azimuth';

                % Sample rate
                M('SAMPLE RATE') = 'samplerate';
                M('RATE (HZ)')   = 'samplerate';
                M('RATE')        = 'samplerate'; % because we strip "(HZ)" -> "RATE"

                % Units
                M('INPUT UNIT')  = 'inputunit';
                M('OUTPUT UNIT') = 'outputunit';

                % Instrument
                M('INSTTYPE')     = 'instrumenttype';
                M('INSTRUMENT')   = 'instrumenttype';

                % Gains/sensitivity
                M('INSTGAIN')         = 'instrumentgain';
                M('INSTGAINUNITS')    = 'instrumentgainunits';
                M('SENSITIVITY')      = 'sensitivity';
                M('SENSITIVITYUNITS') = 'sensitivityunits';

                % Misc
                M('A0') = 'a0';
            end
        end
    end
end