function [subset_list, corr_m] = correlate_waveforms(WAVEFORM_OBJECT, CORRTHRESH)
    % Function to correlate waveforms in a waveform object and keep the
    % waveforms that correlate above the given threshold to the master waveform

    % create correlation object of the waveforms to do the correlation
    c = correlation(WAVEFORM_OBJECT, get(WAVEFORM_OBJECT, 'start'));
    c2 = xcorr(c);
    corr = get(c2, 'CORR');
    corr_m = corr(:,1);
    %lag = get(c2, 'LAG'); don't need but may be useful later...

    % create object with correlation coefficient above CORRTHRESH
    keep = find(corr(:,1) > CORRTHRESH);
    c3 = subset(c2, keep);
    w3 = waveform(c3);

    % Extract the waveform files that correlate above the threshold
    h = get(w3, 'history');
    q = numel(h);
    if q == 4
        error('There is only one waveform in the waveform object!');
    else
        subset_list = cell(numel(h), 1);
        for count = 1:numel(h)
            h1 = h{count,1}{2,1};
            h11 = strrep(h1,'Loaded SAC file: ', '');
            subset_list{count} = h11;
        end
    end
end