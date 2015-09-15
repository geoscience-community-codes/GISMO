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

% now that it is part of waveform, we have special access which allows us 
% to manipulate the data in place,significantly reducing the memory
% footprint. 

    % Remove linear trend discontinuously, from one gap (NaN) to another
    for i=1:numel(w)
       nans = isnan(w(i).data); %since logical,(1/8) memory footprint
        if sum(~nans) > max([3 numel(nans)*0.2]) % at least 20% must be non-nan
            % Here we remove continguous NaNs because otherwise we get an out
            % of memory error. So when we meet a sequence like [3.4 NaN NaN NaN
            % 2.3] we keep the NaN bookends, but then put zeros between
            % bookends, e.g. [3.4 NaN 0 NaN 2.3]. SO for a long data gap, which
            % might have thousands of contiguous NaNs, we end up with thousands
            % of zeros, with a single NaN on each end. That segment will then
            % get detrended as a single unit, rather than as thousands of
            % separate segments (which takes forever and causes out of memory
            % errors).
            
            firstNans = find(diff([false,nans]) == 1);
            lastNans = find(diff([nans, false]) == -1);
            assert(numel(firstNans) == numel(lastNans))
            nContiguousNans = lastNans - firstNans + 1;
            
            % keep only stretches of 3 or more
            firstNans(nContiguousNans < 3) = [];
            lastNans(nContiguousNans < 3) = [];
            
            % replace values in between those stretches with zero
            firstNans = firstNans + 1;
            lastNans = lastNans - 1;
            for c=1:numel(firstNans)
               w(i).data(firstNans(c):lastNans(c)) = 0;
            end
            
            %{ 
            % the following logic has been replaced
            bp = find(allnans);
            if length(bp)>=3
                for c=2:length(bp)-1
                    if bp(c)==bp(c-1)+1;
                        w(i).data(bp(c))=0;
                    end
                end
            end
            %}
            try
                w(i).data = detrend(w(i).data, 'linear', bp);
            catch er
               %it's all messed up, so put w(i) back the way it was
               w(i).data(nans) = nan;
                warning(er.identifier,[message,...
                   '\n detrending w(%d): ',...
                   'unable to remove trend from each line segment'], i)
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
