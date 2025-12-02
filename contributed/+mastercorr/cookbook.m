function cookbook
%COOKBOOK Demonstration of the mastercorr waveform correlation toolbox.
%
% This tutorial demonstrates the complete master waveform correlation
% workflow:
%
%   1. Load continuous waveform data
%   2. Preprocess (gap fill, detrend, filter)
%   3. Define a master waveform "snippet"
%   4. Scan continuous data for matches
%   5. Visualize correlation statistics
%   6. Extract matched waveforms into a correlation object
%
% The included demo dataset consists of six 10-minute waveform segments
% (1 hour total). The mastercorr.scan routine can operate on waveform
% objects from any source and of any length, although very long records
% may require chunking for computational efficiency.
%
% Author: Michael E. West
% Modernization & CI-safe refactor: Glenn Thompson, 2025
%
% See also:
%   mastercorr.scan
%   mastercorr.extract
%   mastercorr.plot_stats
%   correlation


%% ------------------------------------------------------------------------
% 0. Housekeeping
% ------------------------------------------------------------------------

disp('Starting mastercorr cookbook...');
close all;


%% ------------------------------------------------------------------------
% 1. Load Cookbook Data
% ------------------------------------------------------------------------
% In real workflows, users provide their own waveform data. For this
% tutorial, we load a bundled demonstration dataset.

try
    W = mastercorr.load_cookbook_data;
catch ME
    warning('Mastercorr demo data could not be loaded: %s', ME.message);
    disp('Skipping mastercorr cookbook.');
    return
end

disp('Loaded demo waveform dataset.');
disp(W);


%% ------------------------------------------------------------------------
% 2. Preprocess Data for Cross-Correlation
% ------------------------------------------------------------------------
% Cross-correlation performs best on:
%   • gap-free data
%   • zero-mean data
%   • band-pass filtered signals

W = fillgaps(W, 0);
W = demean(W);

filt = filterobject('b', [0.8 12], 2);   % bandpass 0.8–12 Hz
W = filtfilt(filt, W);

figure('Name','Preprocessed Waveforms','Color','w');
plot(W, 'xunit', 'date');
title('Preprocessed Continuous Data');


%% ------------------------------------------------------------------------
% 3. Create a Master Waveform "Snippet"
% ------------------------------------------------------------------------
% The snippet is a short template waveform used to scan the continuous
% data stream. Multiple snippets may be used if desired.

Wsnippet = extract(W(4), ...
    'TIME', ...
    '4/2/2009 20:32:36', ...
    '4/2/2009 20:32:40');

figure('Name','Master Snippet','Color','w');
plot(Wsnippet);
title('Master Waveform Snippet');


%% ------------------------------------------------------------------------
% 4. Add a Reference Trigger Time (Optional)
% ------------------------------------------------------------------------
% Adding a trigger improves extracted timing alignment but is optional.

Wsnippet = addfield(Wsnippet, ...
    'TRIGGER', ...
    datenum('4/2/2009 20:32:37.73'));


%% ------------------------------------------------------------------------
% 5. Scan Continuous Data for Matches
% ------------------------------------------------------------------------
% Threshold = 0.8 correlation coefficient

[W, Wxc] = mastercorr.scan(W, Wsnippet, 0.8);

disp('Correlation scan complete.');
disp(Wxc);


%% ------------------------------------------------------------------------
% 6. Plot Correlation Statistics
% ------------------------------------------------------------------------
% Visual diagnostic of correlation quality and hit distribution

figure('Name','Correlation Statistics','Color','w');
mastercorr.plot_stats(W);


%% ------------------------------------------------------------------------
% 7. Extract Match Information
% ------------------------------------------------------------------------
% Extract summary statistics on detected matches

match = mastercorr.extract(W);

disp('Match summary:');
disp(match);


%% ------------------------------------------------------------------------
% 8. Extract Matched Waveforms into a Correlation Object
% ------------------------------------------------------------------------
% Extract data windows from –2 to +6 seconds around each match

[match, C] = mastercorr.extract(W, -2, 6);

disp('Correlation object created:');
disp(C);

figure('Name','Matched Waveforms','Color','w');
plot(C);


%% ------------------------------------------------------------------------
% 9. Summary
% ------------------------------------------------------------------------
%
% This cookbook demonstrated:
%   ✓ End-to-end template matching with mastercorr
%   ✓ Gap handling, detrending, and filtering
%   ✓ Correlation scanning and thresholding
%   ✓ Statistical diagnostics of match quality
%   ✓ Extraction into a correlation object for clustering or stacking
%
% This tutorial replaces all legacy mastercorr_* scripts with a single,
% namespace-clean, CI-safe cookbook.

disp('mastercorr cookbook completed successfully.');

if exist('C','var')
    % Return final correlation object for testing
    return
else
    C = [];
end
end

