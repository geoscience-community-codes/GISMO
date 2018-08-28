function h = set(h,varargin)
%SET: Set helicorder properties
%   val = get(helicorder,prop_name,prop_val)
%
%   Valid property names:
%       WAVE, E_SST, MPL, TRACE_COLOR, EVENT_COLOR, DISPLAY, SCALE
%
%   See also HELICORDER, HELICORDER/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

if ~isa(h,'helicorder')
   error('HELICORDER/SET: Not a valid helicorder object')
end

if ~rem(nargin-1,2) == 0
      error(['HELICORDER/SET: Arguments after h must appear in ',...
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
            error('HELICORDER/SET: wave property is not a waveform')
         end
         if numel(pv)~=nw
            error(['HELICORDER/SET: new waveform dimensions must match',...
                   ' existing waveform dimensions'])
         end
         h.wave = pv;
         
      case 'e_sst'
         if isnumeric(pv) && (sv(2)==2) && (nw==1) 
            pv={pv};
            nv = 1;
         end
         if iscell(pv)
            for m = 1:nv
               sub = pv{m};
               if (isnumeric(sub) && (size(sub,2)==2))||isempty(sub)
               elseif iscell(sub)
                  for mm = 1:numel(sub)
                     subsub = sub{mm};
                     if ~(isnumeric(subsub) && (size(subsub,2)==2))
                        error('HELICORDER/SET: wrong e_sst format')
                     end
                  end                     
               else
                  error('HELICORDER/SET: wrong e_sst format')
               end
            end
            h.e_sst = pv;
         elseif isempty(pv)
            for m = 1:nw
               h.e_sst{m} = []; % Set all e_sst to empty
            end
         else
            error('HELICORDER/SET: wrong e_sst format')
         end
         
      case 'mpl'
         if isnumeric(pv) && nv==1
            h.mpl = pv;
         else
            error('HELICORDER/SET: wrong mpl format')
         end
         
      case 'ytick'
         if isnumeric(pv) && nv==1
            h.ytick = pv;
         else
            error('HELICORDER/SET: wrong ytick format')
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
                        error(['HELICORDER/SET: trace_color RGB values must ',...
                           'be between 0 and 1'])
                     end
                  end
               end
            end
            h.trace_color = pv;
         else
            error('HELICORDER/SET: wrong trace_color format')
         end
         
      case 'event_color'
         h.event_color = pv;
         
      case 'display'
         h.display = pv;
         
      case 'scale'
         if isnumeric(pv) && nv==nw
            h.scale = pv;
         elseif isnumeric(pv) && nv==1
            h.scale = pv*ones(1,nw);
         else
            error('HELICORDER/SET: wrong scale format')
         end   

      otherwise
         error('HELICORDER/GET: Not a valid helicorder property')
    end
end
