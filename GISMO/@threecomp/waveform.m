function w = waveform(TC)

%WAVEFORM Get waveforms from a threecomp object
%   W = WAVEFORM(TC) Extracts waveforms from a threecomp object where W is
%   a waveform object and TC is a threecomp object.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


w = TC.traces;