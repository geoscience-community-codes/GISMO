function disp(f)
% DISP - Filterobject disp overloaded operator

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if numel(f) > 1;
    disp(' ');
    DispStr = sprintf('%d',size(f,1));
    for n = 2 : numel(size(f))
        DispStr = sprintf('%sx%d', DispStr, size(f,n));
    end
    disp(sprintf('%s %s object with fields:', DispStr, class(f)));
    disp('    type');
    disp('    cutoff');
    disp('    poles');
else
    switch f.type
        case 'B'
            typename = 'Bandpass';
        case 'L'
            typename = 'Low-pass';
        case 'H'
            typename = 'High-pass';
    end;
    disp(['      type: ' f.type ' (' typename ')']);
    disp(['    cutoff: ' num2str(f.cutoff) ' Hz']);
    disp(['     poles: ' num2str(f.poles)]);
end;