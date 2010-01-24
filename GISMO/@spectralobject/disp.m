function disp(s)
%DISP - spectralobject disp overloaded operator

% VERSION: 1.0 of spectralobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

if numel(s) > 1;
    DispStr = sprintf('%d',size(s,1));
    for n = 2 : numel(size(s))
        DispStr = sprintf('%sx%d', DispStr, size(s,n));
    end
    disp(sprintf('%s %s object with fields:', DispStr, class(s)));
    
    disp('    nfft');
    disp('    over');
    disp('    freqmax');
    disp('    dBlims');
else
    disp(['       nfft: ' num2str(s.nfft)]);
    disp(['       over: ' num2str(s.over)]);
    disp(['    freqmax: ' num2str(s.freqmax)]);
    disp(['     dBlims: [' num2str(s.dBlims) ']']);
end;