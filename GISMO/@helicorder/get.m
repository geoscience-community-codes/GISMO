function val = get(h,prop_name)
%GET: Get helicorder properties
%   val = get(helicorder,prop_name)
%
%   Valid property names:
%       WAVE, E_SST, MPL, TRACE_COLOR, EVENT_COLOR, DISPLAY
%   
%   Example: Create a waveform, add a field, then get the field
%
%   See also HELICORDER, HELICORDER/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if ~isa(h,'helicorder')
   error('HELICORDER/GET: Not a valid helicorder object')
end

switch lower(prop_name)
    case 'wave'
        val = h.wave;
    case 'e_sst'
        val = h.e_sst;
    case 'mpl'
        val = h.mpl;
    case 'trace_color'
        val = h.trace_color;
    case 'event_color'
        val = h.event_color;
    case 'display'
        val = h.display;
    case 'scale'
        val = h.scale;
    otherwise
        error('HELICORDER/GET: Not a valid helicorder property')
end
