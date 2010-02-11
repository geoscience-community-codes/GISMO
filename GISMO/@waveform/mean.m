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
for I = 1 : numel(w);
        y(I) = nanmean( get(w(I),'data') );
end
