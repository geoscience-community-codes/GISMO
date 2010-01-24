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
%   See also MEAN, WAVEFORM/MIN, WAVEFORM/MAX, WAVEFORM/MEDIAN, SORT.

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/21/2008

y = nan(size(w));
for I = 1 : numel(w);
    data_to_mean = get(w(I),'data');
    data_to_mean = data_to_mean(~isnan(data_to_mean)); %ignore NaN values
    if ~isempty(data_to_mean)
        y(I) = mean( data_to_mean );
    end
end
