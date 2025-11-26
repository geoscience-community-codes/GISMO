%% EventRate Cookbook
% The EventRate class is designed to summarize catalog activity in time,
% providing:
%
%   * Number of events per unit time ("counts")
%   * Event rate (counts per day, hour, etc.)
%   * Cumulative magnitude per time window (cum_mag)
%   * Mean and median magnitude per time window (mean_mag, median_mag)
%   * Derived "energy" metrics based on magnitude
%
% EventRate objects are derived from Catalog objects. This cookbook shows:
%
%   1. How to build a synthetic Catalog and compute EventRate from it
%   2. How to work with different bin sizes and sliding windows
%   3. How to visualize different metrics with plot(), helenaplot(),
%      and pythonplot()
%   4. (Optionally) How to compute EventRate from a real Redoubt 2009
%      catalog if Antelope + GISMO testdata are available.
%
% This cookbook is written to be robust:
%   * It does NOT require Antelope or TESTDATA to run.
%   * All real-data examples are optional and wrapped in try/catch.

%% 1. Synthetic Catalog Example (Always Available)
% To make this cookbook self-contained, we first construct a synthetic
% Catalog with:
%
%   * Event times spanning 5 days
%   * Magnitudes that increase slightly over time
%   * Dummy lat/lon/depth fields
%
% This portion of the cookbook will always run, and is suitable for
% automated tests and basic demos.

disp('--- EventRate Cookbook: Synthetic Catalog Example ---');

% Define a synthetic 5-day interval starting at 2020-01-01
t0 = datenum(2020,1,1,0,0,0);

% Create 200 synthetic events over 5 days
nEvents = 200;
times   = t0 + sort(rand(nEvents,1) * 5);      % random times over 5 days
mags    = 1.0 + 2.5 * rand(nEvents,1);         % magnitudes in [1.0, 3.5]

% Build a minimal Catalog object that EventRate can consume.
% EventRate uses trigger times (trig) and magnitudes (mag). The other
% fields are included for completeness but not required.
syntheticCatalog      = Catalog();
syntheticCatalog.trig = times;
syntheticCatalog.mag  = mags;
syntheticCatalog.lat  = zeros(size(times));
syntheticCatalog.lon  = zeros(size(times));
syntheticCatalog.depth= zeros(size(times));

%% 1.1 Hourly Event Counts
% We now compute an EventRate object with 1-hour bins (1/24 of a day).
% This corresponds conceptually to "events per hour".

binsize = 1/24;   % 1 hour, in days

eventrateObject = syntheticCatalog.eventrate('binsize', binsize);

figure;
eventrateObject.plot();  % same as plot(eventrateObject)
title('Synthetic Catalog: Event counts per hour');

%% 1.2 Smaller Time Bins (20 minutes)
% We can refine the temporal resolution by using smaller bins.
% Here we use 20-minute bins, which is 20/1440 days.

binsize_20min = 20/1440;   % 20 minutes

eventrate_20 = syntheticCatalog.eventrate('binsize', binsize_20min);

figure;
plot(eventrate_20);
title('Synthetic Catalog: Event counts per 20 minutes');

%% 1.3 Overlapping (Sliding Window) Event Rates
% EventRate can also be computed in overlapping windows by specifying a
% 'stepsize'. For example, 1-hour windows computed every 5 minutes:
%
%   binsize  = 1 hour
%   stepsize = 5 minutes
%
% This is useful for tracking the evolution of swarm activity or changing
% rates in finer detail without losing smoothing.

binsize_1hr   = 1/24;     % 1 hour
stepsize_5min = 5/1440;   % 5 minutes

eventrate_sliding = syntheticCatalog.eventrate( ...
    'binsize',  binsize_1hr, ...
    'stepsize', stepsize_5min);

figure;
eventrate_sliding.plot();
title('Synthetic Catalog: Sliding 1-hr window every 5 minutes');

%% 1.4 Available EventRate Metrics
% An EventRate object typically includes the following numeric sequences:
%
%   * counts      : number of events in each bin
%   * mean_rate   : counts divided by binsize (events/day)
%   * median_rate : median rate in the window
%   * cum_mag     : sum of magnitudes in each bin
%   * mean_mag    : mean magnitude in each bin
%   * median_mag  : median magnitude in each bin
%   * energy      : (optional) derived energy metric from cum_mag/mag
%
% Internally, these are stored as properties of the EventRate object and
% can be accessed directly, e.g.:
%
%   eventrateObject.counts
%   eventrateObject.mean_rate
%   eventrateObject.cum_mag
%
% or visualized using the 'metric' option of plot().

disp('Available metrics fields include: counts, mean_rate, median_rate, cum_mag, mean_mag, median_mag, energy');

%% 1.5 Plot Multiple Metrics Together
% The plot() method can display several metrics on the same axes by
% passing a cell array of metric names.

