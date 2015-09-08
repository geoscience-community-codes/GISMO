function setmap(s, alternateMap)
%SETMAP   sets the default colormap used with spectrograms
%   USAGE: setmap(spectralobject, alternateMap)
%
%   EXAMPLE: setmap(s, bone(64));
%     this sets the map to the 'bone' colormap, with 64 shading  values.  
%     If you don't specify the # of values, MatLab will assign the colormap
%     to your current figure.  If no figure exists, MatLab will create one.
%
%   GETMAP and SETMAP are different from GET and SET in that they affect
%   all spectrograms, regardless of the spectralobject used.
%
%   Please Type HELP GRAPH3D to see a number of useful colormaps.

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007


global SPECTRAL_MAP
size(SPECTRAL_MAP)
sizecheck = size(alternateMap);
if sizecheck(2) ~= 3,
    warning('Map ignored.  alternateMap has  incorrect # columns; should be 3');
    return
end

SPECTRAL_MAP = alternateMap;