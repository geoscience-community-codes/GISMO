function c = diff(c)

% DIFF differentiate each trace.
%
% C = DIFF(C) differentiate each trace through a call to WAVEFORM/DIFF.
% See WAVEFORM/DIFF for details

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


c.W = diff(c.W);