function w = clean(w)
%CLEAN Clean a waveform by filling gaps with the mean value, and then
%detrending. This makes the waveform ready for filtering, etc.
%   w = clean(waveform)
%   returns a waveform containing a cleaned version of the waveform data
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       W: array of same size as WAVEFORM

% AUTHOR: Glenn Thompson
% $Date$
% $Revision$

	% Check input is a waveform object
	if ~isa(w, 'waveform')
		warning('Not a waveform object')
		return
    end
    
    % Remove linear trend discontinuously, from one gap (NaN) to another
    for i=1:numel(w)
        data = get(w(i),'data');
        if size(find(~isnan(data))) > max([3 length(data)*0.2]) % at least 20% must be non-nan
            % Here we remove continguous NaNs because otherwise we get an out
            % of memory error. So when we meet a sequence like [3.4 NaN NaN NaN
            % 2.3] we keep the NaN bookends, but then put zeros between
            % bookends, e.g. [3.4 NaN 0 NaN 2.3]. SO for a long data gap, which
            % might have thousands of contiguous NaNs, we end up with thousands
            % of zeros, with a single NaN on each end. That segment will then
            % get detrended as a single unit, rather than as thousands of
            % separate segments (which takes forever and causes out of memory
            % errors).
            bp = find(isnan(data));
            if length(bp)>=3
                for c=2:length(bp)-1
                    if bp(c)==bp(c-1)+1;
                        data(bp(c))=0;
                    end
                end
            end
            try
                data = detrend(data, 'linear', bp);
            catch
                warning('out of memory: unable to remove trend from each line segment')
            end
            if ~all(isnan(d))
                w(i) = set(w(i), 'data', data);
            end
        end
    end
    
    % Fillgaps with mean value (should be 0 since we've already detrended)
    y = mean(w);
    for i = 1:numel(w)
        w(i) = fillgaps(w(i), y(i));
    end
    
	% Remove linear trend for whole thing
	w = detrend(w);

end
