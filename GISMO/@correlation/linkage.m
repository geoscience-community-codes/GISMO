function c = linkage(c,varargin);

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


if nargin <= 0
    error('Not enough inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end;

if get(c,'TRACES')<2
    error('correlationLinkageTooFewTraces','Correlation object must contain at least two traces to use the LINKAGE function');
end;


% if isempty(get(c,'LAG'))
%     error('LAG field must be filled in input object');
%     error('See correlation/linkage function');
% end;




K = 1.001 - c.C;			% create dissimilarity matrix
K = K - diag(diag(K));			% remove diagonal (required format)
Y = squareform(K);          % transform to "pdist" vector format


if nargin == 1
    c.link = linkage(Y,'average');
else
    c.link = linkage(Y,varargin{:});
end


