function cobj2 = subset(cobj, indices)
    %CATALOG.SUBSET Create a new catalogObject by subsetting based
    %on indices. 
    cobj2 = cobj;
    N = numel(cobj.otime)
    cobj2.otime = cobj.otime(indices);
    if numel(cobj.lon)==N
        cobj2.lon = cobj.lon(indices);
    end
    if numel(cobj.lat)==N
        cobj2.lat = cobj.lat(indices);
    end
    if numel(cobj.depth)==N
        cobj2.depth = cobj.depth(indices);
    end
    if numel(cobj.mag)==N
        cobj2.mag = cobj.mag(indices);
    end
    if numel(cobj.magtype)==N
        try % there is a limit on subsetting cell array
        cobj2.magtype = cobj.magtype{indices};
        end
    end
    if numel(cobj.etype)==N
        try
        cobj2.etype = cobj.etype{indices};
        end
    end
    if numel(cobj.arrivals)==N
        cobj2.arrivals = cobj.arrivals(indices);
    end
    if numel(cobj.waveforms)==N
        cobj2.waveforms = cobj.waveforms(indices);
%         counter = 1;
%         indices
%         for thisindex=indices
%             cobj2.waveforms{counter} = cobj.waveforms{thisindex};
%             counter = counter + 1;
%         end
    end
    if numel(cobj.ontime)==N
        cobj2.ontime = cobj.ontime(indices);
    end
    if numel(cobj.offtime)==N
        cobj2.offtime = cobj.offtime(indices);
    end    
end