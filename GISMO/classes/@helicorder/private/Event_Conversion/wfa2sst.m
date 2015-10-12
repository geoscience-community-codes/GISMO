function sst = wfa2sst(wfa)
%
%WFA2SST: Convert events from WAR form to SST form.
%      WFA - WaveForm Array form, events separated in nx1 waveform array
%          - (or) into 1xl cell array, each cell containing a nx1 waveform 
%          - array of events from a separate station/channel.
%      NAN - NaN form, (1xl waveform) for l station/channels with events in 
%            one time series w/ non-events = NaN. 
%      SST - Start/Stop Times form, nx2 array of matlab start/stop times
%            (or) 1xl cell array, each cell containing nx2 start/stop
%            times from a separate station/channel.
%
%USAGE: sst = wfa2sst(wfa)
%
%INPUTS: wfa - Events (WFA form)
%
%OUTPUTS: sst - Events (SST form)
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2NAN, SST2SSD, SST2VAL, 
% SST2WFA, WFA2NAN
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if iscell(wfa)
   for l = 1:numel(wfa)
      if ~isa(wfa{l},'waveform')
         error('Input must be a waveform object array')
      end
      for n = 1:numel(wfa{l})
         sst{l}(n,1) = get(wfa{l}(n),'start');
         sst{l}(n,2) = get(wfa{l}(n),'end');
      end
   end
else
   for n = 1:numel(wfa)
      sst(n,1) = get(wfa(n),'start');
      sst(n,2) = get(wfa(n),'end');
   end
end
