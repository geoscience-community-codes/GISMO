function tests = amplitude_spectrum_test()
% AMPLITUDE_SPECTRUM_TEST
% Unit tests for GISMOs amplitude_spectrum() function.
%
% Tests:
%   • a clean sinusoid embedded in noise produces a peak at the correct frequency
%   • returned frequency vector matches expected FFT length
%

tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
%  Test: Peak frequency detection
% -------------------------------------------------------------------------
function testSinusoidPeak(testCase)

fsamp = 100;        % Hz
fsignal = 2;        % injected sinusoid frequency (Hz)
duration = 60;      % seconds

t = 0:1/fsamp:duration;
y = 20*sin(2*pi*fsignal*t) + randn(size(t));

% Create waveform object
w = waveform;
w = set(w, 'data', y, 'freq', fsamp);

% Compute amplitude spectrum
[A, phi, f] = amplitude_spectrum(w);

% Find spectral peak
[~, idx] = max(A);
peakFreq = f(idx);

% Verify peak is near expected frequency (±0.2 Hz)
testCase.verifyLessThan(abs(peakFreq - fsignal), 0.2, ...
    sprintf('Peak frequency %.3f Hz is not near expected %.3f Hz', peakFreq, fsignal));

end

%% ------------------------------------------------------------------------
%  Test: Spectrum dimensions and frequency vector
% -------------------------------------------------------------------------
function testSpectrumDimensions(testCase)

fsamp = 50;
duration = 20;
t = 0:1/fsamp:duration;
y = sin(2*pi*3*t);

w = waveform;
w = set(w, 'data', y, 'freq', fsamp);

[A, phi, f] = amplitude_spectrum(w);

% Length checks
N_expected = floor((numel(y)/2) + 1);

testCase.verifyEqual(length(A), N_expected);
testCase.verifyEqual(length(f), N_expected);
testCase.verifyEqual(length(phi), N_expected);

end

%% ------------------------------------------------------------------------
%  Optional Fixtures
% -------------------------------------------------------------------------
function setupOnce(testCase)
% Placeholder: add GISMO path if needed
end

function teardownOnce(testCase)
% Placeholder
end

function setup(testCase)
% No figures during automated testing
close all;
end

function teardown(testCase)
close all;
end