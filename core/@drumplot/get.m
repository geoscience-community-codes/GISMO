function val = get(h,prop_name)
%GET: Get drumplot properties
%   val = get(drumplot,prop_name)
%
%   Valid property names:
%       WAVE, CATALOG, MPL, TRACE_COLOR, EVENT_COLOR, DISPLAY
%   
%   Example: Create a waveform, add a field, then get the field
%
%   See also DRUMPLOT, DRUMPLOT/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if ~isa(h,'drumplot')
   error('DRUMPLOT/GET: Not a valid drumplot object')
end

switch lower(prop_name)
    case 'wave'
        val = h.wave;
    case 'catalog'
        val = h.catalog;
    case 'mpl'
        val = h.mpl;
    case 'trace_color'
        val = h.trace_color;
    case 'event_color'
        val = h.event_color;
    case 'scale'
        val = h.scale;
    otherwise
        error('DRUMPLOT/GET: Not a valid drumplot property')
end
