function W = smooth(W, varargin)
% SMOOTH overloaded smooth function for waveform
% Differs from MATLAB's smooth function in that it takes one or more
% waveforms instead of a data vector.  
%
% See Also smooth

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

for n = 1:numel(W)
    W(n) = set(W(n),'data',smooth(W(n).data,varargin{:}));
end
W = addhistory(W,{'Smoothed with these arguments',varargin});
