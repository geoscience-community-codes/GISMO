function out = stack(w)
%STACK stacks data from array of waveforms
%   StackedWave = stack(waveforms)
%   ASSUMES frequencies are the same. data does not need to be the same
%   length, but shorter waveforms will be padded with zeros at the end
%   prior to stacking.
%
%   Stacks all waves, regardless of waveform's dimension
%
%   Data is summed, but the average is not taken, nor is it normalized. You
%   may wish to change the station and/or channel names to reflect the
%   properties of this waveform.  Possibly change the units, also, if that
%   makes sense.
%
%   Output retains the same info as the very first waveform (minus history)
%   the station name becomes the original name with "- stack" tacked onto
%   the end.
%
%
%   To ensure frequency and time matching, use ALIGN
%
%   See also WAVEFORM/ALIGN

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/15/2009

out = w(1);
out = set(out,'station',[get(out,'station') ' - stack']);
out = set(out,'data',sum(double(w),2));
out = clearhistory(out);
out = addhistory(out,['Stack of ', num2str(numel(w)), 'waveforms']);
