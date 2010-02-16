function w = abs(w)
%ABS Absolute value for the waveform object
%   waveform = abs(waveform)
%   equivelent to running "abs" on the data within the waveform.
%
%   Input Argument
%       WAVEFORM: waveform object       N-DIMENSIONAL
%
%  input waveform may be N-dimensional
% See also ABS.
   
% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

for n=1:numel(w)
    w(n).data = abs(w(n).data);
end
w(n) = addhistory(w(n), 'Absolute value of data');