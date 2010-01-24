function f = filterobject(anything, cutoff, poles)
% FILTEROBJECT constructor for a filter object
%   f = filterobject() creates a new default filterobject
%   f = filterobject(filterobject) duplicates a filterobject
%   f = filterobject(type, cutoff, poles) create user-defined filterobject
%
%   TYPE:  'B' : Bandpass, 'H' : Highpass, 'L' : Lowpass
%   CUTOFF: [low, high] for bandpass, single value for others
%   POLES: number of poles used in the filter
%
%   default new object: Bandpass from 0.8 Hz to 5Hz, 2 poles (as dictated
%   by this constructor file

% VERSION: 1.0 of filter objects
% AUTHOR: Celso Reyes
% LASTUPDATE: 1/30/2007

load_global_namespace;

switch nargin
    case 0
            %create a fresh filterobject
            f.type = 'B';
            f.cutoff = [0.8 5];
            f.poles = 2;
            f = class(f, 'filterobject');

    case 1
        if isa(anything, 'filterobject')
            f = anything;
        else
            error(['trying to use filterobject(' class(anything) ')']);
        end
        
    case 3
        f = filterobject;
        f = set(f,'type',anything, 'cutoff', cutoff,'poles',poles);

    otherwise
        disp('Invalid arguments in filterobject constructor');
end;

%% LOAD filterobject's global namespace
% replaces SUITE_STUFF
function load_global_namespace()

persistent FILTER_NAMESPACE

if FILTER_NAMESPACE
    return
else
    FILTER_NAMESPACE = true;
end
% 
% global FILTER_LONG 
% global FILTER_STANDARD
% 
% FILTER_LONG = filterobject('L',0.999,2);
% FILTER_STANDARD = filterobject('B', [0.8 5.0] ,2);