function w = uminus(w)
%-  Unary minus for waveforms.
%   -A negates the elements of A.
%
%   B = UMINUS(W) is called for the syntax '-W' when W is an waveform.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

for n=1:numel(w)
    w(n).data = -w(n).data;
end
w = addhistory(w,'multiplied by -1');
