function w = sst2val(sst,w,val)

%SST2VAL: Set sections of waveform w to single value. Useful for setting
%  data gaps, noise, or other unwanted waveform sections to 0 or NaN for
%  event detection, rms calculation, display purposes, etc.
%
%USAGE: w = set2val(sst,w,val)
%
%INPUTS: sst - Start/Stop Times (nx2 array of matlab times)
%        w   - Waveform object that contains sections to delete
%        val - Numeric value used to replace waveform data in sst
%
%OUTPUTS: w - Original waveform with sst set to val
%
% See also NAN2SST, NAN2WFA, SSD2SST, SST2NAN, SST2SSD, SST2WFA,
%          WFA2NAN, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

%%
if isempty(sst)|| iscell(sst) && isempty(sst{:})
   return
end
if iscell(sst)
   if numel(sst) == numel(w)
      for l = 1:numel(sst)
         w(l) = SST2VAL(sst{l},w(l),val);
      end
   else
      error(['SST2VAL:ArgumentDimensions - Number of elements in',...
             ' waveform input ''w'' and cell input ''sst'' must match']);
   end
else
   w = SST2VAL(sst,w,val);
end

%%
function w = SST2VAL(sst,w,val)
nn = size(sst,1);

for n=1:nn
   if n == 1
      wfa(n) = extract(w,'time',get(w,'start'),sst(n,1));
      r_wfa(n) = extract(w,'time',sst(n,1),sst(n,2));
      r_wfa(n) = (r_wfa*0+1)*val;
      wfa(n) = combine([wfa(n) r_wfa(n)]);
   else
      wfa(n) = extract(w,'time',sst(n-1,2),sst(n,1));
      r_wfa(n) = extract(w,'time',sst(n,1),sst(n,2));
      r_wfa(n) = (r_wfa(n)*0+1)*val;
      wfa(n) = combine([wfa(n) r_wfa(n)]);
   end
end
wfa(nn+1) = extract(w,'time',sst(nn,2),get(w,'end'));
w = combine(wfa(:));
