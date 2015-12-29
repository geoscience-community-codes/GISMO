function display(scnl)
%DISPLAY - scnlobject display overloaded operator

% VERSION: 1.0 of scnlobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if isequal(get(0,'FormatSpacing'),'compact')
    disp([inputname(1) ' =']);
    disp(scnl);
else
    disp(' ');
    disp([inputname(1) ' =']);
    disp(' ');
    disp(scnl);
end