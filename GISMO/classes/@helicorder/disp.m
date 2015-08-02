function disp(h)
%DISP: Helicorder disp overloaded operator
%
% See also HELICORDER
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

nw = numel(h.wave);
disp(' ');
fprintf('%s object with %d waveform(s):\n',class(h), nw);

for n = 1:nw
if n == 1
 stacha = [get(h.wave(n),'station'),':',get(h.wave(n),'channel')];
else
 stacha = [stacha,', ',get(h.wave(n),'station'),':',get(h.wave(n),'channel')];
end
end


fprintf(['    STA/CHA:      ',stacha,'\n']);
fprintf('    START:        %s\n',datestr(get(h.wave(1),'start')));
fprintf('    DURATION:     %s\n',get(h.wave(1),'duration_str'));
fprintf('    MINUTES/LINE: %d\n',h.mpl);
fprintf('    DISPLAY TYPE: %s\n',h.display);



