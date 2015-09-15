function [W, I] = sortby(W, criteria)
   % sortby sorts waveforms based on one of its properties
   % 
   % Wsorted = sortby(Win) sorts by the channeltag (N.S.L.C)
   %
   % Wsorted = sortby(Win, criteria), where criteria is a valid "get"
   % request.  ex. starttime, endtime, channelinfo, freq, data_length, etc.
   %
   % [Wsorted, I] = sortby(Win...) will also return the index list so that 
   %     Win(I) = Wsorted
   %
   % see also: sort, waveform/get
   
   if nargin < 2
      criteria = 'channeltag';
   end
   % sort by a field
   [~, I] = sort(get(W,criteria));
   W = W(I);
end