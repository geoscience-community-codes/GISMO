function wfa = sst2wfa(sst,w)
%
%SST2WFA: Convert events from SST form to WFA form.
%      WFA - WaveForm Array form, events separated in nx1 waveform array
%          - (or) into 1xl cell array, each cell containing a nx1 waveform 
%          - array of events from a separate station/channel.
%      NAN - NaN form, (1xl waveform) for l station/channels with events in 
%            one time series w/ non-events = NaN. 
%      SST - Start/Stop Times form, nx2 array of matlab start/stop times
%            (or) 1xl cell array, each cell containing nx2 start/stop
%            times from a separate station/channel.
%
%USAGE: wfa = sst2wfa(sst)
%
%INPUTS: w    - Waveform object that contains events
%        sst  - Events (WFA form)   
%
%OUTPUTS: wfa - Events (WFA form)
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2NAN, SST2SSD, SST2VAL,
%          WFA2NAN, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if iscell(sst)
   if numel(sst) == numel(w)
      for l=1:numel(sst)
         for n=1:size(sst{l},1)
            wfa{l}(n) = extract(w,'time',sst{l}(n,1),sst{l}(n,2));
         end
      end
   else
      error(['sst2nan:ArgumentDimensions - Number of elements in',...
             ' waveform input ''w'' and cell input ''sst'' must match']);
   end
else
   for n=1:size(sst,1)
      wfa(n) = extract(w,'time',sst(n,1),sst(n,2));
   end
end


   

