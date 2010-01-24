function display(c)

% CORRELATION/DISPLAY Command window display of a correlation object
% See help correlation for fields

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



disp(' ');
disp([inputname(1),' = '])
disp(' ');
%
[i,j] = size(c.W);
disp(['  WAVEFORMS: ' num2str(i) 'x' num2str(j) ' vector']);
%
[i,j] = size(c.trig);
disp(['       TRIG: ' num2str(i) 'x' num2str(j) ' vector']);
%
[i,j] = size(c.C);
disp(['       CORR: ' num2str(i) 'x' num2str(j) ' square matrix']);
%
[i,j] = size(c.L);
disp(['        LAG: ' num2str(i) 'x' num2str(j) ' square matrix']);
%
[i,j] = size(c.stat);
disp(['       STAT: ' num2str(i) 'x' num2str(j) ' matrix']);
%
[i,j] = size(c.link);
disp(['       LINK: ' num2str(i) 'x' num2str(j) ' matrix']);
%
[i,j] = size(c.clust);
disp(['      CLUST: ' num2str(i) 'x' num2str(j) ' vector']);
