function w = clean(w, f)
% CLEAN Clean up waveform object(s)
%   w = clean(w) will detrend waveforms (in a smart way, aware of NaN
%   values marking missing values), then use fillgaps to mark bounded NaNs
%   with linear-interpolated values, and also mark bounded NaNs with zeroes
%   (now okay, since trend has been removed, so no weird startup effects).
%   It then removes non-linear trends using a 20-s (0.05 Hz) highpass
%   filter.

% Glenn Thompson March 28, 2017
    if ~exist('f','var')
        f = 0.05; % 20-s
    end

    for c=1:numel(w)
        
        if ~isempty(w(c))
            
            % remove spikes of length 1
            %w(c) = medfilt1(w(c), 3); 

            % smart detrend
            w(c) = detrend(w(c));

            % % fill gaps to get rid of NaNs marking missing values, so we can filter
            w(c) = fillgaps(w(c), 'interp');

            % highpass data at 20s - to remove non-linear trends
            fobj = filterobject('h',f,2);
            w(c) = filtfilt(fobj,w(c));
            
            % detrend again
            w(c) = detrend(w(c));
        
        end
    end

end