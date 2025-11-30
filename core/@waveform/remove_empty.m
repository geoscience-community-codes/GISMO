function wout = remove_empty(w)
%REMOVE_EMPTY Remove empty waveform objects (nsamp <= 1)
%
%   wout = remove_empty(w)
%
% Loops over a waveform vector and keeps only elements with
% more than 1 sample, using:
%     nsamp = get(w(count), 'data_length')
%
% This replaces the old IceWeb dependency:
%     iceweb.waveform_remove_empty
%
% CI-safe, Antelope-free.
%
% Glenn Thompson / Refactored 2025

    if isempty(w)
        wout = w;
        return;
    end

    keep = false(size(w));

    for count = 1:length(w)
        try
            nsamp = get(w(count), 'data_length');
            keep(count) = nsamp > 1;
        catch
            % If anything is malformed, discard safely
            keep(count) = false;
        end
    end

    wout = w(keep);
end
