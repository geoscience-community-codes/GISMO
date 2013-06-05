function h = helicorder(varargin)

%HELICORDER: Helicorder generates a multi-line display of input waveform
%   data. Helicorder can display waveform data from multiple stations and 
%   channels as long as the time range is the same for each. Helicorder
%   can also display detected events over the raw data.
%
%USAGE: helicorder()----------------------- Empty helicorder
%       helicorder(wave)------------------- Default properties
%       helicorder(wave,prop_1,val_1,...)-- User-defined properties
%
%VALID PROP/VAL:
%  'mpl'-->(Minutes Per Line)
%     single numeric value specifying number of minutes per helicorder
%     line. (This applies to all waveforms in the helicorder)
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
%  'e_sst'-->(Event Start/Stop Times) 
%     If wave contains only one wavefrom object, 'e_sst' can be entered
%     as an Nx2 array of matlab times. If there is more than one waveform
%     in wave (M waveforms), 'e_sst' must be a 1xM cell array, each cell 
%     containing Nx2 array of start/stop times. A single waveform can also
%     have multiple sets of start/stop times as in a waveform with multiple
%     event families. In this case 'e_sst' should be entered as a 1xL cell
%     array for a particular waveform (with L separate groups to be 
%     highlighted).
%     EXAMPLE: h = helicorder(w,'e_sst',A) where w is a 1x2 waveform object
%        A is a 1x2 cell array
%        A(1,1) is a Nx2 numeric array
%        A(1,2) is a 1x3 cell
%        A(1,2){1} is a Nx2 numeric array
%        A(1,2){2} is a Nx2 numeric array
%        A(1,2){3} is a Nx2 numeric array
%     DEFAULT = [] (No events)
%
%  'trace_color'-->(Trace Color)
%     If wave contains only one wavefrom object, 'trace_color' can be 
%     entered as a 1x3 array of RGB values (between 0 and 1). For wave
%     arguments longer than 1, 'trace_color' should be entered as a 1xN
%     cell array, each containing a 1x3 array of RGB values.
%
%  'event_color'-->(Event Color)
%     Only use this property when 'e_sst' property exists. 'event_color'
%     follows the same structure as 'e_sst'. If wave contains only one 
%     waveform object, 'event_color' can be entered as a 1x3 array of RGB 
%     values (between 0 and 1). For wave arguments longer than 1, 
%     'event_color' should be entered as a 1xN cell array, each containing 
%     a 1x3 array of RGB values. If multiple event sets exist for a single
%     waveform, 'event_color' must be specified accordingly
%     EXAMPLE: h = helicorder(w,'e_sst',A,'event_color',B)
%        A is the same as the previous example
%        B(1,1) is a 1x3 RGB array
%        A(1,2) is a 1x3 cell
%        A(1,2){1} is a 1x3 RGB array
%        A(1,2){2} is a 1x3 RGB array
%        A(1,2){3} is a 1x3 RGB array
%     DEFAULT = [] (No events)
%
%  'display'-->(Multi-Waveform Display Type)
%     'single' - used when there is only one waveform in wave. None of the
%        multi-waveform display types can be set unless multiple waveforms
%        are passed.
%     'stack' - plots multiple waveforms over top of each other. 
%        (Multiple motivations could exist for wanting to display data in 
%        this way such as overlaying VLP energy)
%     'alternate' - Alternate helicorder lines 
%        i.e. Helicorder containing 3 waveforms would look like:           
%        w1(t0 --> t1), w2(t0 --> t1), w3(t0 --> t1), w1(t1 -- t2),...
%     'group' - Plot all lines from individual waveforms in separate blocks
%        i.e. Helicorder containing 3 waveforms would look like: 
%        w1(t0 --> t1), w1(t1 --> t2), w1(t2 --> t3),... w1(t_end-1 -->
%        t_end),w2(t0 --> t1), w2(t1 --> t2), w2(t2 --> t3),...
%     DEFAULT = 'single','alternate' (1 or multiple waveforms)
%
%INPUTS: wave     - a waveform object to be plotted on multiple helicorder
%                   trace lines
%        varargin - user-defined helicorder properties (argument pairs)                  
%
%OUTPUTS: h - helicorder object
%
%   See also HELICORDER/DISP, HELICORDER/BUILD, HELICORDER/GET,
%            HELICORDER/SET
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

%% EMPTY HELICORDER
if nargin == 0               
   h.wave = waveform();
   h.e_sst = {};
   nw = 0;

%% ANOTHER HELICORDER OBJECT 
elseif nargin==1 && isa(varargin{1},'helicorder')
    h = varargin{1};
    return
    
%% WAVEFORM OBJECT PROVIDED
elseif (nargin >= 1) && isa(varargin{1},'waveform')
   h.wave = varargin{1}; % Helicorder waveform data
   nw = numel(h.wave);
else
   error('helicorder: first argument must be a waveform')
end

%% DEFAULT PROPERTIES
for n = 1:nw,               
   h.e_sst{n} = []; % Empty event start/stop time array
end 

h.mpl = 10;   % 10 Minutes per line
h.ytick = 30; % Time Ticks every 30 Minutes (3 Lines)

if nw <= 1                     % Default trace color scheme
   h.trace_color{1} = [0 0 0]; % black
   h.event_color{1} = [1 0 0]; % red
elseif nw == 2
   h.trace_color{1} = [0 0 0]; % black
   h.trace_color{2} = [0 0 1]; % blue
else
   rr = zeros(1,nw);              % red values
   gg = round(linspace(-255,255,nw)); 
   gg = sign(sign(gg)+1).*gg/255; % green values
   bb = round(linspace(255,-255,nw)); 
   bb = sign(sign(bb)+1).*bb/255; % blue values
   for n = 1:nw
      h.trace_color{n} = [rr(n) gg(n) bb(n)];
   end
end

h.event_color = [];

if nw <= 1
   h.display = 'single';
else
   h.display = 'alternate';
end

h.scale = ones(1,nw); % Waveform amplitude scale is automatically set based
                      % on maximum values in wave. scale can be set after 
                      % the fact. 1 is default, going higher or lower will
                      % scale wave proportionally.
h = class(h,'helicorder');

%% USER-DEFINED PROPERTIES
if (nargin > 1)
   v = varargin(2:end);
   nv = nargin-1;
   if ~rem(nv,2) == 0
      error(['helicorder: Arguments after wave must appear in ',...
             'property name/val pairs'])
   end
   for n = 1:2:nv-1
      name = lower(v{n});
      val = v{n+1};
      switch name
         case 'e_sst' % Event Start/Stop Times
            h = set(h,'e_sst',val);
            for n = 1:nw       % Default event color scheme (shades of red)
               if ~iscell(h.e_sst{n})
                  h.event_color{n} = [1 0 0];
               else
                  for m = 1:numel(h.e_sst{n})
                     rr = m/numel(h.e_sst{n});
                     h.event_color{n}{m} = [rr 0 0];
                  end
               end
            end
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
            error('helicorder: Property name not recognized')
      end
   end
end
  