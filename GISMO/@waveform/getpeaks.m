function peakmask = getpeaks(w)
%GETPEAKS return mask for peak values for a waveform
%     PEAKMASK = GETPEAKS(WAVEFORM)
%     returns a mask of all maximums in the waveform.
%
%   Input Arguments
%       WAVEFORM: waveform object  (SINGLE WAVEFORM)
%
%   Output
%       PEAKMASK: a mask of all local maximums within the waveform.
%       This mask can then be used to reference the peak points in a
%       waveform
%
%   a MASK is a logical array the same size as the waveform's data,
%   where the value is TRUE when that data point is a peak, and is zero
%   otherwise.
%
%   in some cases, it may be preferable to get the peakmask for the
%   absolute value of the data, that way both highs and lows are marked.
%
% See also WAVEFORM/HILBERT

% 10/21/2005 - Completely changed.  If you need the original, let me know...

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/6/2007

if ~isscalar(w)
    error('Waveform:getpeaks:tooManyWaveforms',...
      'getpeaks can only be used with individual waveforms');
end
myData = get(w,'data');
BiggerLeft = [(myData(1:end-1) >= myData(2:end)); true];
BiggerRight = [true ; (myData(1:end-1) < myData(2:end))];
peakmask = (BiggerLeft & BiggerRight);