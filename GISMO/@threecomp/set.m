function TC = set(TC, fieldName, val)

%SET inserts properties for threecomp object
%   TC = SET(TC,FIELD,VALUE) asigns VALUE to FIELD for all properties
%   in the threecomp object. Suitable FIELDS include:
%       WAVEFORM         value must be 1x3 waveform object
%       BACKAZIMUTH      value must be scalar or same size as TC
%

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% CHECK INPUT
if nargin ~= 3
    error('Incorrect number of inputs');
end
if ~isa(TC,'threecomp')
    error('First argument must be a threecomp object');
end
if ~isa(fieldName,'char')
    error('Second argument must be a character string');
end

switch upper(fieldName)
    
    case {'WAVEFORM'}
        if ~isa(val,'WAVEFORM')
            error('VALUE is not a waveform object');
        end
        if numel(val)~=3
            error('Input waveform must be nx3 in size');
        end
        TC.traces = reshape(val,1,3);
        
        
    case {'BACKAZIMUTH'}
        if ~isa(val,'double')
            error('VALUE is not of type double');
        end
        if val<0 || val>=360
            error('BACKAZIMUTH must be between 0-360');
        end
        if numel(val)==1
            val = repmat(val,size(TC));
        end                     % NOt WORKING SOMEWHERE HERE>>>>>
        for n=1:numel(TC)
            TC(n).backAzimuth = val(n);
        end
    otherwise
        warning('can''t understand property name');
end;


