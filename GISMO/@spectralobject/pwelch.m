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
% See also PWELCH for more detail

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 02/07/2007

%variables used

if nargin < 2
    error('usage: [out] = pwelch(spectralobject, waveform, [''default'']');
end

if ~isscalar(w)
    error('waveform must be scalar (1x1)');
end

if ~isa(w,'waveform')
    error('second argument expected to be WAVEFORM, but was [%s]', class(w));
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
switch nargout
    case 0
        pwelch(data,[],[],NFFT,Fs);
    case 1
        varargout{1} = pwelch(data,window,over,NFFT,Fs);
    case 2
        [varargout{1} varargout{2}] = pwelch(data,window,over,NFFT,Fs);
    otherwise
        disp('pbbtt!!!!')
end