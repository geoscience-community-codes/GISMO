function c = demean(c,varargin);

% DEMEAN removes the mean of each trace.
%
% C = DEMEAN(C) removes the DC offset from each trace. In most cases it is
% unnecessary to call this function directly. By default, all traces are
% demeaned and detrended when they are loaded into a correlation object.
% This is one of the assumptions of the correlation toolbox.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

c.W = demean(c.W);