function nan = sst2nan(sst,w)
%
%EVENT_SST2NAN: Convert events from SST form to NAN form.
%      WFA - WaveForm Array form, events separated in 1xn waveform array
%          - (or) into 1xm cell array, each cell containing a 1xn waveform 
%          - array of events from a separate station/channel.
%      NAN - NaN form, (1xm waveform) for m station/channels with events in 
%            one time series w/ non-events = NaN. 
%      SST - Start/Stop Times form, nx2 array of matlab start/stop times
%            (or) 1xm cell array, each cell containing nx2 start/stop
%            times from a separate station/channel.
%
%USAGE: nan = sst2nan(w, sst)
%
%INPUTS: w       - Waveform object that contains events
%        times   - Events times (nx2 double)
%
%OUTPUTS: nan - Event in NaN form
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2SSD, SST2VAL, SST2WFA,
%          WFA2NAN, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if iscell(sst)
   if numel(sst) == numel(w)
      for m = 1:numel(sst)
         nan(m) = SST2NAN(sst{m},w(m));
      end
   else
      error(['sst2nan:ArgumentDimensions - Number of elements in',...
             ' waveform input ''w'' and cell input ''sst'' must match']);
   end
else
   nan = SST2NAN(sst,w);
end

function nan = SST2NAN(sst,w)
for n=1:size(sst,1)
   wfa(n) = extract(w,'time',sst(n,1),sst(n,2));
end
if isempty(sst)
   nan = w*NaN;
else   
nan = combine(wfa);
ts1 = get(w, 'start');
ts2 = get(nan, 'start');
te1 = get(nan, 'end');
te2 = get(w, 'end');
pad_s = extract(w, 'time',ts1,ts2);
pad_e = extract(w, 'time',te1,te2);
nan = [NaN*pad_s nan NaN*pad_e];
nan = combine(nan);
end