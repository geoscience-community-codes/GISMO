function family=getclusterstat(c)

%GETCLUSTERSTAT gets detais of individual correlation clusters.
% family = GETCLUSTERSTAT(C) outputs a structure FAMILY which contains
% pertinent details of clusters that exist in C. This is a simple routine
% that assumes all cluster calculation has already been done. Note that in
% many cases it may be more appropriate to get the direct CLUST field from
% a correlation object. In some cases however, GETCLUSTERSTAT may be more
% expedient. The FAMILY structure includes the fields:
%   rank:    size order of the cluster (scalar)
%   numel:   number of events in the cluster (scalar)
%   index:   the index of the cluster events in the correlation object(Nx1)
%   trig:    trigger times of the cluster events (Nx1)
%   begin:   the eariest trigger time in the cluster (scalar)
%   finish:  the last trigger time in the cluster (scalar)
% The fields index and trig are cell arrays.
%
% See also correlation/cluster

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



if nargin <= 0
    error('Wrong number of inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if isempty(get(c,'CLUST'))
    error('CLUSTER field must be filled in input argument. See HELP CLUSTER');
end


for n = 1:max(get(c,'CLUST'))
    f = find(c,'CLUST',n);
    c1 = subset(c,f);
    family.rank(n) = n;
    family.numel(n) = numel(f);
    family.index(n) = {f};
    family.begin(n) = min(get(c1,'TRIG'));
    family.finish(n) = max(get(c1,'TRIG'));
    family.trig(n) = {get(c1,'TRIG')};
end




