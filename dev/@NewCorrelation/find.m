function index = find(c, type, value)
   
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
   % least SIZE number of traces. For example, to get all clusters that
   % contain 5 or more traces:
   %   INDEX = FIND(c,'BIG',5)
   %
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   assert(~isempty(c.clust),'Cluster information is not yet set, but can be set with linkage(...) and cluster(...).');
   
   %Find operations are trivial because clusters are assigned numbers by
   %their size in c.cluster(...), meaning that c.clust==1 is the largest,
   %c.clust==2 is the second, etc.
   
   switch upper(type)
      case {'CLUST', 'CLU'}
         index = find( c.clust == value );
      case {'BIG'}
         [famsize, famnum] = hist(c.clust, unique(c.clust));
         index = find(ismember(c.clust, famnum(famsize>=value)));
      otherwise
         error('This use of find is not recognized');
   end
end
