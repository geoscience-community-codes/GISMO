function RMS = rms(W, varargin)
%RMS root mean square of a waveform
%   RMS = sqrt((sum(signal .^2) / (N-1))
%
%  Values of NaN are removed before RMS calculation.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

RMS = zeros(size(W));

for i = 1 : numel(W) %loop through an array of Waveforms
  Signal = W(i).data; %grab signal
  invalidMask = isnan(Signal);
  nInvalid = sum(invalidMask);
  N = length(Signal) - nInvalid; %
  RMS(i) = sqrt( sum(Signal(~invalidMask) .^ 2) / (N - 1) );
end