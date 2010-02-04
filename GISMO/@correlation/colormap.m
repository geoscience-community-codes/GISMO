function c = align(c,varargin)

% C = COLORMAP(C)
% Apply the standard correlation toolbox colormap for cross-correlation
% values. This is the same colormap used in PLOT(C,'CORR').
% 
% C = COLORMAP(C,'CORR')
% Same as above but specifies the specific correlation colorscale on [0 1].
%
% C = COLORMAP(C,'LTCORR')
% A lightened version of the correlation colorscale.
% 
% C = COLORMAP(C,'LAG')
% Specifies the lag plot colorscale.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if (nargin>2)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if nargin==2
    mapname = varargin{1};
else
    mapname = 'CORR';
end
    
% GET COLORMAP
if strncmpi(mapname,'COR',3)
    cmap = load('colormap_corr.txt');
    colormap(cmap);
    caxis([0 1]);
elseif strncmpi(mapname,'LAG',3)
    cmap = load('colormap_lag.txt');
    colormap(cmap);
elseif strncmpi(mapname,'LTC',3)
    cmap = load('colormap_corr.txt');
    cmap = ( cmap + ones(size(cmap)) ) /2;
    colormap(cmap);
    caxis([0 1]);
else
    disp('Color scale not recognized');
end;


