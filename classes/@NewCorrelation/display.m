function display(c)

% CORRELATION/DISPLAY Command window display of a correlation object
% See help correlation for fields

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



disp(' ');
disp([inputname(1),' = '])
disp(' ');
%
showline('WAVEFORMS', c.traces, 'vector');
showline('TRIG', c.trig, 'vector');
showline('CORR', c.corrmatrix, 'square matrix');
showline('LAG', c.lags, 'square matrix');
showline('STAT', c.stat, 'matrix');
showline('LINK', c.link, 'matrix');
showline('CLUST', c.clust, 'vector');
end

function showline(fname, value, desc)
   fprintf('%11s: %s %s\n',fname, getsizestr(value), desc);
end

function s = getsizestr(val)
   sz = size(val);
   s = num2str(sz(1));
   for n=2:numel(sz)
      s = [s,'x',num2str(sz(n))];
   end
end
