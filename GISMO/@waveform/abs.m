function w = abs(w)
%ABS Absolute value for the waveform object
%   waveform = abs(waveform)
%   equivelent to running "abs" on the data within the waveform.
%
%   Input Argument
%       WAVEFORM: waveform object       N-DIMENSIONAL
%
% See also ABS.
   
% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

for n=1:numel(w)
    w(n) = set(w(n),'data',abs(get(w(n),'data')));
    w(n) = addhistory(w(n), 'Absolute value of data');
end