function [varargout] = ifft(s, w)
%IFFT Inverse discrete Fourier transform.  OVERLOADED FOR Spectralobject
%   IFFT(spectralobject, X) is the N-point inverse discrete Fourier
%   transform of X, using the spectralobject's NFFT value for N.
%
%   See also SPECTRALOBJECT/FFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN.

%   Copyright 1984-2003 The MathWorks, Inc.
%   $Revision$  $Date$

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if nargin < 2
    error('Spectralobject:ifft:insufficientArguments',...
        'Not enough input arguments. [out]=ifft(spectralobject, waveform)');
end

if ~isscalar(w)
    error('Spectralobject:ifft:nonScalarWaveform',...
        'waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('Spectralobject:ifft:invalidArgument',...
        'second argument expected to be WAVEFORM, but was [%s]', class(w));
end

if nargout == 0
  builtin('ifft', double(w), get(s,'nfft'));
else
  [varargout{1:nargout}] = builtin('ifft', double(w), get(s,'nfft'));
end
