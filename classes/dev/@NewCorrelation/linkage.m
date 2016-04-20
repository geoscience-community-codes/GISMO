function c = linkage(c,varargin)
   %linkage   Agglomerative hierarchical cluster tree for Seismic Traces
   % c = LINKAGE(c) Creates a hierarchical cluster tree for all waveforms in
   % the correlation object. It reads the CORR field (must be filled) and
   % fills in the LINK field. This iuse is identical to c =
   % LINKAGE(c,'average').
   %
   % c = LINKAGE(c,...) is just a wrapper program which calls the linkage
   % function in the matlab stats toolbox.  Usage is the same as the stats
   % toolbox version except that the first argument and the returned value are
   % correlation objects. In most cases these will be the same object. See
   % HELP LINKAGE for details and usage. All options and user controls are the
   % same.
   %
   % ** IMPORTANT NOTE **: There is one significant difference from the
   % built-in linkage routine. The native linkage command operates on
   % *dissimilarity* information. That is, the opposite of correlation values.
   % When linkage is called on a correlation object, it expects max
   % correlation values as input. Temporary dissimiliarity information is
   % created internally and passed to the built in linkage routine.
   %
   % Common uses include:
   %   c = LINKAGE(c)           % returns clusters of similar waveforms
   % 	c = LINKAGE(c,'average') % same as first use
   % 	c = LINKAGE(c,'single')  % useful for evolving waveforms
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   % REQUIRES STATISTICS and MACHINE LEARNING TOOLBOX
   
   assert(c.ntraces >= 2, 'correlationLinkageTooFewTraces','LINKAGE requires that object contains at least two traces');
   
   K = 1.001 - c.corrmatrix;			% create dissimilarity matrix
   K = K - diag(diag(K));			% remove diagonal (required format)
   Y = squareform(K);          % transform to "pdist" vector format
   
   if nargin == 1
      c.link = linkage(Y,'average');
   else
      c.link = linkage(Y,varargin{:});
   end
   
end
