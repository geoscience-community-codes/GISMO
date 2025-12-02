%% correlation Cookbook (GISMO)
% Human-facing tutorial for correlation workflows.
% NOT for CI. NOT for automated testing.
%
% Uses either:
%   • External TESTDATA/matfiles/correlation.mat (if present)
%   • Built-in DEMO dataset (fallback)
%
% The correlation object provides tools for manipulating and analyzing large
% collections of similar waveform snippets including:
%
%   • Cross-correlation
%   • Time alignment
%   • Clustering
%   • Stacking
%   • Interferograms
%   • Occurrence and overlay plots
%
% Author: Michael West (original)
% Refactor: Glenn Thompson 2025

close all
clc

%% ------------------------------------------------------------------------
%% Resolve data source
%% ------------------------------------------------------------------------
useTestData = false;
c = [];

try
    admin.is_testdata_setup(false);
    global TESTDATA
    matfile = fullfile(TESTDATA,'matfiles','correlation.mat');

    if exist(matfile,'file')
        load(matfile,'c');
        useTestData = true;
        fprintf('\nLoaded correlation object from TESTDATA:\n  %s\n', matfile);
    end
catch ME
    warning('TESTDATA lookup failed: %s', ME.message);
end

if ~useTestData
    fprintf('\nLoading built-in correlation DEMO dataset.\n');
    c = correlation('DEMO');
end

%% ------------------------------------------------------------------------
%% Inspect object
%% ------------------------------------------------------------------------

disp('Available correlation methods:')
methods(c)

disp('Object summary:')
display(c)

%% ------------------------------------------------------------------------
%% Plot raw data (wiggle + shaded)
%% ------------------------------------------------------------------------

figure('Name','Raw wiggle plot');
plot(c,'wig');

figure('Name','Raw shaded plot');
plot(c,'sha');

%% ------------------------------------------------------------------------
%% Crop, taper, and filter
%% ------------------------------------------------------------------------
% IMPORTANT: Filtering before correlation is essential to prevent
% long-period roll from biasing correlation results.

fprintf('\n--- Preprocessing traces ---\n');
c = crop(c,-4,12);
c = taper(c);
c = butter(c,[0.5 10]);

figure('Name','Preprocessed traces');
plot(c,'sha');

%% ------------------------------------------------------------------------
%% Cross-correlation
%% ------------------------------------------------------------------------

fprintf('\n--- Cross-correlating traces ---\n');
c = xcorr(c,[0 3.5]);

%% ------------------------------------------------------------------------
%% Similarity (correlation) matrix
%% ------------------------------------------------------------------------

fprintf('\n--- Similarity matrix ---\n');
c = sort(c);

figure('Name','Correlation matrix');
plot(c,'corr');

corr_matrix = get(c,'CORR');
disp(corr_matrix(1:5,1:5))

%% ------------------------------------------------------------------------
%% Lag matrix
%% ------------------------------------------------------------------------

figure('Name','Lag matrix');
plot(c,'lag');

lag_matrix = get(c,'LAG');
disp(lag_matrix(1:5,1:5))

%% ------------------------------------------------------------------------
%% Realign traces using lag corrections
%% ------------------------------------------------------------------------

fprintf('\n--- Adjusting trigger times ---\n');
c = adjusttrig(c,'MIN',1);

figure('Name','Aligned traces');
plot(c,'sha');

%% ------------------------------------------------------------------------
%% Hierarchical clustering
%% ------------------------------------------------------------------------

fprintf('\n--- Hierarchical clustering ---\n');
c = linkage(c);

figure('Name','Cluster dendrogram');
plot(c,'den');

%% ------------------------------------------------------------------------
%% Extract largest event cluster
%% ------------------------------------------------------------------------

fprintf('\n--- Extracting largest cluster ---\n');
c = cluster(c,0.8);
index = find(c,'CLUST',1);
c1 = subset(c,index);

figure('Name','Largest cluster (wiggle)');
plot(c1,'wig');

%% ------------------------------------------------------------------------
%% Convert between waveform and correlation objects
%% ------------------------------------------------------------------------
% Waveforms are stored internally as WAVEFORM objects and can be extracted,
% modified externally, and reinserted.

fprintf('\n--- Waveform extraction and reinsertion ---\n');
w  = waveform(c1);

for n = 1:numel(w)
    w(n) = w(n) .^ 2 .* sign(w(n));
end

c2 = correlation(c1,w);

%% ------------------------------------------------------------------------
%% Sign traces (remove amplitude information)
%% ------------------------------------------------------------------------

fprintf('\n--- Sign-normalized traces ---\n');
c2 = sign(c1);

figure('Name','Signed traces');
plot(c2,'wig',0.3);

%% ------------------------------------------------------------------------
%% Stack traces
%% ------------------------------------------------------------------------

fprintf('\n--- Stacking traces ---\n');
c1 = crop(c1,-4,9);
c1 = norm(c1);
c1 = stack(c1);
c1 = norm(c1);

figure('Name','Stacked traces');
plot(c1,'wig');

%% ------------------------------------------------------------------------
%% Residual waveform (remove stack)
%% ------------------------------------------------------------------------

fprintf('\n--- Residual waveforms ---\n');
c2 = norm(c1);
c2 = minus(c2);

figure('Name','Residual waveforms');
plot(c2,'raw',0.5);

%% ------------------------------------------------------------------------
%% Interferogram
%% ------------------------------------------------------------------------

fprintf('\n--- Interferogram ---\n');
c1 = xcorr(c1,[1 3]);
c1 = adjusttrig(c1);
c1 = interferogram(c1);

figure('Name','Interferogram (correlation)');
plot(c1,'int',1,'corr');

figure('Name','Interferogram (lag)');
plot(c1,'int',1,'lag',0.01);

%% ------------------------------------------------------------------------
%% Occurrence plot
%% ------------------------------------------------------------------------

fprintf('\n--- Occurrence plot ---\n');
c = crop(c,-3,10);

figure('Name','Occurrence plot');
plot(c,'occurrence',1,1:10);

%% ------------------------------------------------------------------------
%% Overlay plot (largest cluster)
%% ------------------------------------------------------------------------

fprintf('\n--- Overlay plot ---\n');
index = find(c,'CLUST',1);

figure('Name','Overlay plot');
plot(c,'overlay',1,index);

%% ------------------------------------------------------------------------
%% Notes
%% ------------------------------------------------------------------------
% Automated validation of correlation functionality is handled by:
%
%   tests/test_Correlation.m
%
% This cookbook is intended for:
%   • human learning,
%   • scientific reproducibility,
%   • classroom teaching,
%   • documentation publication.
%
% It should NOT be used for CI testing.