function bool = isvertical(w)
% ISVERTICAL: Returns boolean array the same length as waveform object 'w'.
%             Boolean values determined by whether or not the channel field
%             of each element in 'w' ends with a 'Z'.
%
% USAGE: bool = isvertical(w)
% 
% INPUTS:  w - waveform object array
%
% OUTPUTS: bool - boolean array (vertical component or not?)

if ~isa(w,'waveform')
    error('waveform object input required')
end

chan = get(w,'channel');
if iscell(chan)
    for n =1:numel(chan)
        
        bool(n) = strcmpi(strtrim(chan{n}(end)),'Z');
        
    end
else
    bool = strcmpi(strtrim(chan),'Z');
end