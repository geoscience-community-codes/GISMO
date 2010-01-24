function [varargout] = fft(s, w)
%FFT Discrete Fourier transform.  OVERLOADED for waveform & Spectralobject
%   USAGE
%       v = fft(s, w);      % get the fft only
%       [v, f] = fft(s,w);  % get the fft & assoc. frequencies
%       [v, f, Pyy] = fft(s,w); % get fft, frequencies, and Power Spectrum
%
%   See also SPECTRALOBJECT/IFFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN.

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/7/2007

if nargin < 2
    error('Not enough input arguments.  [out] = fft(spectralobject, waveform)');
end

if ~isscalar(w)
    error('waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('second argument expected to be WAVEFORM, but was [%s]', class(w));
end

varargout{1} = builtin('fft', double(w));
varargout{2} = get(w,'fs') * (0:fix(get(s,'nfft')./2)) / get(s,'nfft');
varargout{3} = varargout{1}.* conj(varargout{1}) / get(s,'nfft');
varargout{3} = varargout{3}(1:length(varargout{2}));