figure;
eventrateObject.plot('metric', ...
    {'counts'; 'mean_rate'; 'mean_mag'; 'cum_mag'});
title('Synthetic Catalog: Multiple EventRate metrics');

%% 1.6 Plot Metrics in Separate Windows
% We can also make one plot per metric, for example:

figure;
eventrateObject.plot('metric', 'counts');
title('Synthetic Catalog: Counts per bin');

figure;
eventrateObject.plot('metric', 'mean_rate');
title('Synthetic Catalog: Mean event rate');

figure;
eventrateObject.plot('metric', 'mean_mag');
title('Synthetic Catalog: Mean magnitude per bin');

figure;
eventrateObject.plot('metric', 'cum_mag');
title('Synthetic Catalog: Cumulative magnitude per bin');

%% 1.7 Helena-Style Swarm Plot
% HELENAPLOT provides a compact swarm-plot style visualization, inspired
% by volcano monitoring applications (e.g., Redoubt 2009).

figure;
eventrateObject.helenaplot();
title('Synthetic Catalog: helenaplot()');

%% 1.8 Python-Style Scientific Plot
% PYTHONPLOT offers an alternative, more "modern" scientific style plot.

figure;
eventrateObject.pythonplot();
title('Synthetic Catalog: pythonplot()');

%% 2. Optional Real-Data Example: Redoubt 2009 (Antelope + TESTDATA)
% The original EventRate cookbook was based on the Redoubt 2009 catalog
% from the Alaska Volcano Observatory (AVO), stored in an Antelope/CSS3.0
% database distributed with the GISMO test dataset.
%
% In keeping with that heritage, this section attempts to:
%
%   * locate the GISMO TESTDATA directory,
%   * open the avodb200903 CSS3.0 database via Antelope,
%   * extract events within 20 km of Redoubt,
%   * compute EventRate and make a few plots.
%
% This section is completely optional and wrapped in try/catch so that
% the cookbook will not crash if Antelope, TESTDATA, or the Mapping
% Toolbox are not available.

disp('--- EventRate Cookbook: Optional Redoubt 2009 Example ---');

haveAntelope = false;
try
    % Check for Antelope toolbox (admin.antelope_exists is a GISMO helper)
    if exist('admin.antelope_exists','file') == 2 && admin.antelope_exists()
        haveAntelope = true;
    end
catch
    haveAntelope = false;
end

if haveAntelope
    try
        % Locate TESTDATA under GISMO, if present
        gismopath = fileparts(which('startup_GISMO'));
        TESTDATA  = fullfile(gismopath, 'testdata');

        if ~exist(TESTDATA, 'dir')
            warning('EventRate:RedoubtDemo', ...
                'TESTDATA not found at %s. Skipping Redoubt example.', TESTDATA);
        else
            % Path to official AVO catalog demo segment
            dbpath = fullfile(TESTDATA, 'css3.0', 'avodb200903');

            % Redoubt coordinates
            redoubtLon = -152.7431;
            redoubtLat = 60.4853;
            maxRkm     = 20.0;

            % km2deg may be from Mapping toolbox; guard it
            if exist('km2deg','file')
                maxRdeg = km2deg(maxRkm);
            else
                % Fallback: approximate conversion
                maxRdeg = maxRkm / 111.19;   % ~111.19 km per degree
            end

            % Retrieve events within 20 km of Redoubt from CSS3.0 database
            redoubt_events = Catalog.retrieve( ...
                'antelope', ...
                'dbpath', dbpath, ...
                'radialcoordinates', [redoubtLat redoubtLon maxRdeg]);

            if isempty(redoubt_events)
                warning('EventRate:RedoubtDemo', ...
                    'No events returned from Redoubt demo database.');
            else
                % Compute hourly EventRate
                er_red = redoubt_events.eventrate('binsize', 1/24);

                figure;
                er_red.plot('metric','counts');
                title('Redoubt 2009: Event counts per hour (within 20 km)');

                % Example helenaplot for the Redoubt swarm
                figure;
                er_red.helenaplot();
                title('Redoubt 2009: helenaplot()');

                % Example pythonplot
                figure;
                er_red.pythonplot();
                title('Redoubt 2009: pythonplot()');

                disp('Redoubt 2009 EventRate example completed successfully.');
            end
        end

    catch ME
        warning('EventRate:RedoubtDemo', ...
            'Redoubt example failed: %s', ME.message);
    end
else
    disp('Antelope toolbox not available. Skipping Redoubt 2009 example.');
end

%% 3. Notes and References
% The EventRate metrics, binning strategy, and swarm visualization styles
% illustrated here are consistent with approaches used operationally at
% volcano observatories (e.g., for tracking pre-eruptive swarms and
% aftershock decay sequences).
%
% For more examples of Catalog usage (including b-value, magnitude of
% completeness, and spatial plotting), see:
%
%   Catalog.cookbook
%
% End of EventRate Cookbook.