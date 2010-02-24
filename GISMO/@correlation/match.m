function [c1,c2] = match(c1,c2,varargin)

%Retain matching elements of two correlation objects.
%
% [C1,C2] = MATCH(C1,C2) Returns those elements of c1 and c2 which have
% matching trigger times. Typically this will be used to sync correlation
% objects from two different stations covering the same time frames, or 
% sync'ing two channels from the same station. 
%
% [C1,C2] = MATCH(C1,C2,TOLERANCE) allows traces to match when their
% trigger times are within TOLERANCE seconds of each other. When this
% parameter is not included, the default value is 1 second.
% 
% CAVEATS: Note that if C2 has multiple traces which match a trigger time
% in C1, there is no way of controling which single trace in C2 will be
% considered a match. Similarly, if C1 contains multiple traces with the
% same trigger time, a match for each one will be found in C2.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date:$
% $Revision:$





% READ & CHECK ARGUMENTS
if (nargin>3)
    error('Wrong number of inputs');
end;

if ~strcmpi(class(c1),'correlation') | ~strcmpi(class(c2),'correlation') 
    error('First and second arguments must be a correlation object');
end

if length(varargin)>=1
    if isa(varargin{1},'double')
       tolerance = varargin{1};
    else
        error('TOLERANCE MUST BE A SCALAR NUMBER IN SECONDS');
    end
else
    tolerance = 1;   % time misfit tolerance in seconds
end

disp(['Tolerance for successful match is: ' num2str(tolerance) ' seconds']);




% FIND ELEMENTS THAT MATCH
trig1 = get(c1,'TRIG');
trig2 = get(c2,'TRIG');
matchIndex = [];
for n = 1:numel(trig1)
    [minVal,minIndex] = min(abs(trig2 - trig1(n))*86400);
    if minVal < tolerance
        matchIndex(n) = minIndex;
    else
       matchIndex(n) = 0; 
    end
end


% SUBSET FIRST CORRELATION OBJECT
index = find(matchIndex);
c1 = subset(c1,index);

% SUBSET FIRST CORRELATION OBJECT
index = matchIndex(find(matchIndex));
c2 = subset(c2,index);


