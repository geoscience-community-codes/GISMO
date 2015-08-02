function y = mean(w)
%MEAN Average or mean value of waveform's data.
%   Y = mean(waveform)
%   returns a scalar containing the mean value of the waveform data
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       Y: array of same size as WAVEFORM, with each element corresponding
%          to the mean value of the matching waveform
%
%   NOTE: Values of NaN are ignored.
%
%   See also NANMEAN, WAVEFORM/MIN, WAVEFORM/MAX, WAVEFORM/MEDIAN, SORT.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

y = nan(size(w));
% if the statistics toolbox is installed, use the builtin nanmean function
% to ignore NaN values during the variance calculation.
if ~isempty(ver('stats'))
    for I = 1 : numel(w);
        y(I) = nanmean( w(I).data );
    end
else
    % the statistics toolbox is not installed, so any nan values will have
    % to be dealt with (ignored) manually.
    for I = 1 : numel(w);
        d = w(I).data;
        d = d(~isnan(d)); %ignore NaN values
        if ~isempty(d)
            y(I) = mean( d );
        end
    end
end
