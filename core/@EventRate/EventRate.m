classdef EventRate
%EventRate Event rate and magnitude summary per time window.
%
%    EventRate is a helper class for summarizing seismic catalogs in time.
%    It was originally developed for AVO swarm tracking and has since been
%    generalized within GISMO. An EventRate object stores:
%
%      • the time coordinate of each bin (DATENUM),
%      • the number of events in each bin (counts),
%      • time–normalized rates (mean_rate, median_rate),
%      • magnitude-based metrics per bin (cum_mag, mean_mag, median_mag),
%      • simple summary statistics (min_mag, max_mag, total_counts, total_mag).
%
%    In modern GISMO workflows, EventRate objects are almost always
%    constructed via the Catalog method:
%
%        ER = C.eventrate('binsize', BINSIZE, 'stepsize', STEPSIZE)
%
%    where:
%        • C        is a Catalog object
%        • BINSIZE  is the bin size in days
%        • STEPSIZE is the step size in days (for overlapping/sliding windows)
%
%    If STEPSIZE is omitted it defaults to BINSIZE, giving non-overlapping
%    bins.
%
%    Examples (recommended usage):
%
%        % Hourly event counts
%        ER = C.eventrate('binsize', 1/24);
%
%        % 1-hour sliding window every 5 minutes
%        ER = C.eventrate('binsize', 1/24, 'stepsize', 5/1440);
%
%        % Quick visualization of multiple metrics
%        ER.plot('metric', {'counts','mean_rate','cum_mag'});
%
%        % Swarm-style plots
%        ER.helenaplot();
%        ER.pythonplot();
%
% -------------------------------------------------------------------------
%   PROPERTIES (summary)
% -------------------------------------------------------------------------
%    time                (Nx1 double) center of each time bin (DATENUM)
%
%   METRICS (per bin):
%    counts              (Nx1 double) number of events in each bin
%    mean_rate           (Nx1 double) mean event rate [events/hour]
%    median_rate         (Nx1 double) median-based rate [events/hour]
%                        (see notes below)
%    energy              (Nx1 double) total energy per bin (linear units)
%    cum_mag             (Nx1 double) cumulative magnitude of energy
%    mean_mag            (Nx1 double) mean magnitude in each bin
%    median_mag          (Nx1 double) median magnitude in each bin
%    min_mag             (Nx1 double) smallest magnitude in each bin
%    max_mag             (Nx1 double) largest magnitude in each bin
%
%   SUMMARY DATA:
%    numbins             (scalar) number of bins
%    total_counts        (scalar) total number of events (sum(counts))
%    total_mag           (scalar) total energy of all events, expressed
%                              as a single magnitude
%
%   METADATA:
%    etype               (char) event type/classification (legacy)
%    snum                (scalar) start time (DATENUM)
%    enum                (scalar) end time (DATENUM)
%    binsize             (scalar) bin size in days
%    stepsize            (scalar) step size in days
%    misc_fields         (cell)  additional metadata field names (optional)
%    misc_values         (cell)  additional metadata values (optional)
%
% -------------------------------------------------------------------------
%   NOTES ON RATES AND MAGNITUDES
% -------------------------------------------------------------------------
%   • Bins are defined in units of days. A bin of length BINSIZE therefore
%     spans BINSIZE*24 hours.
%
%   • mean_rate is defined as:
%
%         mean_rate = counts / (24 * binsize);
%
%     giving units of events/hour.
%
%   • median_rate is derived from the median time interval between events
%     in each bin (converted to hours) and then compared with the simple
%     mean_rate. The constructor enforces:
%
%         median_rate = max( mean_rate, median_rate_from_intervals );
%
%     so that the median-based rate never falls below the simple average.
%
%   • energy is stored in linear units; cum_mag, mean_mag, median_mag and
%     total_mag are computed dynamically via magnitude.eng2mag().
%
% -------------------------------------------------------------------------
%   LEGACY USAGE (NOT RECOMMENDED)
% -------------------------------------------------------------------------
%    Older AVO workflows constructed EventRate directly from a Datascope
%    database in a custom "swarms1.0" schema (Thompson & West, 2010), and
%    also used the now-deprecated 'etypes' option to build vectors of
%    EventRate objects by event type. That interface is not guaranteed to
%    work in current GISMO and is no longer maintained.
%
%    For new code, always construct EventRate via:
%
%        ER = Catalog.eventrate(...)
%
% -------------------------------------------------------------------------
%   SEE ALSO
% -------------------------------------------------------------------------
%    Catalog, Catalog/eventrate, EventRate.cookbook
%
% AUTHOR: Glenn Thompson
%
% $Date: 2014-05-06 14:52:40 -0800 (Tue, 06 May 2014) $
% $Revision: 404 $

    %% PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(GetAccess = 'public', SetAccess = 'public')
        time = [];          % (array) in datenum format
        counts = [];        % (array) number of events in each bin
        mean_rate = [];     % (array) events per hour in each bin
        median_rate = [];   % (array) median-based rate [events/hour]
        cum_mag = [];       % (array) total sum of energy per bin (mag)
        mean_mag = [];      % (array) mean magnitude per bin
        median_mag = [];    % (array) median magnitude per bin
        energy = [];        % (array) total energy per bin (linear units)
        total_counts = [];  % (scalar) sum of counts
        total_mag = [];     % (scalar) total energy of all events (mag)
        numbins = [];       % (scalar) number of bins
        min_mag = [];       % (array) smallest magnitude in each bin
        max_mag = [];       % (array) largest magnitude in each bin
        etype = '*';        % (char) legacy event-type label
        snum = 0;           % (scalar) start time (DATENUM)
        enum = now;         % (scalar) end time (DATENUM)
        binsize = 1;        % (scalar) bin size in days
        stepsize = 1;       % (scalar) step size in days
        misc_fields = {};   % (cell) additional metadata field names
        misc_values = {};   % (cell) additional metadata values
    end

    %% PUBLIC METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        %% CONSTRUCTOR
        function self = EventRate(time, counts, energy, median_energy, ...
                smallest_energy, biggest_energy, median_time_interval, ...
                total_counts, snum, enum, etypes, binsize, stepsize, numbins)
            % EventRate constructor (normally called via Catalog.eventrate).
            %
            % TIME                center of each bin (DATENUM)
            % COUNTS              events per bin
            % ENERGY              total energy per bin (linear units)
            % MEDIAN_ENERGY       median energy per bin (linear units)
            % SMALLEST_ENERGY     minimum energy per bin
            % BIGGEST_ENERGY      maximum energy per bin
            % MEDIAN_TIME_INTERVAL median inter-event time within each bin (days)
            % TOTAL_COUNTS        sum(COUNTS)
            % SNUM, ENUM          overall time range (DATENUM)
            % ETYPES              event-type label (legacy/optional)
            % BINSIZE, STEPSIZE   bin and step size (days)
            % NUMBINS             number of bins

            self.time    = time;
            self.counts  = counts;
            self.energy  = energy;
            self.total_counts = total_counts;
            self.numbins = numbins;

            % Median-based event rate [events/hour].
            self.median_rate = 1 ./ (median_time_interval * 24);
            self.median_rate(counts < 10) = 0;

            % Enforce median_rate >= simple mean_rate
            simple_mean_rate = self.counts / (24 * binsize);
            self.median_rate = max([simple_mean_rate; self.median_rate]);

            % Magnitude statistics
            self.median_mag = magnitude.eng2mag(median_energy);
            self.min_mag    = magnitude.eng2mag(smallest_energy);
            self.max_mag    = magnitude.eng2mag(biggest_energy);

            % Metadata
            self.etype    = etypes;
            self.snum     = snum;
            self.enum     = enum;
            self.binsize  = binsize;
            self.stepsize = stepsize;

            % If needed, further validation could go here, e.g.:
            % if (enum - snum) < binsize
            %     error('EventRate:InvalidBinsize', ...
            %           'binsize cannot exceed total data time range.');
            % end
        end

        %% DERIVED PROPERTIES (GETTERS) -----------------------------------
        function cum_mag = get.cum_mag(erobj)
            % Cumulative magnitude per bin
            cum_mag = magnitude.eng2mag(erobj.energy);
        end

        function mean_mag = get.mean_mag(erobj)
            % Mean magnitude per bin
            mean_mag = magnitude.eng2mag(erobj.energy ./ erobj.counts);
        end

        function mean_rate = get.mean_rate(erobj)
            % Simple mean rate [events/hour] based on counts and binsize
            mean_rate = erobj.counts / (24 * erobj.binsize);
        end

        function total_mag = get.total_mag(erobj)
            % Total magnitude corresponding to sum of all bin energies
            total_mag = magnitude.eng2mag(sum(erobj.energy));
        end
    end

    methods(Static)
        cookbook()
    end
end