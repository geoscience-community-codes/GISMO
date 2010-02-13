function w = clip(w, vals)
%CLIP clips a waveform's data at a particular max/min value range
%   waveform = clip(waveform, values)
%
%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       VALUES: a number.  If a scalar, then amplitudes will be
%           clipped at +/- value.  If a pair, eg. [Max, Min] then 
%           waveform will be clipped between these two values
%
%   All values beyond maximum ranges will be set to the maximum range
%
%
% See also  WAVEFORM/DESPIKE

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if nargin < 2,
    vals = [];
end

switch numel(vals)
    case 0
        warning('Waveform:clip:noClipValue',...
            'No values given, waveform remains unclipped');
        return

    case 1 % clip at +/- input value
        if ~isnumeric(vals)
          error('Waveform:clip:invalidClipValue','Non-numeric clip value'); 
        end
        vals = abs(vals);
        disp(['Clipping at +/- ' num2str(vals)]);
        vals = [-vals vals];
        
    case 2
        if ~isnumeric(vals)
          error('Waveform:clip:invalidClipValue','Non-numeric clip value'); 
        end
        if vals(1) > vals(2)
            warning('Waveform:clip:reversedValues',...
                'Value1 %f > Value2 %f , Reversing', vals(1),vals(2));
            vals = vals([2 1]);            
        end
        %everything is AOK
    otherwise
        warning('Waveform:clip:invalidClipValue',...
            'Invalid clip values. waveform remains unclipped. specify [min max] values');
        return
end

for N = 1: numel(w)
    d = w(N).data;
    d(d < vals(1)) = vals(1);
    d(d > vals(2)) = vals(2);
    w(N).data = d;
end


w = addhistory(w,...
    ['Clipped between ', num2str(vals(1)), ' and ', num2str(vals(2))] );
