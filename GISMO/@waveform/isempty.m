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


%this rewrite short-circuits the check if any waveform is found that has no
%data.

TF = true;
for n=1:numel(w)
    if ~isempty(w(n).data)
        TF = false;
        break
    end
end
% originally: TF = (get(w,'data_length') == 0) == 1;