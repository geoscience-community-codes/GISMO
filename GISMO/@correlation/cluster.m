function c=cluster(c,varargin)

% c = CLUSTER(c,CUTOFF) cuts the "branches" of the linkage tree to create
% discrete clusters.  CLUSTER reads the LINK field (must be filled) and
% fills in the CLUST field. The first argument and the returned value are
% correlation objects. In most cases these will be the same object. CUTOFF
% is the inter-cluster correlation value from which clusters should be
% determined. See HELP LINKAGE for a more thorough discription of how the
% inter-cluster correlation values are computed. A CUTOFF value of 0.8 will
% create many small clusters of highly similar waveforms. A CUTOFF value of
% 0.5 will create a few large clusters of moderately similar waveforms.
% Actual values will depend on the specific dataset. This usage is likely
% the most common use of the CLUSTER function. It is shorthand for the more
% elaborate CLUSTER(c,'cutoff',1-CUTOFF,'criterion','distance'). Note the
% difference in how the CUTOFF value is specified however.
%
% This function is simply a wrapper program around the built-in CLUSTER
% function in the Matlab statistics toolbox. More elaborate uses of CLUSTER
% can be performed by using the following usage:
%
% c = CLUSTER(c, ...) simply passes the linkage information in c to the
% CLUSTER function in the stats toolbox. More information can be obtained
% from HELP CLUSTER. 
%
% ** IMPORTANT NOTES (REALLY) **
% There is one major difference when using the more elaborate CLUSTER
% function. The native Matlab CLUSTER function expects CUTOFF values that
% represent *dissimilarity*. For ease and compatibility in the correlation
% toolbox the simple two value usage above is overwritten to allow CUTOFF
% values to be given as a correlation threshold. Before passing to the
% built-in CLUSTER function, these values are subtracted from 1 to generate
% a dissimilarity value. When using more elaborate uses of the CLUSTER
% function, the CUTOFF value should be specified directly as a
% dissimilarity value. Note that this version of CLUSTER is currently
% incompatible with the 'MaxClust' option.
%
% The following two examples are identical:
%   c = CLUSTER(c,0.8)
%	c = CLUSTER(c,'CUTOFF',0.2,'Criterion','distance')

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



if nargin <= 1
    error('Not enough inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if isempty(get(c,'LINK'))
    error('LINK field must be filled in input object');
    error('See correlation/linkage function');
end

   
Y = c.link;
if (length(varargin)==1)
    tmpclust = cluster(Y,'cutoff',1-varargin{1},'criterion','distance');
else
    tmpclust = cluster(Y,varargin{:});
end


% RENUMBER CLUSTERS SO THAT LARGEST IS #1, 2ND LARGEST IS #2, ...
allval = unique(tmpclust);
for n = 1:numel(allval)
    allnum(n) = numel(find(tmpclust==allval(n)));
end
[allnum,index] = sort(allnum,'descend');
allval = allval(index);

c.clust = zeros(size(tmpclust));
for n = 1:numel(allval)
    f = find(tmpclust==allval(n));
    c.clust(f) = n;
end;




