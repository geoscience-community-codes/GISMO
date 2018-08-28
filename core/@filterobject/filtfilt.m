function w =filtfilt(f, w, NYQ)
%FILTFILT - filterobject implementation of FILTFILT, use on waveform Object
%   waveform = filtfilt(filterobject, waveform);
%   waveform = filtfilt(filterobject, data, NYQ);
%
%      'filtfilt' is a function that filters data at a specified
%      cutoff frequency with zero time shift.
%
%      INPUT values are as follows:
%        "filterobject" is a filter object
%        "waveform" is one or more waveform objects
%        "data" is any data vector (generally of type DOUBLE).
%        "NYQ" is the nyquist frequency
%
%
%  See also FILTFILT, BUTTER

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

% Check, if w is a number array, just quick & dirty it...
if isnumeric(w)
    WN = f.cutoff / NYQ;
    [b, a] = getButter(f,WN);
    w = filtfilt(b, a, w);
    
elseif isa(w,'waveform')
    % check for gaps
    HASGAP = 0;
    for n = 1:numel(w)
        if any(isnan(double(w(n))))
            HASGAP = 1;
        end
    end
    if HASGAP
        warning('Filterobject:filtfilt:hasNaN',...
            ['Waveform(s) contain data gaps (NaN values). This '...
            'will cause filtfilt to return an answer of all NaN.  To prevent '...
            'this, use waveform/fillgaps to replace NaN with an appropriate'...
            ' value.  \nSee help waveform/fillgaps.']);
        return
    end
    
    
    for n = 1 : numel(w);
        fnyq = get(w(n),'NYQ');
        if fnyq>0
            WN = f.cutoff / fnyq;     %only one filter is assumed!
            [b, a] = getButter(f,WN);
            w(n) = set(w(n),'data', filtfilt(b, a, double(w(n))) );
        else
            warning('Sampling rate is not set on this waveform. Use w = set(w, ''freq'', 100) to set to 100 Hz, for example. Cannot design a Butterworth filter')
            return
        end
    end
end


w = addhistory(w,['Filtered: Type:', get(f,'type'), ' Cutoff: [',...
    num2str(get(f,'cutoff')), '] Poles: [' , num2str(get(f,'poles')),']' ]);

%- - - -  helper function - - - - %
function [b, a] = getButter(f, WN)

switch f.type
    case 'H';
        [b,a] = butter(f.poles, WN, 'high');
    case 'B';
        [b,a] = butter(f.poles, WN);
    case 'L';
        [b,a] = butter(f.poles, WN);
end
