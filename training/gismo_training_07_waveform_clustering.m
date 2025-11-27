%% GISMO TRAINING 07 — WAVEFORM CORRELATION & CLUSTERING
%
% This training script demonstrates:
%
%   • Event–event waveform cross-correlation
%   • Construction of full N×N correlation matrices
%   • Hierarchical clustering and dendrograms
%   • Automatic waveform family identification
%   • Family stacking
%
% This script refactors and modernizes the original mastercorr cookbook
% by Michael West for CI-safe teaching and reproducibility.
%
% Safe for use WITHOUT Antelope.
%
% Glenn Thompson + ChatGPT (2025)

clc; clear; close all;

disp('=== GISMO TRAINING 07: WAVEFORM CORRELATION & CLUSTERING ===');

%% ------------------------------------------------------------------------
% 1. LOAD OR GENERATE EVENT WAVEFORMS
% ------------------------------------------------------------------------

useSynthetic = false;

try
    % Attempt to load mastercorr demo dataset (if present)
    W = mastercorr.load_cookbook_data();
    disp('Loaded waveform data from mastercorr cookbook dataset.');
catch
    warning('Mastercorr demo data not found — using synthetic waveforms.');
    useSynthetic = true;
end

%% Synthetic fallback
if useSynthetic
    fs = 100;
    t = (0:1/fs:5)';
    N = 12;   % number of synthetic events

    W = waveform.empty;
    for k = 1:N
        f0 = 2 + 0.3*randn;         % slightly varying frequency
        x  = sin(2*pi*f0*t) .* exp(-t);
        x  = x + 0.05*randn(size(x));

        w = waveform;
        w = set(w, 'data', x);
        w = set(w, 'freq', fs);
        w = set(w, 'start', now + k/1440);
        W(k) = w;
    end

    disp('Synthetic waveform catalog created.');
end

N = numel(W);
fprintf('Number of events: %d\n', N);

%% ------------------------------------------------------------------------
% 2. PREPROCESS WAVEFORMS (STANDARD FOR CORRELATION)
% ------------------------------------------------------------------------

W = demean(W);
W = taper(W);
filt = filterobject('b', [1 10], 2);
W = filtfilt(filt, W);

%% ------------------------------------------------------------------------
% 3. BUILD FULL EVENT–EVENT CORRELATION OBJECT
% ------------------------------------------------------------------------

disp('Computing full cross-correlation matrix...');
C = correlation(W);
disp('Correlation object created.');

%% ------------------------------------------------------------------------
% 4. COMPUTE AND PLOT CORRELATION COEFFICIENT MATRIX
% ------------------------------------------------------------------------

R = corrcoef(C);   % N×N similarity matrix

figure('Name','Event Correlation Matrix','Color','w');
imagesc(R);
axis square;
colorbar;
title('Event–Event Correlation Coefficient Matrix');
xlabel('Event Index');
ylabel('Event Index');

%% ------------------------------------------------------------------------
% 5. HIERARCHICAL CLUSTERING & DENDROGRAM
% ------------------------------------------------------------------------

D = 1 - R;                  % distance metric
Dvec = squareform(D);      % condensed distance vector
Z = linkage(Dvec, 'average');

figure('Name','Waveform Dendrogram','Color','w');
dendrogram(Z);
title('Hierarchical Clustering of Waveform Similarity');
xlabel('Event Index');
ylabel('Distance (1 - CC)');

%% ------------------------------------------------------------------------
% 6. CUT DENDROGRAM INTO WAVEFORM FAMILIES
% ------------------------------------------------------------------------

ccThreshold = 0.75;        % correlation threshold for families
distThreshold = 1 - ccThreshold;

families = cluster(Z, 'cutoff', distThreshold, 'criterion', 'distance');

fprintf('Identified %d waveform families.\n', max(families));
disp('Family assignments:');
disp(families');

%% ------------------------------------------------------------------------
% 7. PLOT EACH WAVEFORM FAMILY
% ------------------------------------------------------------------------

uniqueFamilies = unique(families);

for f = uniqueFamilies(:)'
    idx = find(families == f);

    figure('Name', sprintf('Waveform Family %d', f), 'Color','w');
    plot_panels(W(idx), true);
    title(sprintf('Waveform Family %d (N = %d)', f, numel(idx)));
end

%% ------------------------------------------------------------------------
% 8. STACK EACH FAMILY
% ------------------------------------------------------------------------

disp('Computing family stacks...');

for f = uniqueFamilies(:)'
    idx = find(families == f);
    Wfam = W(idx);

    S = stack(Wfam);

    figure('Name', sprintf('Stacked Family %d', f), 'Color','w');
    plot(S);
    title(sprintf('Stacked Waveform — Family %d', f));
end

%% ------------------------------------------------------------------------
% 9. RELATIONSHIP TO MASTERCORR TEMPLATE MATCHING
% ------------------------------------------------------------------------
%
% This training script complements:
%
%   Training 06 — mastercorr template scanning (real-time detection)
%   Training 07 — event–event similarity + waveform family analysis
%
% Typical Observatory Workflow:
%
%   1. Continuous data → mastercorr.scan → detected events
%   2. Detected events → correlation(W)
%   3. correlation → corrcoef → dendrogram → waveform families
%   4. Families → stacking → eruption style interpretation
%
% This two-stage workflow matches best practice at AVO, MVO & Sakurajima.

disp('=== TRAINING 07 COMPLETE ===');