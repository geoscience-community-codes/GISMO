function [actions dates] = history(w)
%HISTORY retrieve the history of a waveform object
%   actions = history(waveform)
%       returns a cell of what's been done to this waveform object
%
%   [actions timestamps] = history(waveform)
%       returns a cell of what's been done to this waveform object
%       ACTIONS and a vector array of matlab datenums associated with
%       each action. ie, TIMESTAMPS.
% 
%
% See also WAVEFORM/ADDHISTORY, WAVEFORM/CLEARHISTORY, WAVEFORM/GET.

% HISTORY recording is controlled by global WAVEFORM_HISTORY from
% waveform/waveform

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if numel(w) > 1
    error('Waveform:history:tooManyWaveforms',...
      'Can only get history for a single waveform at a time');
end
val = get(w,'history');
actions = val(:,1);
dates = datestr([val{:,2}]');

