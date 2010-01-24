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
%   See also MEDIAN, WAVEFORM/MIN, WAVEFORM/MAX, WAVEFORM/MEAN, SORT.

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/21/2008

y = zeros(size(w));
for I = 1 : numel(w);
    data_to_med = get(w(I),'data');
    data_to_med = data_to_med(~isnan(data_to_med));
    if isempty(data_to_med)
        warning('Waveform:median:noDataFound',...
            'no data in waveform #%d',I);
    end
    y(I) = median(data_to_med);
end
