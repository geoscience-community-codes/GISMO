function w = fillgaps(w,value, gapvalue)
% FILLGAPS - fill missing data with values of your choice
% W = fillgaps(W,number) fills data with the number of your choice
%   "number" can also be nan or inf or -inf
%
% W = fillgaps(W,[]) removes missing data from waveform.  Warning, the
%   resulting timing issues are NOT corrected for!
%
% W = fillgaps(W,'method') replaces data using an interpolation method of
% your choice. intended methods include:
% 'meanAll', 
% 'meanEndpoints'  CURRENTLY UNIMPLEMENTED.  
% or some such equivalent undreamed of by me.
%
% FILLGAPS is designed to replace NaN values.  However, if if you use
% W = fillgaps(W,number, gapvalue), then ALL data points with the value
% GAPVALUE will be replaced by NUMBER.
%

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 4/16/2008


if ~(isa(value,'numeric') && (isscalar(value) || isempty(value)) || ischar(value))
    warning('Waveform:fillgaps:invalidGapValue',...
        'Value to replace data with must be string or scalar or []');
end

if ~exist('gapvalue','var')
    gapvalue = nan;
end;

if (isnan(gapvalue))
    for N = 1:numel(w)
        if (isa(value,'numeric'))
            w(N).data(isnan(w(N).data)) = value;
        else
            switch upper(value)
                case 'MEANALL'
                    meanVal = mean(w(N));
                    if isnan(meanVal)
                       meanVal = 0; 
                    end
                    w(N).data(isnan(w(N).data)) = meanVal;
                otherwise
                    disp('unimplemented fillgaps method');
            end
        end
    end
else
    for N = 1:numel(w)
        if (isa(value,'numeric'))
            w(N).data(w(N).data == gapvalue) = value;
        else
            switch upper(value)
                case 'MEANALL'
                    %two step process so that we don't interfere with our
                    %own mean calculation.
                    w(N).data(w(N).data == gapvalue) = nan;
                    w(N).data(isnan(w(N).data)) = mean(w(N));
                otherwise
                    disp('unimplemented fillgaps method');
            end
                    
        end
    end
end
