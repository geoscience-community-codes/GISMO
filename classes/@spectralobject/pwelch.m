function varargout = pwelch(s,w, varargin)
%PWELCH   overloaded pwelch for spectralobjects
%   pwelch(spectralobject, waveform) - plots the spectral density
%       Pxx = pwelch(spectralobject, waveform) - returns the Power Spectral
%           Density (PSD) estimate, Pxx, of a discrete-time signal 
%           vector X using Welch's averaged,  modified periodogram method.
%       [Pxx, Freqs] = pwelch(spectralobject, waveform) - returns spectral
%       density and associated frequency bins.
%
%       Options, pwelch(s,w, 'DEFAULT') - plots the spectral density using
%       pwelch's defaults (8 averaged windows, 50% overlap)
%   window is length of entire waveform..
%
%   NOTE: voltage offsets may cause a large spike for lowest Pxx value.
%   NOTE: NaN values will result in blank
%
% See also pwelch, waveform/fillgaps

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

%variables used

if nargin < 2
    error('Spectralobject:pwelch:insufficientArguments',...
        'usage: [out] = pwelch(spectralobject, waveform, [''default'']');
end

if ~isscalar(w)
    error('Spectralobject:pwelch:nonScalarWaveform',...
        'waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('Spectralobject:pwelch:invalidArgument',...
        'second argument expected to be WAVEFORM, but was [%s]', class(w));
end

if any(isnan(double(w)))
    warning('Spectralobject:pwelch:nanValue',...
        ['This waveform has at least one NaN value. ',...
        'Remove NaN values by either splitting up the',...
        ' waveform into non-NaN sections or by using ',...
        'waveform/fillgaps to replace the NaN values.']);
end
Fs = get(w,'fs');
NFFT = get(s,'nfft');
over = get(s,'overlap');
data = double(w);
window = length(data);
if nargin == 3
    varargin{1}
    if strcmpi(varargin{1}, 'DEFAULT')
        %disp('defaulting')
        window = [];
        over = [];
    end
end
clear w
[varargout{1:nargout}] =  pwelch(data,window,over,NFFT,Fs);