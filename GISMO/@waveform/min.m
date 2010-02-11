function [Y, I] = min(w)
%MIN    Smallest value of a waveform.
%   Y = min(waveform)
%   returns a scalar containing the minimum value of the waveform data
%   [Y, I] = 
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       Y: array of same size as WAVEFORM, with each element corresponding
%          to the median value of the matching waveform
%       I: index(es) of Y within each waveform.
%
%   NOTE: If waveforms with no data are queried, Y and I will be NaN.  This
%   differs from the built-in version of min which returns an empty set.
%   This change allows min to be used for N-dimensional arrays of waveform
%   objects.
%
%   See also MIN, WAVEFORM/MAX, WAVEFORM/MEDIAN, WAVEFORM/MEAN, SORT.


% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

Y = nan(size(w));
I = nan(size(w));
for n = 1 : numel(w);
    if isempty(w(n).data)
        warning('Waveform:min:noDataFound',...
            'no data in waveform #%d, index and value are set to NaN', n);
        continue
    end
    [Y(n), I(n)] = min(w(n).data);
end
