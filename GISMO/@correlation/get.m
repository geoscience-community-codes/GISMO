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


if nargin <= 1
    error('Not enough inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First argument must be a correlation object');
end

                       
switch upper(prop_name)
    case {'WAVEFORMS'}
        val = c.W;
    case {'WAVEFORM'}
        val = c.W;
    case {'WAVES'}
        val = c.W;
    case {'TRIG'}
        val = c.trig;
    case {'TRIG_STR'}
        val = cellstr(datestr(c.trig,'dd-mmm-yyyy HH:MM:SS.FFF'));
    case {'TRIG_MATLAB'}
        val = c.trig;
    case {'TRIG_EPOCH'}
        disp('TRIG_EPOCH property not currently implimented');
    case {'CORR'}
        val = c.C;
    case {'LAG'}
        val = c.L;
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
        vals = get(c.W,'DATA_LENGTH');  
        checkvals(vals);
        val = vals(1);   
    case {'FS'}
        vals = get(c.W,'FS');  
        checkvals(vals);
        val = vals(1);
    case {'PERIOD'}
        val = get(c.W(1),'PERIOD');
    case {'NYQ'}
        val = get(c.W(1),'NYQ');

    % FROM WAVEFORM/GET (VECTOR)
    case {'STATION'}
        val = get(c.W,'STATION');
    case {'STA'}
        val = get(c.W,'STATION');
    case {'COMPONENT'}
        val = get(c.W,'COMPONENT');
    case {'CHAN'}
        val = get(c.W,'COMPONENT');        

    case {'START'}
        val = get(c.W,'START_MATLAB');
    case {'END'}
        val = get(c.W,'END_MATLAB');
 
    case {'START_STR'}
        val = get(c.W,'START_STR');
    case {'START_MATLAB'}
        val = get(c.W,'START_MATLAB');
    case {'START_EPOCH'}
        val = get(c.W,'START_EPOCH');

    case {'END_STR'}
        val = get(c.W,'END_STR');
    case {'END_MATLAB'}
        val = get(c.W,'END_MATLAB');
    case {'END_EPOCH'}
        val = get(c.W,'END_EPOCH');
     
    case {'DURATION_STR'}
        val = get(c.W,'DURATION_STR');
    case {'DURATION_MATLAB'}
        val = get(c.W,'DURATION_MATLAB');
    case {'DURATION_EPOCH'}
        val = get(c.W,'DURATION_EPOCH');    

 % OTHER ROUTINES
    case {'DATA'}
        val = double(c.W);
        
        
    otherwise
        error([upper(prop_name) ' is not a valid argument for correlation/get']);
end;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECKVALS
% This function checks to see if each waveform has the same parameters

function checkvals(vals)

same = 1;
for i = 2:length(vals)
    if vals(i) ~= vals(1)
        same = 0;
    end;
end;
if ~same
    % Warning is disabled because it gets called repeatedly (annoyingly)
    % from within other scripts
    % warning('Waveforms have different frequencies or different numbers of samples. Consider VERIFY function');
end;


