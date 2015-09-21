function w = apply_filter(w, PARAMS)
    for c=1:numel(w)
        try
            w(c) = filtfilt(PARAMS.filterObj, w(c));
        end
    end
end
