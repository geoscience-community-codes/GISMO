function TF = isempty(w)
%ISEMPTY returns TRUE if waveform contains no data
%   TF = isempty(waveform);
%
%   if multiple waveforms are passed, this returns 'true' ONLY if ALL
%   waveforms are empty.
%
%
%  See also ISEMPTY

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/6/2007


%If waveforms have no data, first comparison is false (false == 0, too)
%second (outside) comparison makes sure that all waveforms contain no data
if numel(w) == 0, 
  TF = true; 
  return;
end;
TF= false;
for n=1:numel(w)
    if ~isempty(w(n).data)
        TF = true;
        break
    end
end
% originally: TF = (get(w,'data_length') == 0) == 1;