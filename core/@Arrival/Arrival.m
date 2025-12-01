classdef Arrival
%ARRIVAL Phase-arrival metadata container (GISMO refactor 2025)
%
% Single-table backend
% Antelope/CSS compatible
% Legacy-safe constructor

    properties (Dependent)
        channelinfo
        time
        iphase
        amp
        per
        signal2noise
    end

    properties
        waveforms
    end

    properties (Hidden)
        table
        traveltime
        deltim
        delta
        otime
        orid
        evid
        timeres
        depth
        arid
        seaz
    end

    %% ===========================
    %  CONSTRUCTOR
    % ===========================
    methods
        function obj = Arrival(sta, chan, time, iphase, varargin)

            if nargin == 0
                obj.table = table();
                obj.waveforms = [];
                return
            end

            p = inputParser;
            p.addRequired('sta', @iscell);
            p.addRequired('chan', @iscell);
            p.addRequired('time', @isnumeric);
            p.addRequired('iphase', @iscell);

            p.addParameter('amp', NaN, @isnumeric);
            p.addParameter('per', NaN, @isnumeric);
            p.addParameter('signal2noise', NaN, @isnumeric);
            p.addParameter('arid', [], @isnumeric);
            p.addParameter('seaz', [], @isnumeric);
            p.addParameter('deltim', [], @isnumeric);
            p.addParameter('delta', [], @isnumeric);
            p.addParameter('otime', [], @isnumeric);
            p.addParameter('orid', [], @isnumeric);
            p.addParameter('evid', [], @isnumeric);
            p.addParameter('timeres', [], @isnumeric);
            p.addParameter('depth', [], @isnumeric);

            p.parse(sta, chan, time, iphase, varargin{:});
            r = p.Results;

            ctag = ChannelTag.array('', r.sta, '', r.chan)';
            chanstr = ctag.string();

            obj.table = table( ...
                r.time(:), ...
                datestr(r.time(:),26), ...
                datestr(r.time(:),'HH:MM'), ...
                datestr(r.time(:),'SS.FFF'), ...
                chanstr(:), ...
                r.iphase(:), ...
                r.amp(:), ...
                r.per(:), ...
                r.signal2noise(:), ...
                'VariableNames', ...
                {'time','date','hour_minute','second','channelinfo','iphase','amp','per','signal2noise'} );

            obj.table = sortrows(obj.table,'time');
            obj.waveforms = [];

            obj.arid     = r.arid;
            obj.seaz     = r.seaz;
            obj.deltim   = r.deltim;
            obj.delta    = r.delta;
            obj.otime    = r.otime;
            obj.orid     = r.orid;
            obj.evid     = r.evid;
            obj.timeres  = r.timeres;
            obj.depth    = r.depth;

            fprintf('\nGot %d arrivals\n', height(obj.table));
        end


        %% ===========================
        %  DEPENDENT ACCESSORS
        % ===========================
    
        function v = get.time(obj)
            v = Arrival.safeGet(obj,'time');
        end

        function v = get.channelinfo(obj)
            v = Arrival.safeGet(obj,'channelinfo');
        end

        function v = get.iphase(obj)
            v = Arrival.safeGet(obj,'iphase');
        end

        function v = get.amp(obj)
            v = Arrival.safeGet(obj,'amp');
        end

        function v = get.per(obj)
            v = Arrival.safeGet(obj,'per');
        end

        function v = get.signal2noise(obj)
            v = Arrival.safeGet(obj,'signal2noise');
        end

        function obj = set.amp(obj,v)
            obj.table.amp = v;
        end

        function obj = set.signal2noise(obj,v)
            obj.table.signal2noise = v;
        end

        %% ===========================
        %  CORE UTILITY METHODS
        % ===========================
    
        summary(obj, showall)
        self2 = subset(self, columnname, findval)
        self  = setminmax(self, w, maxTimeDiff, pretrig, posttrig)
        self  = addmetrics(self, maxTimeDiff)
        self  = addwaveforms(self, datasourceobj, pretrigsecs, posttrigsecs)
        [catalogobj,self] = associate(self, maxTimeDiff, sites, source)
        write(self, format, path, varargin)
    end

    %% ===========================
    %  STATIC METHODS
    % ===========================
    methods (Static)
        self = retrieve(dataformat, varargin)
        self = readphafile(phafilename)
        self = read_antelope(dbname, subset_expr)

        function v = safeGet(obj, fieldname)

            % Gracefully handle empty Arrival objects
            if isempty(obj) || isempty(obj.table) || width(obj.table) == 0
                v = [];
                return
            end

            vars = obj.table.Properties.VariableNames;

            if ismember(fieldname, vars)
                v = obj.table.(fieldname);
            else
                % Maintain backward compatibility but fail loudly if used incorrectly
                error('Arrival:get:MissingColumn', ...
                    'Arrival.table has no ''%s'' column', fieldname);
            end
        end

    end
end
