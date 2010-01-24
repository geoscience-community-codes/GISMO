function w = detrend (w, varargin)
%DETREND remove linear trend from a waveform
%   waveform = detrend(waveform, [options])
%   removes the linear trend from the waveform object(s).

%   Input Arguments
%       WAVEFORM: a waveform object   N-DIMENSIONAL
%       OPTIONS: optional parameters as described in matlab's DETREND
%
%  WARNING: Detrending a waveform with NAN values will return a waveform
%  with nothing but NAN values.   Replace NaN values before detrending.
%  "demean", however, works fine but only removes constant offsets.
%
% See also DETREND for list of options

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

Nmax = numel(w);
warnedAboutNAN = false;
for I = 1 : Nmax
    
    if isempty(w(I)), continue, end
    
    d = get(w(I),'data');
    if ~warnedAboutNAN && any(isnan(d))
      warnedAboutNAN = true;
      warning('Waveform:detrend:NaNwarning',...
        ['NAN values exist in one or more waveforms.',...
        '  Detrend will return values of NAN\n',...
        'One possible way to correct this problem is to use FILLGAPS ',...
        'to replace NAN values prior to detrending\n',...
        '  "demean", however, should work fine.']);
    end
        
    w(I) = set(w(I),'data',detrend(d,varargin{:}));
end

w = addhistory(w,'trend removed');