function varargout = spwelch(s,w, varargin)
% PWELCH   (* DEPRECATED*) overloaded pwelch for spectralobjects 
%   spwelch(spectralobject, waveform) - plots the spectral density
%       Pxx = pwelch(spectralobject, waveform) - returns the Power Spectral
%           Density (PSD) estimate, Pxx, of a discrete-time signal 
%           vector X using Welch's averaged,  modified periodogram method.
%       [Pxx, Freqs] = pwelch(spectralobject, waveform) - returns spectral
%       density and associated frequency bins.
%
%       Options, spwelch(s,w, 'DEFAULT') - plots the spectral density using
%       pwelch's defaults (8 averaged windows, 50% overlap)
%   window is length of entire waveform..
%
% THIS FUNCTION HAS BEEN REPLACED WITH PWELCH, and will be removed from
% future versions.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

error('Spectralobject:spwelch:Depricated',...
    ['spectralobject/spwelch has been deprecated. ',...
    'Please use spectralobject/pwelch instead.  the syntax is the same']);