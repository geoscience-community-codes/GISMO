function w = clean(w)
%CLEAN Discontinuously detrend (between NaN values) and fillgaps with 0, to prepare waveform objects for filtering etc.
%   w = clean(waveform)
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       W: array of same size as WAVEFORM
%
%   Seismic waveform data often has missing samples, and these are represented by NaN in MATLAB. But most functions to
%   analyze seismic data in MATLAB will generate an error if there are NaN values in the data, or simple return NaN as the
%   answer. So the scientist must choose how to handle NaN values in the data.
%
%   Often a first step in analyzing any time series data is to detrend the data. But data cannot be detrended if it contains
%   NaN values. So typically the scientist will decide to replace NaN values with the nanmean value of the whole data set, or
%   with a zero. But either of these choices will artifically introduce a spike into the data, which adds a very broad noise
%   signal in the frequency domain. So a better choice (there is no perfect choice) is to detrend each continuous segment of
%   data between NaN values. This is called discontinuous detrending. Following this process, the mean of the data should be
%   zero. So the second step is to replace NaN values with zero. 
%
%   An alternative approach is to use linear interpolation to fill missing values, and then detrend the result, e.g.
%	w = fillgaps(w, 'interp');
%       w = detrend(w)
%

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
	% Check input is a waveform object
	if ~isa(w, 'waveform')
		warning('Not a waveform object')
		return
    end
    
    % Remove linear trend discontinuously, from one gap (NaN) to another
    for i=1:numel(w)
        data = get(w(i),'data');
        if size(find(~isnan(data))) > max([3 length(data)*0.2]) % at least 20% must be non-nan
    % Remove linear trend discontinuously, from one gap (NaN) to another
    for i=1:numel(w)
       nans = isnan(w(i)); %since logical,(1/8) memory footprint
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
            
            bp = find(isnan(data));
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
