function w = apply_filter(w, PARAMS)
   % apply_filter   applies zero-phase filter to each waveform, (ignoring errors)
    for c=1:numel(w)
        try
            w(c) = filtfilt(PARAMS.filterObj, w(c));
        catch er
           disp(er);
        end
    end
end
