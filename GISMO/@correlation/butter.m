function c = butter(c,varargin)

% C = BUTTER(C,[TYPE],CUTOFF,[POLES])
% This function creates and applies a butterworth filter to each waveform
% in the correlation object. The function returns a correlation object.
% Filtering is performed by an underlying call to the filterobject/filtfilt
% routine. Note that filtfilt applies the filter once in each direction to
% minimize phase distortion (effectively a zero-phase filter). This also
% has the effect of doubling the order of the filter. 2 or 4 poles should
% be sufficient for most applications.
%
% EXAMPLES:
%  c = BUTTER(c,[1 5])            band pass filter on 1-5 Hz (4 poles)
%  c = BUTTER(c,'B',[1 5])        same as previous example
%  c = BUTTER(c,'L',5)            low  pass filter below 5 Hz (4 poles)
%  c = BUTTER(c,'H',1)            high pass filter above 5 Hz (4 poles)
%  c = BUTTER(c,...,2)            use 2 poles

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% TODO: should check to ensure low cutoff period is >> trace length

% GET INPUTS
if isa(varargin{1},'char')       % set filter type
    type = varargin{1};
    varargin = varargin(2:end);
else
    type = 'B';
end
 
cutoff = varargin{1};            % set cutoff frequencies

if length(varargin)>1
   poles = varargin{2};
else
    poles = 4;                  % set number of poles
end


% CHECK FIRST LETTER OF FILTER TYPE
type = upper(type(1));
if (type~='B') && (type~='H') && (type~='L')
    error('Filter type not recognized')
end;


% CHECK NUMBER OF CUTOFF FREQUENCIES
if type=='B'
    if length(cutoff)~=2
        error('Two cutoff frequecies needed for bandpass filter')
    end;
else
    if length(cutoff)~=1
        error('High and lowpass filters require one cutoff frequency')
    end;        
end;
        

% CHECK FREQUENCY RANGE
if cutoff(end) >= get(c,'NYQ')
    error('Frequency cutoffs exceed the Nyquist frequency')
end;
  
% duration = get(c,'DURATION_EPOCH');
% if 1/cutoff(1) >= duration(1)
%     warning('Frequency cutoff is very low relative to trace length');
% end;  
% uration(1)
% 1/cutoff(1)


        
% APPLY FILTER
f = filterobject(type,cutoff,poles);
c.W = filtfilt(f,c.W);



