function a = power(a, b)
%POWER (.^) waveform implementation of element-by-element power (.^)
%   waveform = waveform .^ Z;
%   waveform = power(waveform,Z);
%   raises each data point within the waveform objects to the power Z
%   if Z is an array (or a waveform), then each element of WAVEFORM is
%   multiplied by the appropriate element of Z.  Therefore, both the data
%   length of waveform and the array length of Z must be the same.
%
% See also POWER

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 4/16/2008

if ~ isa(a,'waveform')
    error('Waveform:power:invalidBase','Usage: waveform .^ double');
end
if ~(isnumeric(b) || isa(b,'waveform'))
    error('Waveform:power:invalidPower','Usage: waveform .^ double');
end

for N = 1:numel(a)
    a(N) = set(a(N),'data', double(a(N)) .^ double(b));
end

if isnumeric(b) && isscalar(b),
a = addhistory(a,'Raised to power: %s', num2str(b));
else
a = addhistory(a,'Raised to power: %s', inputname(2));
end