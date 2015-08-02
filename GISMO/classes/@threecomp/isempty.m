function TF = isempty(TC)

%ISEMPTY Display threecomp object
%   TF = ISEMPTY(TC) returns an array the same size as TC, containing
%   logical 1 (true) where the elements of TC are empty, and logical 0
%   (false) elsewhere. Empty is defined as containging no waveform data.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% CHECK INPUTS
if ~isa(TC,'threecomp')
    error('First argment must be a threecomp object');
end
if nargin~=1
    error('Incorrect number of arguments');
end


% CHECK EACH ELEMENT TO SEE IF IT IS EMPTY
[objSize1,objSize2] = size(TC);
numObj = numel(TC);
TF = zeros(size(TC));
for n = 1:numObj
    numSamples = min(get(TC(n).traces,'DATA_LENGTH'));
    if numSamples == 0
        TF(n) = 1;
    else
        TF(n) = 0;
    end
end


