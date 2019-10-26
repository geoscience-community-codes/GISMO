function u = utnow(TZ)
    u = utnow;
    if isempty(u)
        global TZ
        if ~exist('TZ','var')
            TZ=0;
        end
        u = now - TZ/24;
    end
end