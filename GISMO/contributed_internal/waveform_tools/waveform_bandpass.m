function [w] = waveform_bandpass(w, Flow, Fhigh, npoles);
% [w] = waveform_bandpass(w, flow, fhigh, order)
% Glenn Thompson, 2009

% Data
y = get(w, 'data'); 

% Sampling frequency
Fs = round(get(w, 'freq'));

% Filter the velocity
[b, a] = butter(npoles, [(2 * Flow / Fs) (2 * Fhigh / Fs)]);
y = filter(b, a, y); 

set(w, 'data', y);
