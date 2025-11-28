%% GISMO Training 06: Master Event Correlation & Repeating Earthquakes
%
% This training demonstrates how to:
%
%   1. Load a continuous multi-segment waveform dataset
%   2. Preprocess for cross-correlation (gap-filling, detrending, filtering)
%   3. Define a master event "snippet" (template)
%   4. Scan continuous data for similar events using mastercorr.scan
%   5. Inspect correlation statistics (SNR, ccmax, lag)
%   6. Extract matched segments into a correlation object
%   7. Visualize stacked / aligned repeating events
%
% The script prefers the built-in mastercorr cookbook dataset, but
% gracefully falls back to synthetic data if it’s unavailable.
%
% -------------------------------------------------------------------------

clc;
close all;
warning off; %#ok<WNOFF>

disp('--- GISMO Training 06: Master Event Correlation ---');

%% 1. Load Demo Dataset (Preferred) --------------------------------------

useSynthetic = false;
W = waveform.empty;

try
    % Preferred: use the official mastercorr cookbook data
    % This should return an array of waveform objects (e.g., 6×1, 10 min each)
    W = mastercorr.load_cookbook_data;
    fprintf('Loaded %d waveform segments from mastercorr cookbook data.\n', numel(W));
catch ME
    warning('Training06:CookbookMissing', ...
        'mastercorr.load_cookbook_data failed (%s). Using synthetic data instead.', ...
        ME.message);
    useSynthetic = true;
end

%% 2. Synthetic Fallback (CI-Safe) ---------------------------------------

if useSynthetic
    % Create 6 segments of 10 minutes each at 50 Hz with a repeating pulse
    fs   = 50;                         % Hz
    dur  = 10*60;                      % seconds per segment
    t    = (0:1/fs:dur-1/fs)';         % time vector
    nseg = 6;
    W    = waveform.empty;

    for k = 1:nseg
        % Baseline noise
        x = 0.2*randn(size(t));

        % Inject a repeating "event" pulse every 2 minutes
        pulseTimes = 30:120:dur-30;   % seconds
        for pt = pulseTimes
            idx = round(pt*fs) + (-25:25);
            idx = idx(idx >= 1 & idx <= numel(x));
            x(idx) = x(idx) + hann(numel(idx));
        end

        % Build waveform object
        w = waveform;
        w = set(w, 'data', x, ...
                    'freq', fs, ...
                    'start', datenum(2020,1,1,0,0,0) + (k-1)*dur/86400, ...
                    'station', sprintf('STA%02d',k), ...
                    'channel','EHZ');

        W(k) = w;
    end

    fprintf('Synthetic dataset created: %d segments of %.1f minutes each.\n', ...
        numel(W), dur/60);
end

%% 3. Preprocess Data for Cross-Correlation ------------------------------

% Typical pre-processing:
%   • Fill gaps
%   • Detrend
%   • Bandpass filter to band of interest

Wproc = W;

Wproc = fillgaps(Wproc, 0);
Wproc = demean(Wproc);

% Bandpass: 0.8–12 Hz (typical for VT/tremor template matching)
fobj = filterobject('b', [0.8 12], 2);
Wproc = filtfilt(fobj, Wproc);

figure('Name','Preprocessed Continuous Data');
plot(Wproc, 'xunit','date');
title('Preprocessed Waveform Segments for Master Correlation');

%% 4. Define Master Snippet (Template Event) -----------------------------

% Use the 4th segment as the source for the master snippet (arbitrary)
% We take a 4-second window around the center of the trace.

w0   = Wproc(min(4, numel(Wproc)));  % safe if fewer than 4
t0   = get(w0, 'start');
dur0 = get(w0, 'duration');
tMid = t0 + dur0/2;

snippetStart = tMid - 2/86400;   % 2 seconds before center
snippetEnd   = tMid + 2/86400;   % 2 seconds after center

Wsnippet = extract(w0, 'time', snippetStart, snippetEnd);

% Add a reference trigger time (optional but recommended)
Wsnippet = addfield(Wsnippet, 'TRIGGER', tMid);

figure('Name','Master Snippet');
plot(Wsnippet);
title('Master Event Template (Snippet)');

%% 5. Run Master Correlation Scan ----------------------------------------

% Threshold: correlation coefficient above which we consider a match
ccThreshold = 0.8;

% mastercorr.scan will:
%   • Slide the snippet across each segment
%   • Compute normalized cross-correlation
%   • Attach match stats to the waveform headers
%
% Output:
%   Wxc : waveform array with correlation metadata
%   (Some versions also return Wcorr or similar; here we keep the
%    interface minimal and compatible with the current mastercorr package.)

[Wxc, Wxcorr] = mastercorr.scan(Wproc, Wsnippet, ccThreshold); %#ok<NASGU>

disp('Master correlation scan complete.');
disp('Inspecting first segment correlation fields:');
disp(get(Wxc(1), 'USERDATA'));

%% 6. Plot Summary Statistics --------------------------------------------

% The mastercorr.plot_stats helper provides:
%   • Histogram of correlation coefficients
%   • Time series of detected matches
%   • Optional SNR or lag statistics

figure('Name','mastercorr statistics');
mastercorr.plot_stats(Wxc);

%% 7. Extract Matched Waveforms & Correlation Object ---------------------

% mastercorr.extract returns:
%   match : struct array with match times, ccmax, lag, etc.
%   C     : correlation object containing extracted waveforms aligned
%
% The time window [-2, 6] seconds is relative to the detected match time.

[match, C] = mastercorr.extract(Wxc, -2, 6);

fprintf('Extracted %d matches into a correlation object.\n', numel(match));

if isempty(C)
    warning('No matches found above threshold = %.2f. Try lowering it.', ccThreshold);
    return
end

%% 8. Explore the Correlation Object -------------------------------------

% The correlation object supports:
%   • plot(C)                : aligned trace plot
%   • plot(C,'stack')        : stacked template
%   • sort(C)                : sort by correlation or time
%   • cluster(C)             : cluster repeated families (optional)
%   • lag(C)                 : view time shifts

figure('Name','Correlation: All Matches');
plot(C);
title('All Extracted Matches (Aligned by Cross-Correlation)');

% Basic stack (if available in your correlation version)
try
    Cstack = stack(C);
    figure('Name','Correlation Stack');
    plot(Cstack);
    title('Stacked Waveform of Repeating Events');
catch
    disp('stack(C) not available or failed — skipping stack plot.');
end

%% 9. Simple Match Summary -----------------------------------------------

% Basic text summary of match timings and ccmax values
ccmax = [match.ccmax]';
mtimes = [match.time]';

fprintf('\nTop 10 matches by correlation coefficient:\n');
[~, idx] = sort(ccmax, 'descend');
nShow = min(10, numel(idx));

for k = 1:nShow
    fprintf('  %2d) ccmax = %.3f   time = %s\n', ...
        k, ccmax(idx(k)), datestr(mtimes(idx(k))));
end

%% 10. Suggested Exercises -----------------------------------------------
%
%   • Change the bandpass filter (e.g., 2–8 Hz vs 0.5–15 Hz) and see how
%     it affects match counts.
%
%   • Adjust ccThreshold (e.g., 0.6, 0.7, 0.9) and compare:
%         - number of matches
%         - stacks (Cstack)
%
%   • Use a shorter or longer snippet window and see when matches become
%     unstable or overly generic.
%
%   • Combine this with Training 05:
%         - Build a Catalog from match times
%         - Compute EventRate for repeating families
%         - Compare RSAM vs repeating-event rate
%
% ------------------------------------------------------------------------

disp('GISMO Training 06 complete: master event correlation workflow finished.');