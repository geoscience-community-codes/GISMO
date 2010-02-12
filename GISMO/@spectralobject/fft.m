function [varargout] = fft(s, w)
%FFT Discrete Fourier transform.  OVERLOADED for waveform & Spectralobject
%   USAGE
%       v = fft(s, w);      % get the fft only
%       [v, f] = fft(s,w);  % get the fft & assoc. frequencies
%       [v, f, Pyy] = fft(s,w); % get fft, frequencies, and Power Spectrum
%
%   See also SPECTRALOBJECT/IFFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN, WAVEFORM/FILLGAPS.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if nargin < 2
    error('Spectralobject:fft:insufficientArguments',...
        'Not enough input arguments. [out]=fft(spectralobject, waveform)');
end

if ~isscalar(w)
    error('Spectralobject:fft:nonScalarWaveform',...
        'waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('Spectralobject:fft:invalidArgument',...
        'second argument expected to be WAVEFORM, but was [%s]', class(w));
end

if any(isnan(double(w)))
    warning('Spectralobject:fft:nanValue',...
        ['This waveform has at least one NaN value, which returns NaN ',...
        'results. Remove NaN values by either splitting up the ',...
        'waveform into non-NaN sections or by using waveform/fillgaps',...
        ' to replace the NaN values.']);
end

varargout{1} = builtin('fft', double(w));
varargout{2} = get(w,'fs') * (0:fix(get(s,'nfft')./2)) / get(s,'nfft');
varargout{3} = varargout{1}.* conj(varargout{1}) / get(s,'nfft');
varargout{3} = varargout{3}(1:length(varargout{2}));


