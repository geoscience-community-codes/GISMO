function y = median(w)
%MEDIAN middlemost value of waveform's sorted data.
%   Y = median(waveform)
%   returns a scalar containing the median value of the waveform data
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       Y: array of same size as WAVEFORM, with each element corresponding
%          to the median value of the matching waveform
%
%   NOTE: NAN values are ignored
%
%   See also NANMEDIAN, WAVEFORM/MIN, WAVEFORM/MAX, WAVEFORM/MEAN, SORT.

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

y = zeros(size(w));
%if the statistics toolbox is installed, use the builtin nanmedian function
%to ignore NaN values during the variance calculation.
if ~isempty(ver('stats'))
    for I = 1 : numel(w);
        y(I) = nanmedian(w(I).data);
    end
    
else
    % the statistics toolbox is not installed, so any nan values will have
    % to be dealt with (ignored) manually.
    for I = 1 : numel(w);
        d = w(I).data;
        %data_to_med = data_to_med(~isnan(data_to_med));
        y(I) = median(d(~isnan(d)));
    end
end