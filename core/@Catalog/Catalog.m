%CATALOG Container for seismic event metadata (Legacy GISMO)
% A Catalog object stores event-level metadata and supports
% retrieval, plotting, rate analysis, and export.
%
% This version is:
%   • Legacy-safe
%   • CI-safe
%   • Vector-backend (no tables)
%   • Prototype-free
%   • Cookbook separated into @Catalog/cookbook.m

classdef Catalog

    % =====================================================================
    % CORE DATA PROPERTIES (LEGACY VECTOR BACKEND)
    % =====================================================================
    properties
        otime = [];   % origin time (datenum)
        lon   = [];
        lat   = [];
        depth = [];
        mag   = [];
        magtype = {};
        etype   = {};
        ontime  = [];
        offtime = [];
        request = struct();

        detections = {};   % optional Detection objects per event
        arrivals   = {};   % optional Arrival objects per event
        waveforms  = {};   % cell array of waveform vectors per event
    end

    % =====================================================================
    % DEPENDENT METRICS
    % =====================================================================
    properties (Dependent)
        numberOfEvents
        duration
        cum_mag
        max_mag
        peakrate
    end

    % =====================================================================
    % CONSTRUCTOR
    % =====================================================================
    methods

        function obj = Catalog(varargin)
            % Catalog constructor
            %
            % Usage:
            %   cobj = Catalog()
            %   cobj = Catalog(otime, lon, lat, depth, mag, magtype, etype)
            %   cobj = Catalog(..., 'ontime', ontime, 'offtime', offtime)

            if nargin == 0
                return
            end

            % --- Parse inputs (legacy positional + name-value) ---
            p = inputParser;
            p.addOptional('otime', [], @isnumeric);
            p.addOptional('lon',   [], @isnumeric);
            p.addOptional('lat',   [], @isnumeric);
            p.addOptional('depth', [], @isnumeric);
            p.addOptional('mag',   [], @isnumeric);
            p.addOptional('magtype', {}, @iscell);
            p.addOptional('etype',   {}, @iscell);
            p.addParameter('request', struct(), @isstruct);
            p.addParameter('ontime', [], @isnumeric);
            p.addParameter('offtime', [], @isnumeric);

            p.parse(varargin{:});
            r = p.Results;

            % --- If only trigger times exist, use as origin times ---
            if isempty(r.otime) && ~isempty(r.ontime)
                r.otime = r.ontime;
            end

            % --- Enforce column vectors ---
            r.otime = r.otime(:);
            n = numel(r.otime);

            % --- Fill missing numeric fields with NaNs ---
            if isempty(r.lon),   r.lon   = NaN(n,1); else, r.lon   = r.lon(:);   end
            if isempty(r.lat),   r.lat   = NaN(n,1); else, r.lat   = r.lat(:);   end
            if isempty(r.depth),r.depth = NaN(n,1); else, r.depth = r.depth(:); end
            if isempty(r.mag),  r.mag   = NaN(n,1); else, r.mag   = r.mag(:);   end
            if isempty(r.ontime),  r.ontime  = NaN(n,1); else, r.ontime  = r.ontime(:);  end
            if isempty(r.offtime), r.offtime = NaN(n,1); else, r.offtime = r.offtime(:); end

            % --- Fill missing cell fields ---
            if isempty(r.magtype)
                r.magtype = repmat({'u'}, n, 1);
            else
                r.magtype = r.magtype(:);
            end

            if isempty(r.etype)
                r.etype = repmat({'u'}, n, 1);
            else
                r.etype = r.etype(:);
            end

            % --- Hard length validation (critical for legacy safety) ---
            Catalog.assertLength(n, r.lon,     'lon');
            Catalog.assertLength(n, r.lat,     'lat');
            Catalog.assertLength(n, r.depth,   'depth');
            Catalog.assertLength(n, r.mag,     'mag');
            Catalog.assertLength(n, r.magtype,'magtype');
            Catalog.assertLength(n, r.etype,  'etype');
            Catalog.assertLength(n, r.ontime, 'ontime');
            Catalog.assertLength(n, r.offtime,'offtime');

            % --- Assign ---
            obj.otime   = r.otime;
            obj.lon     = r.lon;
            obj.lat     = r.lat;
            obj.depth   = r.depth;
            obj.mag     = r.mag;
            obj.magtype = r.magtype;
            obj.etype   = r.etype;
            obj.ontime  = r.ontime;
            obj.offtime = r.offtime;
            obj.request = r.request;
        end

        % =================================================================
        % DEPENDENT ACCESSORS
        % =================================================================
        function val = get.duration(obj)
            val = 86400 * (obj.offtime - obj.ontime);
        end

        function val = get.numberOfEvents(obj)
            val = max([numel(obj.otime), numel(obj.ontime)]);
        end

        function val = get.cum_mag(obj)
            val = magnitude.eng2mag( ...
                sum(magnitude.mag2eng(obj.mag)) );
        end

        function mm = get.max_mag(obj)
            t = obj.gettimerange();
            days = t(2) - t(1);
            [mm, mmi] = max(obj.mag);
            mmpercent = 100 * (obj.otime(mmi) - t(1)) / days;
            mm = mm + mmpercent * 1i;
        end

        function pr = get.peakrate(obj)
            t = obj.gettimerange();
            days = t(2) - t(1);
            binsize = days / 100;
            erobj = obj.eventrate('binsize', binsize);
            [pr, pri] = max(erobj.counts);
            pr = pr + ...
                100 * (erobj.time(pri) - erobj.snum) / ...
                (erobj.enum - erobj.snum) * 1i;
        end

        % =================================================================
        % CORE UTILITY METHODS
        % =================================================================
        function t = gettimerange(obj)
            snum = nanmin([obj.otime; obj.ontime]);
            enum = nanmax([obj.otime; obj.offtime]);
            t = [snum enum];
        end

        function cobj3 = add(cobj1, cobj2)
            % Concatenate two Catalogs (legacy behavior)
            cobj3 = cobj1;
            cobj3.otime   = [cobj1.otime;   cobj2.otime];
            cobj3.lon     = [cobj1.lon;     cobj2.lon];
            cobj3.lat     = [cobj1.lat;     cobj2.lat];
            cobj3.depth   = [cobj1.depth;   cobj2.depth];
            cobj3.mag     = [cobj1.mag;     cobj2.mag];
            cobj3.magtype = [cobj1.magtype; cobj2.magtype];
            cobj3.etype   = [cobj1.etype;   cobj2.etype];
            cobj3.ontime  = [cobj1.ontime;  cobj2.ontime];
            cobj3.offtime = [cobj1.offtime; cobj2.offtime];
            cobj3.arrivals  = [cobj1.arrivals;  cobj2.arrivals];
            cobj3.waveforms = [cobj1.waveforms; cobj2.waveforms];
        end

        function t = table(cobj)
            evid = (1:numel(cobj.otime))';
            epochtime = datenum2epoch(cobj.otime);
            timeutc = cellstr(datestr(cobj.otime, 'yyyy/mm/dd HH:MM:SS'));

            t = table( ...
                evid, ...
                cobj.mag, ...
                epochtime, ...
                timeutc, ...
                cobj.lat, ...
                cobj.lon, ...
                cobj.depth, ...
                'VariableNames', ...
                {'Evid','Magnitude','Epoch_UTC','Time_UTC','Lat','Lon','Depth_Km'} );
        end

    end % methods

    % =====================================================================
    % HIDDEN SUPPORT METHODS
    % =====================================================================
    methods (Hidden=true)
        region = get_region(catalogObject, nsigma)
        symsize = get_symsize(catalogObject)
    end

    % =====================================================================
    % STATIC METHODS
    % =====================================================================
    methods (Static)
        self = retrieve(dataformat, varargin)

        function assertLength(n, v, name)
            if numel(v) ~= n
                error('Catalog:LengthMismatch', ...
                    'Length of %s (%d) does not match otime (%d).', ...
                    name, numel(v), n);
            end
        end
    end

end

