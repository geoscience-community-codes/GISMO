%% GISMO Training 02: Antelope Arrivals → Catalog → Event Waveforms
%
% This training script demonstrates a full observatory-style workflow:
%
%   1. Load an Antelope CSS3.0 database
%   2. Retrieve arrivals from the arrival table
%   3. Associate arrivals into seismic events
%   4. Load waveform data for each event
%   5. Plot one figure per event
%   6. Compute and plot event rates
%
% This script requires:
%   • Antelope to be installed
%   • GISMO built with Antelope support
%   • An Antelope database path set via:
%
%       export GISMO_ANTELOPE_DB=/path/to/db
%
% If Antelope is not available, the script will exit safely.
%
% ---------------------------------------------------------------

clc;
close all;
warning off; %#ok<WNOFF>

%% --- Check for Antelope support ----------------------------------------
if ~exist('dbopen','file')
    warning(['Antelope functions not found on your system. ', ...
             'Skipping Antelope training script.']);
    return;
end

%% --- Resolve Antelope database path -----------------------------------
dbpath = getenv('GISMO_ANTELOPE_DB');
if isempty(dbpath)
    warning(['GISMO_ANTELOPE_DB environment variable is not set.\n', ...
             'Set it to the root of your Antelope database and re-run.\n', ...
             'Example:\n  export GISMO_ANTELOPE_DB=/raid/data/sakurajima/db']);
    return;
end

fprintf('Using Antelope database: %s\n', dbpath);

%% 1. Define Data Sources and Channel Selection -------------------------

% Antelope datasource
ds = datasource('antelope', dbpath);

% Channel selection using ChannelTag (modern GISMO style)
% Wildcards allowed
ctag(1) = ChannelTag('JP.SAKA.-.BD*');
ctag(2) = ChannelTag('JP.SAKB.-.BD*');
ctag(3) = ChannelTag('JP.SAKA.-.HHZ');
ctag(4) = ChannelTag('JP.SAKB.-.HHZ');

%% 2. Load Arrivals from Antelope Arrival Table --------------------------

% Time window for retrieval (example)
startTime = '2015/05/28 18:00:00';
endTime   = '2015/05/29 02:00:00';

subset_expr = sprintf( ...
    'time > "%s" && time < "%s"', startTime, endTime);

fprintf('Retrieving arrivals between %s and %s\n', startTime, endTime);

arrivalobj = Arrival.retrieve( ...
    'antelope', dbpath, subset_expr);

fprintf('Loaded %d arrivals\n', numel(arrivalobj.time));

%% 3. Associate Arrivals into Seismic Events ----------------------------

% Group arrivals into events based on time proximity (seconds)
association_window = 1.0;  % seconds

catalogobj = arrivalobj.associate(association_window);

fprintf('Associated into %d seismic events\n', ...
        catalogobj.numberOfEvents);

%% 4. Load Event Waveforms ----------------------------------------------

% Pre- and post-trigger padding (seconds)
pretrigger  = 30;
posttrigger = 30;

catalogobj = catalogobj.addwaveforms( ...
    ds, ctag, pretrigger, posttrigger);

fprintf('Waveforms added to all catalog events\n');

%% 5. Plot Waveforms: One Figure per Event -------------------------------

output_dir = 'event_figures';
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end

for eventnum = 1:catalogobj.numberOfEvents

    w = [catalogobj.waveforms{eventnum}];

    if isempty(w)
        fprintf('Event %d: no waveforms\n', eventnum);
        continue;
    end

    figure('Visible','off');
    plot_panels(w(:), true);

    title(sprintf('Event %d', eventnum));

    figfile = fullfile(output_dir, ...
              sprintf('event_%03d.png', eventnum));

    print('-dpng', figfile);
    close;

end

fprintf('Saved %d event plots in: %s\n', ...
        catalogobj.numberOfEvents, output_dir);

%% 6. Event Rate Analysis -----------------------------------------------

% Required for proper time normalization
catalogobj.request.startTime = datenum(startTime);
catalogobj.request.endTime   = datenum(endTime);

% Compute event rate (default = per hour)
erobj = catalogobj.eventrate();

figure;
erobj.plot();
title('Event Rate from Antelope-Associated Catalog');

%% 7. Optional: Export Catalog for Downstream Analysis ------------------

save('antelope_training_catalog.mat','catalogobj');
fprintf('Catalog saved to antelope_training_catalog.mat\n');

%% 8. Next Steps (for Students / Users) ---------------------------------
%
% Suggested extensions:
%
%   • Measure amplitudes using:
%         catalogobj = catalogobj.compute_metrics(...)
%
%   • Train ML classifiers using extracted features.
%
%   • Replace arrival table with detections from:
%         dbdetect → Detection.retrieve
%
%   • Perform template matching with:
%         mastercorr.scan()
%
% ---------------------------------------------------------------
disp('GISMO Training 02 complete.');