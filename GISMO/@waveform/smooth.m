function W = smooth(W, varargin)
% SMOOTH overloaded smooth function for waveform
% Differs from MATLAB's smooth function in that it takes one or more
% waveforms instead of a data vector.  
%
% See Also smooth

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

for n = 1:numel(W)
    W(n) = set(W(n),'data',smooth(double(W(n)),varargin{:}));
end
W = addhistory(W,{'Smoothed with these arguments',varargin});
