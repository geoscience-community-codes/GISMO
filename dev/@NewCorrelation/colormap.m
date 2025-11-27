function c = colormap(c,mapname)
   %colormap   apply a colormap to the cross-correlation
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
   narginchk(1,2)
   
   if ~exist('mapname','var')
      mapname = 'CORR';
   end
   
   switch upper(mapname)
      case {'CORR', 'COR'}
         cmap = load('colormap_corr.txt');
         colormap(cmap);
         caxis([0 1]);
      case 'LAG'
         cmap = load('colormap_lag.txt');
         colormap(cmap);
      case {'LTCORR', 'LTC'}
         cmap = load('colormap_corr.txt');
         cmap = ( cmap + ones(size(cmap)) ) /2;
         colormap(cmap);
         caxis([0 1]);
      otherwise
         error('Color scale not recognized');
   end
end
