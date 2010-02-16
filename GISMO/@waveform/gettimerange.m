function [startTimeList endTimeList] = gettimerange(w)
%GETTIMERANGE returns the list of start and end times from a waveform array
%[startTimeList endTimeList] = gettimerange(w)

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

%specialized function that doesn't do much, ideal candidate for deprication
startTimeList = get(w,'start');
endTimeList = get(w,'end');