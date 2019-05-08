function [subset_list, corr] = correlate_waveforms(WAVEFORM_OBJECT, CORRTHRESH)
%CORRELATE_WAVEFORMS correlates all waveforms within the waveform object
%passed to the function and generate a cell array of the waveforms that
%correlate above a given threshold on the master waveform (the first on in
%the object). 
%       Input Arguments:
%           WAVEFORM_OBJECT: waveform object containing all the waveforms
%           in the multiplet family. The master event should be the first
%           on in the waveform object.
%           CORRTHRESH: correlation threshold. Recommend using at least
%           0.7 for multiplet families.
%       Output/Examples:
%           subset_list: cell array containing the filenames of all the
%           waveforms that correlate above the threshold.
%           corr_m: array of the correlation values between each waveform
%           and the master waveform.
%               Ex:
%                   w = load_waveforms(LIST,TYPE)
%                   [subset_list,corr_m] = correlate_waveforms(w,0.7)

    % create correlation object of the waveforms to do the correlation
    c = correlation(WAVEFORM_OBJECT, get(WAVEFORM_OBJECT, 'start'));
    c2 = xcorr(c);
    corr = get(c2, 'CORR');

    % create object with correlation coefficient above CORRTHRESH
    keep = find(corr(:,1) > CORRTHRESH);
    c3 = subset(c2, keep);
    corr = get(c3,'CORR');
    corr = corr(:,1);
    w3 = waveform(c3);

    % Extract the waveform files that correlate above the threshold
    history = get(w3, 'history');
    elements = numel(history);
    if numel(w3) == 1
        error('There is only one waveform in the waveform object!');
    else
        subset_list = cell(numel(history), 1);
        for count = 1:numel(history)
            file = history{count,1}{2,1};
            file = strrep(file,'Loaded SAC file: ', '');
            subset_list{count} = file;
        end
    end
end