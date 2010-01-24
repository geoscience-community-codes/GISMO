function m = getmap(s)
%GETMAP  returns the colormap used for spectrograms
%
%   USAGE: m = getmap(spectralobject)
%       m is an Nx3 array with values corresponding to the current
%       spectralobject colormap
%
%   GETMAP and SETMAP are different from GET and SET in that they affect
%   all spectrograms, regardless of the spectralobject used.
%
%   p.s.- No. There is no way to set a map for spectralobjects individually

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

global SPECTRAL_MAP

m = SPECTRAL_MAP;
