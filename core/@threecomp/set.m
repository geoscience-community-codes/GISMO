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
narginchk(3,3);

if ~ischar(fieldName)
    error('''field'' must be a character string');
end

switch upper(fieldName)
    
    case {'WAVEFORM', 'TRACE'}
        if ~(isa(val,'waveform') || isa(val,'SeismicTrace'))
            error('VALUE is not a waveform object');
        end
        if size(val,2)~=3
            error('Input waveform must be nx3 in size');
        end
        TC.traces = reshape(val,[],3);
        
        
    case {'BACKAZIMUTH'}
       assert(isnumeric(val),'VALUE is not numeric');
       assert(val >=0 && val <360, 'BACKAZIMUTH must be between 0-360');
        if numel(val)==1
            val = repmat(val,size(TC));
        end                     % NOt WORKING SOMEWHERE HERE>>>>>
        for n=1:numel(TC)
            TC(n).backAzimuth = val(n);
        end
    otherwise
        warning('can''t understand property name');
end;


