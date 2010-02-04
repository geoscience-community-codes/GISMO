function [varargout] = ifft(s, v)
%IFFT Inverse discrete Fourier transform.  OVERLOADED FOR Spectralobject
%   IFFT(spectralobject, X) is the N-point inverse discrete Fourier
%   transform of X, using the spectralobject's NFFT value for N.
%
%   See also SPECTRALOBJECT/FFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN.

%   Copyright 1984-2003 The MathWorks, Inc.
%   $Revision$  $Date$

% VERSION: 1.0 of spectralobject
% MODIFIED BY: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/7/2007

if nargin < 2
    error('Not enough input arguments.  [out] = ifft(spectralobject, waveform)');
end

if ~isscalar(w)
    error('waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('second argument expected to be WAVEFORM, but was [%s]', class(w));
end

if nargout == 0
  builtin('ifft', double(v), get(s,'nfft'));
else
  [varargout{1:nargout}] = builtin('ifft', double(v), get(s,'nfft'));
end
