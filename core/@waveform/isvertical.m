function [bool] = isvertical(W)
   
   % isvertical: Find all vertical component waveforms (boolean output)
   %
   %  USAGE: [bool] = isvertical(W)
   %
   %  INPUTS: W - waveform object array
   %
   %  OUTPUTS: bool - boolean array (same size as W)
   
   % Author: Dane Ketner, Alaska Volcano Observatory
   % $Date$
   % $Revision$
   
   if ~isa(W,'waveform')
      error('isvertical: waveform object input required')
   end
   
   tmp = get(W,'channel');
   if ischar(tmp)
      C{1} = tmp;
   elseif iscell(tmp)
      C = tmp;
   end
   
   for n = 1:numel(C)
      bool(n) = strcmpi(strtrim(C{n}(3)),'z');
   end
   bool = reshape(bool,size(W,1),size(W,2));
end