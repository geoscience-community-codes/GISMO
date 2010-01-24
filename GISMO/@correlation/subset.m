function c = subset(c,index)

% c = SUBSET(c,INDEX)
% This function subsets a correlation object to include only those traces
% specified by the vector in INDEX. If INDEX = [1 3 5], all traces except
% for 1,3,5 are discarded. The order of traces is the same order as traces
% appear in c.trig and c.start fields. The fields LINK or CLUST must be 
% recalculated after subsetting as their values are no longer valid. 
% SUBSET replaces these fileds with []. Example:
%       d = SUBSET(c,[1 3 5]);
%
% USAGE NOTE: The returned values will be ordered as listed in the INDEX
% vector. In most circumstances, INDEX will be monotonically increasing.
% However, SUBSET can also be used to reorder the traces using any
% permutation. This may include duplicate events. SUBSET(c,[5 5 5 1]) will
% return a new object that contains three copies of trace followed by a
% single copy of trace 1.
%

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



% RESHAPE AS COLUMN VECTOR
index = reshape(index,length(index),1);


% SELCT DESIRED DATA

c.W = c.W(index);

c.trig = c.trig(index);

if ~isempty(c.C)
    c.C = c.C(index,:);
    c.C = c.C(:,index);
end;

if ~isempty(c.L)
    c.L = c.L(index,:);
    c.L = c.L(:,index);
end;

if ~isempty(c.stat)
    c.stat = c.stat(index,:);
end;

c.link = [];

if ~isempty(c.clust)
    c.clust = c.clust(index,:);
end;




