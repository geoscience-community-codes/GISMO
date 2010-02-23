function w = demean (w)
%DEMEAN remove offset voltage from signal
%   waveform = demean(waveform)
%   Removes the mean signal from the waveform object
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

global WAVEFORM_HISTORY

m = mean(w);

wh = WAVEFORM_HISTORY;
WAVEFORM_HISTORY = false;

w = w - m;
m = strcat('mean removed: ', num2str(m(:)));
%WAVEFORM_HISTORY = wh;

for n=1:numel(w)
    % w(n) = addhistory(w(n),'mean removed: %s',num2str(m(n)));
    w(n) = addhistory(w(n),m(n));
end