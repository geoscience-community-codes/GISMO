function w = waveform(c)

%WAVEFORM Extract a waveform object.
%
% W = WAVEFORM(C) Extracts a waveform object from inside a correlation
% object. This is really just intuitive shorthand for W =
% GET(C,'WAVEFORM').
%
% This function is particularly useful for manipulating waveforms using
% tools outside the correlation toolbox. 
% 
% Example:
%   % square the amplitudes of each trace (sign-sensitive)
%   w  = waveform(c);
%   w1 = (w.^2)
%   w2 = sign(w);
%   for n = 1:numel(w)
%        w(n) = w1(n) .* w2(n);
%   end
%   c = correlation(c,w);

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


w = c.W;