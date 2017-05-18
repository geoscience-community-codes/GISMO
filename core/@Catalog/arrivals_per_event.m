function arrivals_per_event(cobj)
    N = numel(cobj.arrivals);
    na = [];
    if N>1
        for c=1:N
            na = [na numel(cobj.arrivals{c}.time)];
        end
        m = max(na);
        for v=1:m
            disp(sprintf('arrivals = %d, count = %d', v, sum(na==v) ));
        end
    end
    
end
         