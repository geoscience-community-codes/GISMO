%% EventRate Cookbook (GISMO)
% EventRate summarizes catalog activity in time using:
%   • Event counts
%   • Mean and median rates
%   • Energy and cumulative magnitude
%   • Sliding-window swarm tracking
%
% EventRate objects are always constructed via:
%
%     ER = Catalog.eventrate(...)
%
% This cookbook demonstrates:
%   1. Fully reproducible synthetic example (always runs)
%   2. Sliding window swarm tracking
%   3. Multi-metric plotting
%   4. Optional real Redoubt 2009 swarm via Antelope + TESTDATA
%
% This file is:
%   • SAFE for inexperienced users
%   • SAFE for CI (no hard dependencies)
%   • SAFE for classroom use
%   • Scientifically meaningful when Antelope is present
%
% Author: Glenn Thompson
% Refactor & modernization: 2025

close all
clc

disp('======================================================')
disp('          GISMO EventRate Cookbook')
disp('======================================================')

%% ------------------------------------------------------------------------
%% 1. SYNTHETIC CATALOG (ALWAYS AVAILABLE)
%% ------------------------------------------------------------------------
disp(' ')
disp('--- 1. Synthetic Catalog Example ---')

% Deterministic RNG for reproducibility
rng(42);

% Time span: 5 days starting Jan 1, 2020
t0 = datenum(2020,1,1,0,0,0);
span_days = 5;

% Number of events
nEvents = 200;

% Random event times and magnitudes
times = sort(t0 + span_days * rand(nEvents,1));
mags  = 1.0 + 2.5 * rand(nEvents,1);

% Build minimal Catalog
C = Catalog();
C.otime = times;
C.ontime = times;
C.offtime = times;
C.mag = mags;
C.lat = zeros(size(times));
C.lon = zeros(size(times));
C.depth = zeros(size(times));

disp(sprintf('Synthetic catalog with %d events created.', nEvents))

%% ------------------------------------------------------------------------
%% 1.1 Hourly Event Counts
%% ------------------------------------------------------------------------
disp('--- Hourly Event Counts ---')

binsize = 1/24;   % 1 hour
ER = C.eventrate('binsize', binsize);

figure;
ER.plot();
title('Synthetic Catalog: Hourly Event Counts');

%% ------------------------------------------------------------------------
%% 1.2 20-Minute Bins
%% ------------------------------------------------------------------------
disp('--- 20-minute Event Bins ---')

binsize_20 = 20/1440;
ER20 = C.eventrate('binsize', binsize_20);

figure;
ER20.plot();
title('Synthetic Catalog: 20-Minute Event Counts');

%% ------------------------------------------------------------------------
%% 1.3 Sliding 1-Hour Window / 5-Minute Step
%% ------------------------------------------------------------------------
disp('--- Sliding Window Event Rate ---')

binsize  = 1/24;      % 1 hour
stepsize = 5/1440;   % 5 minutes

ERslide = C.eventrate( ...
    'binsize',  binsize, ...
    'stepsize', stepsize);

figure;
ERslide.plot();
title('Sliding 1-Hour Window, 5-Minute Step');

%% ------------------------------------------------------------------------
%% 1.4 Multi-Metric Plotting
%% ------------------------------------------------------------------------
disp('--- Multi-Metric Visualization ---')

figure;
ER.plot('metric', {'counts','mean_rate','mean_mag','cum_mag'});
title('Multiple EventRate Metrics');

%% ------------------------------------------------------------------------
%% 1.5 Individual Metric Plots
%% ------------------------------------------------------------------------
metrics = {'counts','mean_rate','mean_mag','cum_mag'};

for k = 1:numel(metrics)
    figure;
    ER.plot('metric', metrics{k});
    title(['Metric: ', metrics{k}]);
end

%% ------------------------------------------------------------------------
%% 1.6 Helena-Style Swarm Plot
%% ------------------------------------------------------------------------
disp('--- Helena Swarm Plot ---')

figure;
ER.helenaplot();
title('Synthetic Catalog: helenaplot()');

%% ------------------------------------------------------------------------
%% 1.7 Python-Style Scientific Plot
%% ------------------------------------------------------------------------
disp('--- Python-Style Plot ---')

figure;
ER.pythonplot();
title('Synthetic Catalog: pythonplot()');

%% ------------------------------------------------------------------------
%% 2. OPTIONAL REAL DATA EXAMPLE: REDOUBT 2009 (ANTELOPE)
%% ------------------------------------------------------------------------
disp(' ')
disp('--- Optional Redoubt 2009 Swarm Example ---')

haveAntelope = false;

try
    if exist('admin.antelope_exists','file') == 2 && admin.antelope_exists()
        haveAntelope = true;
    end
catch
    haveAntelope = false;
end

if haveAntelope
    try
        % Resolve TESTDATA directory
        gismopath = fileparts(which('startup_GISMO'));
        TESTDATA  = fullfile(gismopath,'testdata');

        if ~exist(TESTDATA,'dir')
            warning('EventRate:RedoubtDemo', ...
                'TESTDATA not found. Skipping Redoubt example.');
        else
            dbpath = fullfile(TESTDATA,'css3.0','dbredoubt200903');
            fprintf('Loading Redoubt database:\n  %s\n',dbpath);

            % Redoubt summit coordinates
            redoubtLat = 60.4853;
            redoubtLon = -152.7431;
            maxRkm = 20;

            if exist('km2deg','file')
                maxRdeg = km2deg(maxRkm);
            else
                maxRdeg = maxRkm / 111.19;
            end

            % Retrieve events near Redoubt
            redoubt_events = Catalog.retrieve( ...
                'antelope', ...
                'dbpath', dbpath, ...
                'radialcoordinates', [redoubtLat redoubtLon maxRdeg]);

            if isempty(redoubt_events) || isempty(redoubt_events.otime)
                warning('EventRate:RedoubtDemo', ...
                    'No events returned from Redoubt database.');
            else
                disp(sprintf('Loaded %d Redoubt events.', ...
                    numel(redoubt_events.otime)))

                ERred = redoubt_events.eventrate('binsize',1/24);

                figure;
                ERred.plot('metric','counts');
                title('Redoubt 2009: Hourly Event Counts');

                figure;
                ERred.helenaplot();
                title('Redoubt 2009: helenaplot()');

                figure;
                ERred.pythonplot();
                title('Redoubt 2009: pythonplot()');

                disp('Redoubt 2009 EventRate demo completed successfully.')
            end
        end
    catch ME
        warning('EventRate:RedoubtDemo', ME.message);
    end
else
    disp('Antelope toolbox not available. Skipping Redoubt example.');
end

%% ------------------------------------------------------------------------
%% 3. NOTES
%% ------------------------------------------------------------------------
% • EventRate windows use DAYS as the fundamental unit.
% • mean_rate is in EVENTS PER HOUR.
% • median_rate is enforced >= mean_rate.
% • Magnitudes are derived dynamically from summed energy.
%
% For related cookbooks, see:
%   • Catalog.cookbook
%   • Detection.cookbook
%   • Correlation.cookbook
%
% End of EventRate Cookbook
