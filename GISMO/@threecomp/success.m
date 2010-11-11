function [mask,conflicts] = success(TC)

%SUCCESS Checks the success of a conversion to threecomp object.
% MASK = SUCCESS(TC) returns a boolean mask of 0's and 1's marking which
% waveform tuples where successfully converted to threecomp objects.
% Example where W is 5x3 waveform matrix with one row which does meet the
% minimum standards for a threecomp object:
%   TC = threecomp(W);
%      where TC is only 4x1
%   mask = success(TC);
%   mask'
%      1   1   1   1   0
% In this example, it was the fifth row of waveforms that were not
% converted to a threecomp object.
%
% [MASK,CONFLICTS] = SUCCESS(TC) returns itemized failure points in
% the threeecomp conversion. See function VERIFY for description of 
% CONFLICTS.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if isfield(TC(1).traces(1),'TMP_SUCCESSMASK')
    mask = get(TC(1).traces(1),'TMP_SUCCESSMASK');
else
    mask = [];
end
   
if isfield(TC(1).traces(1),'TMP_CONFLICTS')
    conflicts = get(TC(1).traces(1),'TMP_CONFLICTS');
else
    conflicts = [];    
end


