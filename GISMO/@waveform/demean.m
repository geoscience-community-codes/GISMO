function w = demean (w)
%DEMEAN remove offset voltage from signal
%   waveform = demean(waveform)
%   Removes the mean signal from the waveform object
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

Nmax = numel(w);

for I = 1 : Nmax
    w(I) = w(I) - mean(w(I));
end

w = addhistory(w,'mean removed');