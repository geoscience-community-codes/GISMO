function RMS = rms(W, varargin)
%RMS root mean square of a waveform
%   RMS = sqrt((sum(signal .^2) / (N-1))
%
%  Values of NaN are removed before RMS calculation.
%
% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 11/25/2008

RMS = zeros(size(W));

for i = 1 : numel(W) %loop through an array of Waveforms
  Signal = get(W(i),'data'); %grab signal
  invalidMask = isnan(Signal);
  nInvalid = sum(invalidMask);
  N = length(Signal) - nInvalid; %
  RMS(i) = sqrt( sum(Signal(~invalidMask) .^ 2) / (N - 1) );
end