function nan = wfa2nan(wfa, varargin)
%
%WFA2NAN: Convert events from WFA form to NAN form.
%      WFA - WaveForm Array form, events separated in nx1 waveform array
%          - (or) into 1xl cell array, each cell containing a nx1 waveform 
%          - array of events from a separate station/channel.
%      NAN - NaN form, (1xl waveform) for l station/channels with events in 
%            one time series w/ non-events = NaN. 
%      SST - Start/Stop Times form, nx2 array of matlab start/stop times
%            (or) 1xl cell array, each cell containing nx2 start/stop
%            times from a separate station/channel.
%
%USAGE: nan = wfa2nan(wfa)
%        ...Output nan waveforms extend from the first to the last
%        ...events in wfa, separated by NaN values.
%       nan = wfa2nan(wfa,w)
%        ...Output nan waveforms extend from the beginning to the end
%        ...of w
%       
%INPUTS: wfa - Waveform event array (1xl cell of nx1 event waveforms)
%        w   - Reference waveform, nan timevector will match w
%
%OUTPUTS: nan - Event/NaN waveforms (1xl waveforms)
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2NAN, SST2SSD, SST2VAL, 
%          SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if nargin == 1
   w = waveform();
elseif nargin == 2
   w = varargin{1};
end

if iscell(wfa)
   if numel(wfa) == numel(w)
      for l = 1:numel(wfa)
         nan(l) = WFA2NAN(wfa{l},w(l));
      end
   else
      error(['wfa2nan:ArgumentDimensions - Number of elements in',...
             ' waveform input ''w'' and cell input ''wfa'' must match']);
   end
else
   nan = WFA2NAN(sst,w);
end

function nan = WFA2NAN(wfa,w)

for n=1:length(wfa)
   if isempty(wfa(n))
      wfa(n)=[];
   end
end
nan = combine(wfa);  

if ~isempty(w)
   ts1 = get(w, 'start');
   ts2 = get(nan, 'start');
   te1 = get(nan, 'end');
   te2 = get(w, 'end');
   
   if ts1 < ts2
      pad_s = extract(w, 'time',ts1,ts2);
   else
      pad_s = [];
   end
   
   if te2 > te1
      pad_e = extract(w, 'time',te1,te2);
   else
      pad_e = [];
   end
   
   nan = [NaN*pad_s nan NaN*pad_e];
   nan = combine(nan);
end

