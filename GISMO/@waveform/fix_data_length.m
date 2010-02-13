function w = fix_data_length(w, maxlen)
%FIX_DATA_LENGTH adjust length of waveform data to allow batch processing
%   waveform = fix_data_length(waveform)
%       adjusts all waveforms to the length of the largest, while
%       zero-padding all shorter waveforms
%
%   waveform = fix_data_length(waveform, maxlength)
%       sets all waveform lengths to maxlength.  This use of the function
%       has been superceeded by set(waveform,'samplelength',maxlength);
%        
%  examples
%       % let inWaves be a 1x2 waveform object
%       % 3000 samples in inWaves(1)
%       % 10025 samples in inWaves(2)
%
%       % set both waves' data to a length of to 10025 while padding the 
%       % smaller of the two with zeroes.
%       outWaveforms = fix_data_length(inWaves) 
%
%       % set both sample lengths to 500 truncating both of them...
%       outWaveform = fix_data_length(inWaves, 500) 
%
%       %The above example is nearly the same as
%       outWaveform = set(inWaves,'sample_length',500)
%
%       Behaviorally, this differs from the set command because it
%       automatically determines the maximum desired length, when not
%       specified.
%
%
% See also WAVEFORM/EXTRACT, WAVEFORM/DOUBLE, WAVEFORM/SET -- Sample_Length 

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

Wcount = numel(w);

if ~exist('maxlen','var')
    m(Wcount) = 0;
    for j = Wcount : -1 : 1
        m(j) = numel(w(j).data);
    end
    maxlen = max(m);
end

if length(maxlen) == 2
    st = maxlen(1);
    ed = maxlen(2);
else
    st = 1;
    ed = maxlen(end);
end

for j = 1 : Wcount
    D = w(j).data;
    if ed > numel(D)
        D(ed) = 0;
    else
        D = D(st:ed);
    end
    w(j) = set(w(j),'data',D);
end;
