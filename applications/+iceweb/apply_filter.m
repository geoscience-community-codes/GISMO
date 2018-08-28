function w = apply_filter(w, PARAMS)
    if ~exist('PARAMS','var')
        PARAMS.filterObj = filterobject('h',0.1,2);
    end
    for c=1:numel(w)
        try
            w(c) = filtfilt(PARAMS.filterObj, w(c));
        end
    end
end
