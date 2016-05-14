function ssd = sst2ssd(sst,w)
%
%SST2SSD: Convert events from SST form to SSD form.
%      WFA - WaveForm Array form, events separated in nx1 waveform array
%          - (or) into 1xl cell array, each cell containing a nx1 waveform 
%          - array of events from a separate station/channel.
%      NAN - NaN form, (1xl waveform) for l station/channels with events in 
%            one time series w/ non-events = NaN. 
%      SST - Start/Stop Times form, nx2 array of matlab start/stop times
%            (or) 1xl cell array, each cell containing nx2 start/stop
%            times from a separate station/channel.
%      SSD - Start/Stop Data form, nx2 array of start/stop data points
%            (or) 1xl cell array, each cell containing nx2 start/stop
%            data points from a separate station/channel.
%
%USAGE: ssd = sst2ssd(sst,w)
%
%INPUTS: w     - Waveform object that contains events
%        sst - Start/Stop Times (references w time vector)
%
%OUTPUTS: ssd - Start/Stop Data Points (references w) 
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2NAN, SST2VAL, SST2WFA,
%          WFA2NAN, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

tv = get(w,'timevector');
if iscell(sst)
   if numel(sst) == numel(w)
      for l=1:numel(sst)
         for n=1:size(sst{l},1)
            ssd{l}(n,:) = find(tv == sst{l}(n,:));
         end
      end
   else
      error(['ssd2sst:ArgumentDimensions - Number of elements in',...
             ' waveform input ''w'' and cell input ''ssd'' must match']);
   end
else
   for n=1:size(ssd,1)
      sst(n,:) = tv(ssd(n,:));
   end
end

find((tv >= sst(n,1)-10*eps)&&(tv <= sst(n,1)+10*eps))