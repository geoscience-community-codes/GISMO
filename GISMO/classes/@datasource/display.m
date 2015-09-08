function display(ds)
%DISPLAY - datasource display overloaded operator

% VERSION: 1.0 of datasource object
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if isequal(get(0,'FormatSpacing'),'compact')
    disp([inputname(1) ' =']);
    disp(ds);
else
    disp(' ');
    disp([inputname(1) ' =']);
    disp(' ');
    disp(ds);
end