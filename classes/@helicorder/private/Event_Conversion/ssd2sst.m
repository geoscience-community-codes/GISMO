function sst = ssd2sst(ssd,w)
%
%SSD2SST: Convert events from SSD form to SST form.
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
%USAGE: sst = ssd2sst(ssd,w)
%
%INPUTS: w     - Waveform object that contains events
%        ssd   - Start/Stop Data Points (references w) 
%
%OUTPUTS: sst - Start/Stop Times (references w time vector)
%
% See also NAN2SST, NAN2WFA, SST2NAN, SST2SSD, SST2VAL, SST2WFA,
%          WFA2NAN, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

tv = get(w,'timevector');
if iscell(ssd)
   if numel(ssd) == numel(w)
      for l=1:numel(ssd)
         for n=1:size(ssd{l},1)
            sst{l}(n,:) = tv(ssd{l}(n,:));
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


   

