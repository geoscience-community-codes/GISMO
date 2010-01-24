function c = norm(c,varargin)

% C = SORT(C,'TIME')
% Sorts traces a function of time from oldest to youngest.
% Currently no other types of sorting have been implimented
%
% C = SORT(C)
% Short hand for SORT(C,'TIME')
%

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



% READ & CHECK ARGUMENTS
if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

% CHOOSE SORT TYPE
if nargin==1
    type = 'TIM';
elseif isa(varargin{1},'char')
    type = varargin{1};
else
    error('Incorrect inputs');
end;


% SORT TRACES
if strncmpi(type,'TIM',3)
    [S,I] = sort(c.trig);
    c = subset(c,I);
else
    disp('Sort type not recognized');
end;
