function val = get(c,prop_name)

% GET - Get correlation properties
%
% VAL = get(C,PROP_NAME)
% See HELP CORRELATION for description of primary property names:
%   Waveforms, Trig, Corr, Lag, Stat, Link, Clust
%   
% Additional scalar properties:
%   Traces:         number of traces
%   Data_Length:    number of samples in each trace
%   Fs:             Frequency
%   Period:         Period
%   Nyq:            Nyquist frequency
%   **NOTE - The scalar properties listed above exist for each waveform
%   (except Traces). However, the correlation object requires them to be
%   the same. GET only reads the value associated with the first waveform 
%   Normally this will not be an issue. If the correlation object
%   was created manually it is possible for these fields to be different.
%
% Additional vector properties (nx1):
%   Start, Trig, End:             same as Start_Matlab, End_Matlab
%   Start_Str, Trig_Str, End_Str:           String times
%   Start_Matlab, Trig_Matlab, End_Matlab:  Matlab-format times
%   Start_Epoch, Trig_Epoch, End_Epoch:     Epoch-format times
%
% Additional vector properties (nx1 cell vector)
%   Sta (or Station):       Cell vector of station names
%   Chan (or Component):    Cell vector of channel names
%
% Additional matrix properties (nxm matrix)
%   Data:                    Matrix of raw trace data
%                           (n traces) x (m samples)         

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

error('using NewCorrelation/get')
if nargin <= 1
    error('Not enough inputs');
end

% got rid of test for c
                       
switch upper(prop_name)
    case {'WAVEFORMS', 'WAVEFORM', 'WAVES'}
        val = c.W;
    case {'TRIG'}
        val = c.trig;
    case {'TRIG_STR'}
        val = cellstr(datestr(c.trig,'dd-mmm-yyyy HH:MM:SS.FFF'));
    case {'TRIG_MATLAB'}
        val = c.trig;
    case {'CORR'}
        val = c.corrmatrix;
    case {'LAG'}
        val = c.lags;
    case {'STAT'}
        val = c.stat;
    case {'LINK'}
        val = c.link;
    case {'CLUST'}
        val = c.clust;
    case {'TRACES'}
        val = size(c.W,1);
        
    % FROM WAVEFORM/GET (SCALAR OUTPUT)
    case {'DATA_LENGTH'}
       val = c.traces(1).nsamples();
    case {'FS'}
       val = c.traces(1).samplerate;
        
%     % FROM WAVEFORM/GET (VECTOR)
    case {'STATION', 'STA'}
        val = {c.traces.station};
    case {'COMPONENT', 'CHAN'}
        val = {c.traces.channel};

 % OTHER ROUTINES
    case {'DATA'}
        val = double(c.traces);
        
    otherwise
        try 
            % see if it is a valid waveform property
            val = get(c.W,prop_name);
        catch
            error([upper(prop_name) ' is not a valid argument for correlation/get']);
        end
end;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECKVALS
% This function checks to see if each waveform has the same parameters

function checkvals(vals)

same = all(vals(:) == vals(1));

if ~same
    % Warning is disabled because it gets called repeatedly (annoyingly)
    % from within other scripts
    % warning('Waveforms have different frequencies or different numbers of samples. Consider VERIFY function');
end;
end

