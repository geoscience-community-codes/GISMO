function h = drumplot(varargin)

%DRUMPLOT: Drumplot generates a multi-line display of input waveform
%   data. Drumplot can display waveform data from multiple stations and 
%   channels as long as the time range is the same for each. Drumplot
%   can also display detected events over the raw data.
%
%USAGE: drumplot()----------------------- Empty drumplot
%       drumplot(wave)------------------- Default properties
%       drumplot(wave,prop_1,val_1,...)-- User-defined properties
%
%VALID PROP/VAL:
%  'mpl'-->(Minutes Per Line)
%     single numeric value specifying number of minutes per drumplot
%     line. (This applies to all waveforms in the drumplot)
%     DEFAULT = 10 
%
%  'ytick'-->(Y-Axis Ticks)
%     single numeric value specifying number of minutes between y-axis 
%     tick marks and labels. 'ytick' depends on 'mpl', for example, if 
%     'mpl' is 20, an attempt to set 'ytick' to 10 will be result in 
%     'ytick' rounded to nearest multiple of 'mpl' (20 in this case). Note
%     also that manually setting 'mpl' will result in an automatic
%     adjustment of 'ytick'.
%     DEFAULT = 30
%
%  'catalog'-->(Catalog object from which event start/stop times are retrieved) 
%     EXAMPLE: h = drumplot(w,'catalog',cobj) where w is a 1x2 waveform object
%        cobj is a Catalog object
%     DEFAULT = [] (No events)

%  'trace_color'-->(Trace Color)
%     If wave contains only one wavefrom object, 'trace_color' can be 
%     entered as a 1x3 array of RGB values (between 0 and 1). For wave
%     arguments longer than 1, 'trace_color' should be entered as a 1xN
%     cell array, each containing a 1x3 array of RGB values.
%
%INPUTS: wave     - a waveform object to be plotted on multiple drumplot
%                   trace lines
%        varargin - user-defined drumplot properties (argument pairs)                  
%
%OUTPUTS: h - drumplot object
%
%   See also DRUMPLOT/DISP, DRUMPLOT/BUILD, DRUMPLOT/GET,
%            DRUMPLOT/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% Modified: Glenn Thompson 2016-04-19 to work with Catalog objects
% $Date$
% $Revision$

    %% DEFAULT PROPERTIES              
    h.wave = waveform();
    h.catalog = Catalog();
    nw = 0;
    h.mpl = 10;   % 10 Minutes per line
    h.trace_color = [0 0 0]; % black
    h.event_color = [1 0 0]; % red
    h.scale = 1;          % Waveform amplitude scale is automatically set based
                          % on maximum values in wave. scale can be set after 
                          % the fact. 1 is default, going higher or lower will
                          % scale wave proportionally.
    h = class(h,'drumplot');
    
    %% WAVEFORM OBJECT PROVIDED
    if (nargin >= 1) && isa(varargin{1},'waveform')
       h.wave = varargin{1}; % Drumplot waveform data
       nw = numel(h.wave);
       if nw>1
           error('Input waveform must be a single waveform object')
       end
    else
       error('drumplot: first argument must be a waveform')
    end

    %% NAME-VALUE PARAMS
    if (nargin > 1)
       v = varargin(2:end);
       nv = nargin-1;
       if ~rem(nv,2) == 0
          error(['drumplot: Arguments after wave must appear in ',...
                 'property name/val pairs'])
       end
       for n = 1:2:nv-1
          name = lower(v{n});
          val = v{n+1};
          switch name
             case 'catalog' % get ontimes/offtimes from catalog object 
                h = set(h, 'catalog', val);
             case 'ytick' % Y-Tick Spacing
                h = set(h,'ytick',val);
             case 'mpl' % Minutes Per Line
                h = set(h,'mpl',val);
             case 'trace_color' % Minutes Per Line
                h = set(h,'trace_color',val);
             case 'event_color' % Minutes Per Line
                h = set(h,'event_color',val);
             case 'display' % Multiple Waveform Display Type
                h = set(h,'display',val);
             case 'scale' % Waveform Data Scaling Factor   
                h = set(h,'scale',val);
             otherwise
                error('drumplot: Property name not recognized')
          end % switch name
       end % for
    end % if
end
  
