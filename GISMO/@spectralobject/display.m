function display(s)
%DISPLAY - spectralobject display overloaded operator

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if isequal(get(0,'FormatSpacing'),'compact')
    disp([inputname(1) ' =']);
    disp(s);
else
    disp(' ');
    disp([inputname(1) ' =']);
    disp(' ');
    disp(s);
end