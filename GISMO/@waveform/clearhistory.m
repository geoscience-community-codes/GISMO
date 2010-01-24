function w = clearhistory(w)
%CLEARHISTORY reset history of a waveform
%   waveform = clearhistory(waveform)
%   clears the history, leaving current date/time. To remove history 
%   altogether, use 'delfield'
%
%   Input Argument
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%
%
%   Control of whether or not history is added automatically lies within
%   the waveform constructor (in a global variable called WAVEFORM_HISTORY)
%
%
% See also WAVEFORM/ADDHISTORY, WAVEFORM/DELFIELD, WAVEFORM/ADDFIELD.

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

w = set(w,'HISTORY',{});
w = addhistory(w,'Cleared History');
