classdef sacpz
%SACPZ Canonical pole-zero instrument response class for GISMO
%
%   This class is the single authoritative representation of all
%   pole-zero based instrument responses in GISMO.
%
%   Supported sources:
%       • SACPZ text files
%       • IRIS web SACPZ services
%       • Antelope databases (static loader)
%
%   All legacy polezero structs and response_get_from_polezero() are
%   deprecated and replaced by this class.

    properties
        % Core pole-zero model
        z = complex([]);         % Zeros
        p = complex([]);         % Poles
        k = NaN;                 % Overall gain

        % Validity times
        created   = NaN
        starttime = NaN
        endtime   = NaN

        % Channel metadata
        network   = ''
        station   = ''
        location  = ''
        channel   = ''

        % Geometry
        latitude  = NaN
        longitude = NaN
        elevation = NaN
        depth     = NaN
        dip       = NaN
        azimuth   = NaN

        % Sampling + units
        samplerate = NaN
        inputunit  = ''
        outputunit = ''

        % Instrument info
        instrumenttype = ''
        instrumentgain = ''
        instrumentgainunits = ''
        sensitivity = ''
        sensitivityunits = ''
        description = ''
        comment = ''
        a0 = NaN
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

            if ischar(source) || isstring(source)
                source = char(source);

                if strncmpi(source,'http',4)
                    txt = webread(source);
                elseif exist(source,'file')
                    txt = fileread(source);
                else
                    txt = source;   % assume raw text
                end

                obj = obj.parse_sacpz_text(txt);
            end
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

        function response = to_response_structure(obj, frequencies)
            %TO_RESPONSE_STRUCTURE Create legacy GISMO response struct

            response.scnl = scnlobject( ...
                obj.station, obj.channel, obj.network, obj.location);

            response.time        = obj.starttime;
            response.frequencies = frequencies(:);
            response.calib       = obj.k;
            response.units       = obj.outputunit;
            response.sampleRate  = obj.samplerate;
            response.source      = 'SACPZ';
            response.status      = '';

            ws = 2*pi*response.frequencies;
            num = poly(obj.z);
            den = poly(obj.p);
            scale = obj.k;

            response.values = scale * freqs(num, den, ws);
        end

        function plot(obj)
            %PLOT Poles, impulse response, and frequency response

            figure, zplane(obj.z, obj.p)
            title('Poles and Zeros')

            sos = zp2sos(obj.z, obj.p, obj.k);

            figure, impz(sos)
            title('Impulse Response')

            figure, freqz(sos)
            title('Frequency Response')
        end
    end

    %======================================================================
    % STATIC LOADERS
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
            epochs = strsplit(txt,'\n\n\n');
            epochs = epochs(~cellfun(@isempty,epochs));

            block = epochs{1};

            % Headers
            hdr = regexp(block,'\*([^\n]+)','tokens');
            for i = 1:numel(hdr)
                kv = strsplit(strtrim(hdr{i}{1}),':');
                if numel(kv) < 2, continue, end
                key = strtrim(kv{1});
                val = strtrim(kv{2});

                switch upper(key)
                    case 'NETWORK';   obj.network = val;
                    case 'STATION';   obj.station = val;
                    case 'CHANNEL';   obj.channel = val;
                    case 'LOCATION';  obj.location = val;
                    case 'START';     obj.starttime = datenum(val,'yyyy-mm-ddTHH:MM:SS');
                    case 'END';       obj.endtime   = datenum(val,'yyyy-mm-ddTHH:MM:SS');
                    case 'LATITUDE';  obj.latitude  = str2double(val);
                    case 'LONGITUDE'; obj.longitude = str2double(val);
                    case 'ELEVATION'; obj.elevation = str2double(val);
                    case 'SAMPLE RATE'; obj.samplerate = str2double(val);
                    case 'INPUT UNIT';  obj.inputunit  = val;
                    case 'OUTPUT UNIT'; obj.outputunit = val;
                end
            end

            % Poles/zeros/constant
            Z = regexp(block,'ZEROS\s+\d+([\s\S]*?)POLES','tokens','once');
            P = regexp(block,'POLES\s+\d+([\s\S]*?)CONSTANT','tokens','once');
            C = regexp(block,'CONSTANT\s+([eE\d\+\-\.]+)','tokens','once');

            obj.z = parse_complex_lines(Z{1});
            obj.p = parse_complex_lines(P{1});
            obj.k = str2double(C{1});

            function x = parse_complex_lines(txtblock)
                L = textscan(txtblock,'%f %f');
                x = complex(L{1},L{2});
            end
        end
    end
end
