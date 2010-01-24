function c = hilbert(c,n)

%HILBERT (for WAVEFORM objects) Discrete-time analytic Hilbert transform.
%   waveform = hilbert(waveform)
%   waveform = hilbert(waveform, N);
%
% This function does not return the complete (complex) hilbert transform,
% but rather the absolutely value of the transform typically used in
% seismology. To keep the imaginary values, use the built-in hilbert
% transform. 
%
% Be careful if cross correlating the hilbert transforms of waveforms.
% Becuase the nilbert transformed data is not oscillatory around zero in
% the traditional waveform sense, unexpected behaviors can result.
% Caveat Emptor!
%
% See HILBERT for the meaning of "N"


% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


if exist('n','var'),
    c.W = hilbert(c.W,n);
else
    c.W = hilbert(c.W);
end