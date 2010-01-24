function s = spectralobject(anyV,overlap,freqmax,dBlims, scaling)
%SPECTRALOBJECT - spectralobject class constructor
%      Ways to call...
%      s = SPECTRALOBJECT() creates a spectralobject from scratch
%      s = SPECTRALOBJECT(spectralobject) clones a spectralobject
%      s = SPECTRALOBJECT(nfft, overlap, freqmax, dBlims)
%            manually puts together a spectralobject object
% 
%      SPECTRALOBJECT - an existing spectral object
%      NFFT - Fourier transform window               (default [1024])
%      OVERLAP - how much of the window to overlap   (default [NFFT * 0.8])
%      FREQMAX - how high a freq to display          (default [8])
%      DBLIMS - dB range over which to display data  (default [50 100])
%      SCALING - 's', 'm', 'h', 'date': x axis scale (default 's' (second))
%      to get default value, use []

% VERSION: 1.1 of spectralobject
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 5/29/2007

load_global_namespace;

Default_lims = [50 100];

switch nargin
    case 0
        %create a fresh spectralobject
        s.nfft = 1024;
        s.over = s.nfft * 0.8;
        s.freqmax = 8; %
        s.dBlims = Default_lims;
        s.scaling = 'm';
        s = class(s, 'spectralobject');
    case 1
        if isa(anyV, 'spectralobject')
            s = anyV;
        end
    case {4,5}
        % Building a spectralobject from input peices

        s = spectralobject; %create a default spectralobject
        
        if ~isempty(anyV)
            s = set(s,'nfft',anyV);
        end
        
        if ~isempty(overlap)
            s = set(s,'overlap',overlap);
        end
        
        if ~isempty(freqmax)
            s = set(s,'freqmax',freqmax);
        end
        
        if ~isempty(dBlims)
            s = set(s,'dblims',dBlims);
        end
        
        if exist('scaling','var')
            s = set(s,'scaling',scaling);
        end
        
    otherwise
        error('Invalid arguments in spectralobject constructor');
end;



%% LOAD spectralobject's global_namespace

function load_global_namespace()

persistent SPECTRALOBJECT_NAMESPACE

if SPECTRALOBJECT_NAMESPACE
    return
else
    SPECTRALOBJECT_NAMESPACE = true;
end

global SPECTRAL_MAP
% The spectral plotting routines use the color scheme defined in
% a variable SPECTRAL_MAP.  This variable is saved (ascii style)
% in a file called "spectral.map", accessable from your work directory.
%
% If this file doesn't exist, it will generate the internal map as
% defined below.

if exist('spectral.map','file')
    SPECTRAL_MAP = load('spectral.map','-ascii');
else
    % P.S.  this used to be "jackie.map"
    SPECTRAL_MAP =[0         0    0.5625
        0         0    0.6250
        0         0    0.6875
        0         0    0.7500
        0         0    0.8125
        0         0    0.8750
        0         0    0.9375
        0         0    1.0000
        0    0.0625    1.0000
        0    0.1250    1.0000
        0    0.1875    1.0000
        0    0.2500    1.0000
        0    0.3125    1.0000
        0    0.3750    1.0000
        0    0.4375    1.0000
        0    0.5000    1.0000
        0    0.5625    1.0000
        0    0.6250    1.0000
        0    0.6875    1.0000
        0    0.7500    1.0000
        0    0.8125    1.0000
        0    0.8750    1.0000
        0    0.9375    1.0000
        0    1.0000    1.0000
        0.0625    1.0000    1.0000
        0.1250    1.0000    0.9375
        0.1875    1.0000    0.8750
        0.2500    1.0000    0.8125
        0.3125    1.0000    0.7500
        0.3750    1.0000    0.6875
        0.4375    1.0000    0.6250
        0.5000    1.0000    0.5625
        0.5625    1.0000    0.5000
        0.6250    1.0000    0.4375
        0.6875    1.0000    0.3750
        0.7500    1.0000    0.3125
        0.8125    1.0000    0.2500
        0.8750    1.0000    0.1875
        0.9375    1.0000    0.1250
        1.0000    1.0000         0
        1.0000    0.9375         0
        1.0000    0.8750         0
        1.0000    0.8125         0
        1.0000    0.7500         0
        1.0000    0.6875         0
        1.0000    0.6250         0
        1.0000    0.5625         0
        1.0000    0.5000         0
        1.0000    0.3750         0
        1.0000    0.2500         0
        1.0000    0.1250         0
        1.0000         0         0
        0.9375         0    0.6375
        0.9375    0.1500    0.9375
        1.0000    0.8000    1.0000];
end
