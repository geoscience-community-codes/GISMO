function arrivalobj = addmetrics(arrivalobj, maxTimeDiff)
%ADDMETRICS add metrics to waveforms in Arrival object
%   arrivalobj = addmetrics(arrivalobj, maxTimeDiff)
    disp('Computing waveform metrics for arrivals')
    w = arrivalobj.waveforms;
    N = numel(w);
    if N>0
        w = addmetrics(w, maxTimeDiff);
        amp=-ones(size(w));
        for c=1:N
            m = get(w(c), 'metrics');
            amp(c) = max(abs([m.maxAmp m.minAmp]));
        end
        arrivalobj.amp = amp;
        arrivalobj.waveforms = w;
    end

end


