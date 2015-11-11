function w = medfilt1(w,size)

%MEDFILT1: Wrapper function for applying 1-D Median Filter (Signal 
%          Processing Toolbox) to waveform data
%
%USAGE: w = medfilt1(w,size)
%
%INPUTS: w    -  unfiltered waveform
%        size -  size of median window (data points)
%        
%OUTPUTS: w = median filtered waveform

% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

for n=1:numel(w)
    s = get(w(n),'start');
    d = get(w(n),'data');
    d = medfilt1(d,size);
    w(n) = set(w(n),'data',d);
    w(n) = set(w(n),'start',s);
end