function display(w)
%DISPLAY Waveform Display overloaded operator

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/6/2007

if isequal(get(0,'FormatSpacing'),'compact')
    disp([inputname(1) ' =']);
    disp(w);
else
    disp(' ');
    disp([inputname(1) ' =']);
    disp(' ');
    disp(w);
end