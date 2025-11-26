classdef Response
    % RESPONSE  Instrument response object (modern GISMO OOP wrapper)
    %
    % This class encapsulates an instrument response formerly represented
    % as a loose structure returned by:
    %   - response_get_from_db
    %   - response_get_from_polezero
    %
    % Core numerical operations are still performed by:
    %   - response_apply
    %   - response_plot
    %
    % The class provides:
    %   • Clean namespace
    %   • Validation at construction
    %   • Unified API for load / apply / plot
    %   • Backward compatibility with legacy struct-based code
    %
    % Glenn Thompson & Mike West response system (modernized)
    %

    %% -------------------- CORE RESPONSE PROPERTIES --------------------
    properties
        type            % 'polezero', 'fap', 'evalresp', etc.

        zeros           % complex zeros
        poles           % complex poles
        gain            % dimensionless gain
        sensitivity     % overall sensitivity
        scalefreq       % scale frequency (Hz)

        units_in        % e.g., 'M', 'M/S', 'COUNTS'
        units_out       % e.g., 'COUNTS', 'M/S', 'PA'

        samplerate      % Hz

        network
        station
        location
        channel

        starttime       % datenum
        endtime         % datenum

        metadata        % struct for provenance / DB info
    end

    %% -------------------- CONSTRUCTOR --------------------
    methods
        function obj = Response(varargin)
            % RESPONSE constructor
            %
            % Supported inputs:
            %   Response()                     → empty shell
            %   Response(struct)               → from legacy response struct
            %   Response('polezero', file)    → from pole-zero file
            %   Response('db', ds, tag, time) → from database

            if nargin == 0
                obj.metadata = struct();
                return
            end

            % --- Construct from legacy struct ---
            if nargin == 1 && isstruct(varargin{1})
                obj = obj.fromStruct(varargin{1});
                return
            end

            % --- Tag-value constructor ---
            if ischar(varargin{1}) || isstring(varargin{1})
                mode = lower(string(varargin{1}));

                switch mode
                    case "polezero"
                        pzfile = varargin{2};
                        S = response_get_from_polezero(pzfile);
                        obj = obj.fromStruct(S);

                    case "db"
                        ds   = varargin{2};
                        tag  = varargin{3};
                        time = varargin{4};
                        S = response_get_from_db(ds, tag, time);
                        obj = obj.fromStruct(S);

                    otherwise
                        error("Response:UnknownConstructorMode", ...
                            "Unknown constructor mode: %s", mode);
                end
            end
        end
    end

    %% -------------------- CORE USER METHODS --------------------
    methods
        function y = apply(obj, x, varargin)
            % APPLY  Apply instrument correction
            %
            % y = obj.apply(x)
            % y = obj.apply(x, 'causal', true)
            %
            if isempty(obj.samplerate)
                error("Response:MissingSampleRate", ...
                    "samplerate must be defined before apply().");
            end

            S = obj.toStruct();
            y = response_apply(x, obj.samplerate, S, varargin{:});
        end

        function plot(obj, varargin)
            % PLOT  Plot instrument response
            %
            % obj.plot()
            %
            if isempty(obj.samplerate)
                error("Response:MissingSampleRate", ...
                    "samplerate must be defined before plot().");
            end

            S = obj.toStruct();
            response_plot(S, obj.samplerate, varargin{:});
        end

        function disp(obj)
            fprintf("Response object:\n");
            fprintf("  %s.%s.%s.%s\n", ...
                string(obj.network), ...
                string(obj.station), ...
                string(obj.location), ...
                string(obj.channel));

            fprintf("  Type: %s\n", string(obj.type));
            fprintf("  In → Out: %s → %s\n", ...
                string(obj.units_in), string(obj.units_out));

            if ~isempty(obj.starttime)
                fprintf("  Valid: %s to %s\n", ...
                    datestr(obj.starttime), ...
                    datestr(obj.endtime));
            end
        end
    end

    %% -------------------- CONVERSION METHODS --------------------
    methods
        function S = toStruct(obj)
            % Convert class to legacy struct used by backend functions

            S = struct();

            S.type        = obj.type;
            S.zeros       = obj.zeros;
            S.poles       = obj.poles;
            S.gain        = obj.gain;
            S.sensitivity = obj.sensitivity;
            S.scalefreq   = obj.scalefreq;

            S.units_in  = obj.units_in;
            S.units_out = obj.units_out;

            S.samplerate = obj.samplerate;

            S.network  = obj.network;
            S.station  = obj.station;
            S.location = obj.location;
            S.channel  = obj.channel;

            S.starttime = obj.starttime;
            S.endtime   = obj.endtime;

            S.metadata = obj.metadata;
        end

        function obj = fromStruct(obj, S)
            % Populate class from legacy response struct

            fields = fieldnames(S);
            for k = 1:numel(fields)
                f = fields{k};
                if isprop(obj, f)
                    obj.(f) = S.(f);
                end
            end

            if ~isfield(S, 'metadata')
                obj.metadata = struct();
            end
        end
    end

    %% -------------------- STATIC FACTORIES --------------------
    methods (Static)
        function R = fromPoleZero(pzfile)
            S = response_get_from_polezero(pzfile);
            R = Response(S);
        end

        function R = fromDatabase(ds, tag, time)
            S = response_get_from_db(ds, tag, time);
            R = Response(S);
        end
    end
end