function display(f)
% DISPLAY - Filterobject display overloaded operator

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if isequal(get(0,'FormatSpacing'),'compact')
    disp([inputname(1) ' =']);
    disp(f);
else
    disp(' ');
    disp([inputname(1) ' =']);
    disp(' ');
    disp(f);
end