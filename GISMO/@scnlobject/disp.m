function disp(sncl)
% DISP - scnl disp overloaded operator

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007
if numel(sncl) > 1;
    disp(' ');
    DispStr = sprintf('%d',size(sncl,1));
    for n = 2 : numel(size(sncl))
        DispStr = sprintf('%sx%d', DispStr, size(sncl,n));
    end
    disp(sprintf('%s %s object with fields:', DispStr, class(sncl)));
    disp('    station');
    disp('    channel');
    disp('    network');
    disp('   location');
else    
    disp(['   station: ' sncl.station]);
    disp(['   channel: ' sncl.channel]);
    disp(['   network: ' sncl.network]);
    disp(['  location: ' sncl.location]);
end;