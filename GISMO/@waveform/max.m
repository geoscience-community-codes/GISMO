function [Y, I] = max(w)
%MIN    Largest value of a waveform.
%   Y = max(waveform)
%   returns a scalar containing the minimum value of the waveform data
%   [Y, I] = max(waveform)
%
%   Input Arguments
%       WAVEFORM: waveform object   N-DIMENSIONAL
%
%   Output
%       Y: array of same shape as WAVEFORM, with each element corresponding
%          to the maximum value of each waveform
%       I: index(es) of Y within each waveform.
%
%   NOTE: If waveforms with no data are queried, Y and I will be NaN.  This
%   differs from the built-in version of min which returns an empty set.
%   This change allows max to be used for N-dimensional arrays of waveform
%   objects.
%
%   See also MAX, WAVEFORM/MIN, WAVEFORM/MEDIAN, WAVEFORM/MEAN, SORT.


% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/21/2008

Y = nan(size(w));
I = nan(size(w));
for n = 1 : numel(w);
    if isempty(w(n).data)
        warning('Waveform:max:noDataFound',...
            'no data in waveform #%d, index and value are set to NaN', n);
        continue
    end
    [Y(n), I(n)] = max(w(n).data);
end
