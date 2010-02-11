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
for I = 1 : numel(w);
    y(I) = nanmedian(get(w(I),'data'));
end
