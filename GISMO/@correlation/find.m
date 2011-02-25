function index = find(c,varargin)

% INDEX = FIND(c,'CLUST',WHICH_CLUSTER)
% Returns a list of trace numbers belonging to the cluster specified by
% WHICH_CLUSTER. If WHICH_CLUSTER is 1, then cluster with the most traces
% will be returned. If WHICH_CLUSTER is 2, then the seconds largest cluster
% will be returned, and so on. Often this use will be paired with SUBSET or
% STACK. For example, to plot the largest cluster of traces followed by 
% a stack of these traces:
%   INDEX = FIND(c,'CLUST',1)
%   c1 = SUBSET(c,INDEX)  
%   c1 = stack(c1)
%   plot(c1)
%
% INDEX = FIND(c,'BIG',SIZE)
% Returns a list of trace numbers belonging to any cluster that has at
% leats SIZE number of traces. For example, to get all clusters that
% contain 5 or more traces:
%   INDEX = FIND(c,'BIG',5)
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% READ & CHECK ARGUMENTS
if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if length(varargin)==0
   error('More arguments needed');
else
    type = varargin{1};
end
    

% EXECUTE FIND TYPE
if strncmpi(type,'CLU',3)
    n = varargin{2};
    if isa(n,'double')
        index = find_clu(c,n);
    else
       error('second argument must be a number'); 
    end
elseif strncmpi(type,'BIG',3)
    n = varargin{2};
    if isa(n,'double')
        index = find_big(c,n);
    else
       error('second argument must be a number'); 
    end    
else
    error('This use of find is not recognized');
end;








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND CLUSTERS
%

function index = find_clu(c,n);
if isempty(c.clust)
	error('No cluster information available. Consider using the linkage and cluster functions.');
end
famsize = histc(c.clust,[0:max(c.clust)]+.5  );
[famsize,fami] = sort(famsize,'descend');
if n > max(c.clust)
   error(['There are only ' num2str(max(c.clust)) ' clusters']); 
end
index = [];
for i = 1:length(n)
    index = cat(1,index,find(c.clust==fami(n(i))));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND BIGGEST CLUSTERS
%

function index = find_big(c,n);

famsize = histc(c.clust,[0:max(c.clust)]+.5  );
[famsize,fami] = sort(famsize,'descend');
if n > max(famsize)
   warning(['There are no clusters with more than ' num2str(max(famsize)) ' traces']); 
end
index = [];

f = find(famsize>=n);

for i = 1:length(f)
    index = cat(1,index,find(c.clust==fami(f(i))));
end

