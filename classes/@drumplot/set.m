function h = set(h,varargin)
%SET: Set drumplot properties
%   val = get(drumplot,prop_name,prop_val)
%
%   Valid property names:
%       WAVE, CATALOG, MPL, TRACE_COLOR, EVENT_COLOR, SCALE
%
%   See also DRUMPLOT, DRUMPLOT/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% Modified: Glenn Thompson 2016/04/20
% $Date$
% $Revision$

if ~isa(h,'drumplot')
   error('DRUMPLOT/SET: Not a valid drumplot object')
end

if ~rem(nargin-1,2) == 0
      error(['DRUMPLOT/SET: Arguments after h must appear in ',...
             'property name/val pairs'])
end

for n = 1:2:nargin-2
   nw = numel(h.wave); % Number of waveforms in h
   pn = varargin{n};   % Property name
   pv = varargin{n+1}; % Property value
   nv = numel(pv);     % Number of elements in property value
   sv = size(pv);      % Size of property value
   
   switch lower(pn)
      case 'wave'
         if ~isa(pv,'waveform')
            error('DRUMPLOT/SET: wave property is not a waveform')
         end
         if numel(pv)~=nw
            error(['DRUMPLOT/SET: new waveform dimensions must match',...
                   ' existing waveform dimensions'])
         end
         h.wave = pv;
         
      case 'catalog'
         if isa(pv,'Catalog')
             h.catalog = pv;
         elseif isempty(pv)
            h.catalog = Catalog();
         else
            error('DRUMPLOT/SET: wrong Catalog format')
         end
         
      case 'mpl'
         if isnumeric(pv) && nv==1
            h.mpl = pv;
         else
            error('DRUMPLOT/SET: wrong mpl format')
         end
         
      case 'trace_color'
         if sv(2)==3 && isnumeric(pv)
            pv = {pv};
            nv = 1;
         end
         if (nw==nv) && iscell(pv)
            for m = 1:nv
               if size(pv{m},2)==3
                  for mm = 1:numel(pv{m})
                     if ~(pv{m}(mm)<=1 && pv{m}(mm)>=0)
                        error(['DRUMPLOT/SET: trace_color RGB values must ',...
                           'be between 0 and 1'])
                     end
                  end
               end
            end
            h.trace_color = pv;
         else
            error('DRUMPLOT/SET: wrong trace_color format')
         end
         
      case 'event_color'
         h.event_color = pv;

      case 'scale'
         if isnumeric(pv) && nv==nw
            h.scale = pv;
         elseif isnumeric(pv) && nv==1
            h.scale = pv*ones(1,nw);
         else
            error('DRUMPLOT/SET: wrong scale format')
         end   

      otherwise
         error('DRUMPLOT/GET: Not a valid drumplot property')
    end
end
