%SACPZ Class for reading SAC pole-zero files (multiple dialects)
% Supports:
%  (1) IRIS-style SACPZ with '*' header lines and ISO timestamps
%  (2) Plain "KEY : VALUE" headers with ISO timestamps + optional 'Z' + fractional seconds
%  (3) Older SAC-style headers with START/END like "YYYY,DDD,HH:MM:SS.ssss"
%
% Also tolerant of:
%  - END : None
%  - END : No Ending Time
%  - COMPONENT used instead of CHANNEL
%  - RATE (HZ) used instead of SAMPLE RATE
%
% Usage:
%   pz = sacpz(fileread('SACPZ.IU.COLA.BHZ'))
%   pz = sacpz('SACPZ.IU.COLA.BHZ')
%   pz = sacpz(webread('http://...'))  % content string
%
% One sacpz object is returned per epoch if the file contains multiple epochs.

classdef sacpz
    properties
        z = [];
        p = [];
        k = [];
        created = NaN;
        starttime = NaN;
        endtime = NaN;
        network = '';
        station = '';
        location = '';
        channel = '';
        latitude = NaN;
        longitude = NaN;
        depth = NaN;
        elevation = NaN;
        dip = NaN;
        azimuth = NaN;
        samplerate = NaN;
        description = '';
        inputunit = '';
        outputunit = '';
        instrumenttype = '';
        instrumentgain = '';
        instrumentgainunits = '';
        comment = '';
        sensitivity = '';
        sensitivityunits = '';
        a0 = NaN;
    end

    methods
        function s = sacpz(filename)
            %sacpz.sacpz Constructor for sacpz
            % pz = sacpz(fileContents)
            % pz = sacpz(webpage)  % string begins with http:// or https://
            % pz = sacpz(file)

            if nargin == 0
                return;
            end

            % Read file/URL/content into a string
            if ischar(filename) || isstring(filename)
                filename = char(filename);
            else
                error('sacpz:constructor:invalidInput', 'Input must be a filename, URL, or file contents string.');
            end

            if length(filename) > 7 && (strncmpi(filename,'http://',7) || strncmpi(filename,'https://',8))
                fcontents = webread(filename);
            elseif exist(filename,'file')
                fcontents = fileread(filename);
            else
                fcontents = filename; % assume it's file contents
            end

            if isempty(fcontents)
                return;
            end

            s = s.new_readroutine(fcontents);
        end

        function obj = new_readroutine(obj, fileContents)
            persistent fieldmap
            if isempty(fieldmap)
                fieldmap = getFieldmap();
            end

            epochs = splitEpochsFlexible(fileContents);

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

                    % convert by type
                    switch upper(f)
                        case {'START','END','CREATED'}
                            v = parseDateFlexible(vRaw);

                        case {'LONGITUDE','LATITUDE','ELEVATION','DEPTH','DIP','AZIMUTH','SAMPLE RATE','A0','RATE (HZ)'}
                            v = str2double(vRaw);

                        case {'INSTGAIN','SENSITIVITY'}
                            [v, units] = splitOffUnits(vRaw);
                            unitfield = [upper(f), 'UNITS'];
                            if fieldmap.isKey(unitfield)
                                obj(N).(fieldmap(unitfield)) = units;
                            end

                        otherwise
                            v = vRaw;
                    end

                    fKey = upper(f);

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
                % Handles e.g. "381407000.0 (M/S)" or "2.023580e+03 (M/S)" or "123"
                unit = '';
                if isempty(val)
                    return
                end
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

            function epochs = splitEpochsFlexible(txt)
                txt = normalizeNewlines(txt);

                % Split on 2+ blank lines (common multi-epoch separator)
                chunks = regexp(txt, '\n\s*\n\s*\n+', 'split');
                chunks = chunks(~cellfun(@isempty, strtrim(chunks)));

                if isempty(chunks)
                    epochs = {txt};
                else
                    epochs = chunks;
                end
            end

            function [header, resp] = splitHeaderAndResponse(txt)
                txt = normalizeNewlines(txt);

                idxZ = regexpi(txt, '(^|\n)\s*ZEROS\b', 'once');
                idxP = regexpi(txt, '(^|\n)\s*POLES\b', 'once');
                idxC = regexpi(txt, '(^|\n)\s*CONSTANT\b', 'once');

                idxs = [idxZ idxP idxC];
                idxs(idxs==0) = NaN;
                idx = min(idxs);

                if isempty(idx) || isnan(idx)
                    header = txt;
                    resp = '';
                else
                    header = txt(1:idx-1);
                    resp = txt(idx:end);
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
                %  "2020-07-06T19:25:06.642000Z"
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
                x = [];
                fNameU = upper(fName);

                header = find(strncmpi(fNameU, upper(lines), length(fNameU)), 1, 'first');
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

                % If fewer than nValues were provided, remainder remain 0+0i
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
                M('CHANNELTAG') = 'channel'; %#ok<NASGU> % (unused but harmless)

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

                % Units
                M('INPUT UNIT')  = 'inputunit';
                M('OUTPUT UNIT') = 'outputunit';

                % Instrument
                M('INSTTYPE')     = 'instrumenttype';
                M('INSTRUMENT')   = 'instrumenttype';

                % Gains/sensitivity
                M('INSTGAIN')        = 'instrumentgain';
                M('INSTGAINUNITS')   = 'instrumentgainunits';
                M('SENSITIVITY')     = 'sensitivity';
                M('SENSITIVITYUNITS')= 'sensitivityunits';

                % Misc
                M('A0') = 'a0';
            end
        end

        %% -----------------------------------------------
        function plot(obj)
            %sacpz.plot() Plot poles & zeros, impulse response & frequency response

            figure(1)
            zplane(obj.z, obj.p)

            figure(2)
            sos = zp2sos(obj.z, obj.p, obj.k);
            impz(sos)

            figure(3)
            freqz(sos)
        end

        function [num,den] = transfer(obj)
            %sacpz.transfer Transfer function numerator/denominator from P/Z/K
            [num,den] = zp2tf(obj.z, obj.p, obj.k);
        end

        %% -----------------------------------------------
        function response = to_response(obj, frequencies)
            %sacpz.to_response  Create GISMO response structure compatible with
            %the +instrument_response package (e.g., response_apply).
            %
            % RESPONSE = obj.to_response(FREQUENCIES) returns a response structure
            % computed from poles/zeros using SAC CONSTANT (obj.k) as the gain.
            % This yields OUTPUT UNIT per INPUT UNIT (typically COUNTS per METER
            % or COUNTS per (M/S), depending on the SACPZ file).
            %
            % frequencies: vector in Hz

            if nargin < 2 || isempty(frequencies)
                error('sacpz:to_response:missingFrequencies', ...
                    'A frequency vector (Hz) must be provided.');
            end

            if isempty(obj.k) || ~isfinite(obj.k)
                error('sacpz:to_response:missingConstant', ...
                    'SACPZ CONSTANT (obj.k) is missing or invalid.');
            end

            response.scnl = scnlobject(obj.station,obj.channel,obj.network,obj.location);
            response.time = obj.starttime;
            response.frequencies = reshape(frequencies,numel(frequencies),1);
            response.values = [];
            response.calib = NaN;
            response.units = obj.outputunit;
            response.sampleRate = obj.samplerate;
            response.source = 'sacpz.to_response';
            response.status = [];

            ws = (2*pi) .* response.frequencies; % rad/s
            response.values = freqs(obj.k * poly(obj.z), poly(obj.p), ws);
        end
    end
end