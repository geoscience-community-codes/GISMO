function val = get(TC,varargin)

%GET    Get threecomp object properties.
%   V = GET(TC,'PropertyName') returns the value of the specified
%   property for the threecomp object specified by TC. Allowable properties
%   include:
%   WAVEFORM          waveform object containing the three component traces
%   BACKAZIMUTH       backazimuth to source
%   RECTILINEARITY    rectilinearity stored in a waveform object
%   PLANARITY         stored in a waveform object
%   ENERGY            energy stored in a waveform object
%   AZIMUTH           azimuth stored in a waveform object
%   INCLINATION       inclination stored in a waveform object
% See also threecomp object

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% Check inputs
if ~isa(TC,'threecomp')
    error('First argment must be a threecomp object');
end
if nargin~=2
    error('Incorrect number of arguments');
end
property = varargin{1};
if ~isa(property,'char')
    error('Second argument must be a character string');
end


[objSize1,objSize2] = size(TC);
numObj = numel(TC);

% Prepare property values
switch upper(property)
    
    case 'WAVEFORM'
        if numObj==1
            val = TC.traces;
        elseif objSize1>1 && objSize2==1
            for n = 1:numObj
                val(n,1:3) = TC(n).traces;
            end
        elseif objSize2>1
            for n1 = 1:objSize1
                for n2 = 1:objSize2
                    val(n1,n2,1:3) = TC(n).traces;
                end
            end
        else
            error('threecomp object is not 1x1, nx1, or nxm in size');
        end
        
    case 'TRIGGER'
        for n = 1:numObj
           val(n) = TC(n).trigger;
        end
        val = reshape(val,objSize1,objSize2);

    case 'BACKAZIMUTH'
        for n = 1:numObj
            if isempty(TC(n).backAzimuth)
                val(n) = NaN;
            else
                val(n) = TC(n).backAzimuth;
            end
        end
        val = reshape(val,objSize1,objSize2);
    case 'NSCL'
        for n = 1:numObj
            w = TC(n).waveform;
            net = get(w(1),'NETWORK');
            sta = get(w(1),'STATION');
            chan = get(w,'CHANNEL');
            chanString = [chan{1}(1:2) '[' chan{1}(3) chan{2}(3) chan{3}(3) ']' ];
            loc = get(w(1),'LOCATION');
            val(n) = {[net '_' sta '_' chanString '_' loc]};
        end
        val = reshape(val,objSize1,objSize2);
    case 'STATION'
        for n = 1:numObj
            w = TC(n).waveform;
            val(n) = {get(w(1),'STATION')};
        end
        val = reshape(val,objSize1,objSize2);
    case 'CHANNEL'
        for n = 1:numObj
            w = TC(n).waveform;
            val(n) = {get(w,'CHANNEL')};
        end
        val = reshape(val,objSize1,objSize2);  
    case 'TYPE'
        for n = 1:numObj
            val(n) = gettype(TC(n));
        end
        val = reshape(val,objSize1,objSize2);
    
    case 'COMPLETENESS'
        for n = 1:numObj
            val(n) = getcompleteness(TC(n));
        end
        val = reshape(val,objSize1,objSize2);
        
    case 'ORIENTATION'
        for n = 1:numObj
            vals = TC(n).orientation;
            if isempty(vals)
               vals = [NaN NaN NaN NaN NaN NaN]; 
            end
            val(n,1:6) = vals;
        end  
    case 'RECTILINEARITY'
        for n = 1:numObj
            if isempty(TC(n).rectilinearity)
                val(n) = waveform;
            else
                val(n) = TC(n).rectilinearity;
            end
        end
        val = reshape(val,objSize1,objSize2);
    
    case 'PLANARITY'
        for n = 1:numObj
            if isempty(TC(n).planarity)
                val(n) = waveform;
            else
                val(n) = TC(n).planarity;
            end
        end
        val = reshape(val,objSize1,objSize2);
    
    case 'ENERGY'
        for n = 1:numObj
            if isempty(TC(n).energy)
                val(n) = waveform;
            else
                val(n) = TC(n).energy;
            end
        end
        val = reshape(val,objSize1,objSize2);
    
    case 'AZIMUTH'
        for n = 1:numObj
            if isempty(TC(n).azimuth)
                val(n) = waveform;
            else
                val(n) = TC(n).azimuth;
            end
        end
        val = reshape(val,objSize1,objSize2);
    
    case 'INCLINATION'
        for n = 1:numObj
            if isempty(TC(n).inclination)
                val(n) = waveform;
            else
                val(n) = TC(n).inclination;
            end
        end
        val = reshape(val,objSize1,objSize2);
    
        
        
    otherwise
        error('Property not recognized.');
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE TYPE PROPERTY
% where TC and val are scalars
%
function val = gettype(TC)


chan = get(TC,'CHANNEL');
chan = chan{1};
for n = 1:3
   val(1) = {[ chan{1}(3) chan{2}(3) chan{3}(3) ]};
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE COMPLETENESS PROPERTY
% where TC and val are scalars
%
function val = getcompleteness(TC)

% 0 = no waveforms and no particle motions
% 1 = waveforms but no particle motions
% 2 = waves and all particle motion fields


val = 0;

if all(~isempty(TC.traces)) && ~isempty(TC.rectilinearity) && ~isempty(TC.planarity) && ~isempty(TC.energy) && ~isempty(TC.azimuth)  && ~isempty(TC.inclination) 
    val = 2;
elseif all(~isempty(TC.traces)) 
   val = 1;
else
    val = 0;
end
    

