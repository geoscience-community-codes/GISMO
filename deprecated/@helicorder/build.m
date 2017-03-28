function varargout = build(h)

%BUILD: Helicorder builder function. A helicorder object (h) contains no
%  graphical elements, but is instead a blueprint for how the helicorder
%  figure should be assembled. Information in h includes waveform data,
%  number of minutes per line, color scheme, multi-waveform display type,
%  and events to highlight over the helicorder. Calling build(h) will
%  assemble the helicorder figure based the information in h. Build returns
%  the figure handle if an output argument is provided, otherwise, there is
%  no output.
%
%USAGE: build(h) --> Create helicorder figure from helicorder object
%       fh = build(h) --> Also return helicorder figure handle
%
%INPUTS: h - helicorder object
%                           
%OUTPUTS: fh - figure handle of helicorder
%
% See also HELICORDER
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

% B is the 'builder structure' which contains the following fields:
%
% B.fh --> Figure handle of helicorder
% B.ax --> Axes handle of helicorder
% B.nw --> Number of waveform objects in helicorder
% B.tv --> Waveform time vector cell array
% B.w_d --> Waveform data cell array
% B.scale --> For each waveform w, the value max(w)-min(w) is scaled such
%  that is spans 4 helicorder lines. If waveformm w has a max value 
%  appearing on helicorder line 16, then that maximum point should fall 
%  near the middle of line 14 (2 lines above 16). Note that for any 
%  waveform in a helicorder, B.scale is consistant throughout (no different 
%  scaling on different lines for the same waveform). B.scale is multiplied 
%  by h.scale, which by default is equal to 1. B.scale cannot be accessed
%  directly, but it can be increased or decreased indirectly by setting
%  h.scale to a different value: h = set(h,'scale',2); will double the
%  displayed amplitude assuming there is only one waveform in helicorder.
%  h = set(h,'scale',[2 1 .5]); will double the first, and halve the
%  last waveform display amplitude assuming 3 waveforms in h.
% B.w_l --> Data length of each waveform in h
% B.Fs --> Sampling Frequency of each waveform in h
% B.tra_l --> Number of data points per helicorder line for each waveform
%  in h (note: B.tra_l will be different for waveforms in h with different 
%  sampling frequencies)
% B.tra_ns --> Number of helicorder lines occupied by a single waveform
% B.tra_nt --> Total number of helicorder lines (all waveforms)
%  (Note: If only one waveform in h, B.tra_ns = B.tra_nt)
% B.e_nan --> Event overlay waveforms (used for event highlighting)
% B.off --> Trace offset from bottom of H.ax
% B.trace --> Waveform array of all traces, length = B.tra_nt
% B.tra_mean --> Mean value of each trace (used for alignment)
% B.trace_e --> Event trace includes event waveform data separated by NaN
%  values (plotted over top of B.trace)

%% INITIALIZE HELICORDER FIGURE
B.fh = figure('Name','Helicorder');        % New helicorder figure handle
B.ax = axes('position',[.10 .07 .83 .86]); % New helicorder axes handle
title(B.ax,'Building Helicorder...','FontSize',12)
%refresh(B.fh)
refresh(gcf)
pause(.1)

%% INITIALIZE BUILDER STRUCTURE FIELDS
h = pad_w(h);          % If front of waveform is missing, fill with NaN
B.nw = numel(h.wave);              % Number of waveforms
B.tv = get(h.wave, 'timevector');  % Wave time vector
B.w_d = get(h.wave,'data');        % Wave data vector
if ~iscell(B.w_d), B.w_d = {B.w_d}; end
for n = 1:B.nw % Scale factor
   B.scale(n)=(max(B.w_d{n})-min(B.w_d{n}));
end 
mean_scale = mean(B.scale);
for n = 1:B.nw 
   B.scale(n)=mean_scale./h.scale(n);
end 
B.w_l = get(h.wave,'data_length');  % Wave data length
B.Fs = get(h.wave,'freq');          % Sampling frequency
B.tra_l = round(B.Fs*60*h.mpl);       % Trace length (data points)
B.tra_ns = round(B.w_l(1)/B.tra_l(1));% # of helicorder rows (one waveform)
B.tra_nt = B.nw*B.tra_ns; %

for n =1:B.nw
   if ~isempty(h.e_sst{n})  % Is the events array non-empty?
      % Return wave w/ NaN non-events from wave start to end
      if is_sst(h.e_sst{n})
      B.e_nan{n} = sst2nan(extract_sst(h.e_sst{n},...
         get(h.wave,'start'),get(h.wave,'end')), h.wave);
      elseif iscell(h.e_sst{n})
         for m = 1:numel(h.e_sst{n})
            if is_sst(h.e_sst{n}{m})
               B.e_nan{n}(m) = sst2nan(extract_sst(h.e_sst{n}{m},...
               get(h.wave,'start'),get(h.wave,'end')), h.wave);
            else
               B.e_nan{n}(m) = waveform();
            end
         end
      end
   else
      B.e_nan{n} = [];
   end
end



%% PLOT HELICORDER TRACES WITH EVENT OVERLAY

% Example values of n,k1,k2,k3,k4 reflect:
% B.nw = 3;  B.tra_ns = 100;  B.tra_nt = 300 
% Example values show what k1 through k4 look like
% And how they are used in different display types

for n = 1:B.tra_nt     % for n = 1,2,3,4,5,6,7,8,9,...,298,299,300
                      
k1 = ceil(n/B.nw);     % k1 = 1,1,1,2,2,2,3,3,3,...,99,99,99,100,100,100 
k2 = n-(B.nw*(k1-1));  % k2 = 1,2,3,1,2,3,1,2,3,...,1,2,3,1,2,3,1,2,3 
k3 = ceil(n/B.tra_ns); % k3 = 1,1,1,1,1,1,...,2,2,2,2,2,2,...,3,3,3,3,3
k4 =...       % k4 = 1,2,3,4,...,99,100,1,2,3,...,99,100,1,2,3,...,99,100
 n-floor(n/(B.tra_ns+.00001))*B.tra_ns;

switch lower(h.display)
   
%% Single/Alternate Display Type (Default)   
   case {'single','alternate'}
      B.off(n) = .5+(B.tra_nt-n)*.25; % Trace offset from bottom
      B.trace(n) = extract(h.wave(k2),'index',...
         1+(k1-1)*B.tra_l(k2), k1*B.tra_l(k2))/B.scale(k2)+B.off(n);
      B.k(n) = k2;
      B.tra_mean(n) = mean(B.trace(n));
      if ~isempty(h.e_sst{k2})
         B.trace_e(n) = extract(B.e_nan{k2},'index',...
            1+(k1-1)*B.tra_l(k2),k1*B.tra_l(k2))/B.scale(k2) + B.off(n);
      end
      B.trace_h(n) = plot(B.trace(n),'color',h.trace_color{k2},...
         'xunit','minutes');
      if n == 1
         hold on
      end
      if ~isempty(h.e_sst{k2}) % Plot event red
         B.trace_e_h(n) = plot(B.trace_e(n),...
         'color',h.event_color{k2},'xunit','minutes');
      else
         B.trace_e_h(n) = NaN;
      end
      
%% Group Display Type
   case {'group'}
      B.off(n) = .5+(B.tra_nt-n)*.25; % Trace offset from bottom
      B.trace(n) = extract(h.wave(k3),'index',...
         1+(k4-1)*B.tra_l(k3), k4*B.tra_l(k3))/B.scale(k3)+B.off(n);
      B.k(n) = k3;
      B.tra_mean(n) = mean(B.trace(n));
      if ~isempty(h.e_sst{k3})
         B.trace_e(n) = extract(B.e_nan{k3},'index',...
            1+(k4-1)*B.tra_l(k3), k4*B.tra_l(k3))/B.scale(k3)+B.off(n);
      end
      B.trace_h(n) = plot(B.trace(n),'color',h.trace_color{k3},...
         'xunit','minutes');
      if n == 1
         hold on
      end
      if ~isempty(h.e_sst{k3}) % Plot event over 
         B.trace_e_h(n) = plot(B.trace_e(n),...
         'color',h.event_color{k2},'xunit','minutes');
      else
         B.trace_e_h(n) = NaN;
      end
      
%% Stack Display Type      
   case {'stack'}
      B.off(n) = .5+(B.tra_ns-k1)*.25; % Trace offset from bottom
      B.trace(n) = extract(h.wave(k2),'index',...
         1+(k1-1)*B.tra_l(k2), k1*B.tra_l(k2))/B.scale(1)+B.off(n);
      B.k(n) = k2;
      B.tra_mean(n) = mean(B.trace(1+B.nw*floor(n/(B.nw+.00001))));
      if ~isempty(h.e_sst{k2})
         B.trace_e(n) = extract(B.e_nan{k2},'index',...
            1+(k1-1)*B.tra_l(k2),k1*B.tra_l(k2))/B.scale(1) + B.off(n);
      end
      B.trace_h(n) = plot(B.trace(n),'color',h.trace_color{k2},...
         'xunit','minutes');
      if n == 1
         hold on
      end
      if ~isempty(h.e_sst{k2}) % Plot event red
         B.trace_e_h(n) = plot(B.trace_e(n),...
            'color',h.event_color{k2},'xunit','minutes');
      else
         B.trace_e_h(n) = NaN;
      end
end % switch
end % Finished plotting all helicorder trace data

%% ADD FINISHING TOUCHES TO HELICORDER FIGURE
add_title(h,B);
add_y_ticks(h,B);
set(B.ax,'XGrid','on')
xlim([0 h.mpl])

switch lower(h.display)
   case {'stack'}       
      ylim([0 1+(B.tra_ns-1)*.25])
   otherwise                                      
     ylim([0 1+(B.tra_nt-1)*.25])
end

%% STORE TRACE NUMBER IN LINE OBJECT 'TAG' & SET BUTTON DOWN FUNCTION
% for n = 1:numel(B.trace_h)
%    set(B.trace_h(n),'HitTest','on','ButtonDownFcn',{@traClick,h,B})
%    set(B.trace_h(n),'Tag',['t',num2str(n)]) % t for trace
%    if ~isnan(B.trace_e_h(n))
%       set(B.trace_e_h(n),'Tag',['e',num2str(n)]) % e for event
%       set(B.trace_e_h(n),'HitTest','on','ButtonDownFcn',{@traClick,h,B})
%    end
% end

%% OUTPUT
if nargout == 0
elseif nargout == 1
   varargout(1) = {B.fh};
else
   error('HELICORDER:BUILD This many output arguments nor supported')
end

%% DETERMINED WHAT WAS CLICKED
% function traClick(varargin)
% 
% k = get(varargin{1},'Tag');       % Clicked object tag 
% tra_n = str2double(k(2:end));     % Get Trace number
% h = varargin{3};                  % Get Helicorder object
% B = varargin{4};                  % Get Builder structure
% clk_trace = B.trace(tra_n);       % Get clicked trace waveform
% clk_n = B.k(tra_n);               % Get clicked waveform number
% mouse = get(B.ax,'currentpoint'); % Mouse location in H.ax()
% clk_t = get(clk_trace,'start')+...
%         mouse(1,1)/60/24;
% if strcmp(k(1),'e')               % Was an event was clicked?
%    [N P] = search_sst(t,h.e_sst{clk_n});
%    if P == 1
%       clk_e_n = N;
%    end
% else
%    clk_e_n = 0;
% end

% TO SUMMARIZE:
% clk_n --> which waveform in h.wave was clicked?
% clk_t --> where in time was mouse click? (datenum value)
% clk_e_n --> which event in h.e_sst was clicked? 
%             If not event click, clk_e_n = 0
%% NEXT LINES CAN BE ALTERED TO CHANGE TRACE CLICK BEHAVIOR
% Comment next lines to suppress click behavior

% w_start = get(h.wave(clk_n),'start');
% w_end = get(h.wave(clk_n),'end');
% if (w_start > clk_t-30/24/60/60), win_t(1) = w_start;
% else win_t(1) = clk_t-30/24/60/60; end
% if (w_end < clk_t+30/24/60/60),win_t(2) = w_end;
% else win_t(2) = clk_t+30/24/60/60; end
% if ~isempty(h.e_sst{clk_n})
%    event_pick(h.wave(clk_n),'sst',h.e_sst{clk_n},'win',win_t);
% else
%    event_pick(h.wave(clk_n),'win',win_t);
% end

%% ADD TITLE TO HELICORDER FIGURE
function add_title(h,B)

if isempty(h.wave)
   title(B.ax,'No Data Selected','FontSize',12);
else
   scn_str = [];
   for n = 1:numel(h.wave)
      sta = get(h.wave(n),'station');
      cha = get(h.wave(n),'channel');
      net = get(h.wave(n),'network');
      scn_str = [scn_str,sta,':',cha,':',net,', '];
   end
   
   dv1 = datevec(get(h.wave(1),'start')); % Date vec (first trace point)
   dv2 = datevec(get(h.wave(1),'end')); % Date vec (last trace point)
   if dv1(1)==dv2(1) && dv1(2)==dv2(2) && dv1(3)==dv2(3) % Same Y,M,D ?
      span = [datestr(dv1,0), ' to ', datestr(dv2,13)]; % Less repetitive
   else % Different Year , Month, or Day
      span = [datestr(dv1), ' to ', datestr(dv2)]; % Full dates displayed
   end

   h_title = [scn_str, span];
   title(B.ax,h_title);
end

%% ADD Y-AXES TICKS AND LABELS
function add_y_ticks(h,B)

if ~isempty(h.wave)
   ylabel(B.ax,'')
   n_lab = 0;
   switch lower(h.display)
   case {'single','group'}
      d = 1;
   case {'stack','alternate'}
      d = B.nw;
   end
   for k = 1:d:B.tra_nt
      t = get(B.trace(k),'start');
      m = round((t-floor(t))*24*60);   % number of decimal minutes from day start
      if rem(m,h.ytick)==0
         n_lab = n_lab + 1;
         tick_pos(n_lab) = B.off(k);
         tick_lab{n_lab} = datestr(t,13);
      end
   end
end

tick_pos = tick_pos(end:-1:1);
tick_lab = tick_lab(end:-1:1);
set(B.ax,'YTick',tick_pos)
set(B.ax,'YTickLabel',tick_lab)

%% PAD FRONT & END OF WAVE IF NOT A MULTIPLE OF h.mpl
%  (i.e. if mpl = 30 and wave begins at 12:32:00, then first 2 minutes are
%   NaN stuffed so that the trace begins at 12:30:00
function h = pad_w(h)

for n = 1:numel(h.wave)
   w = h.wave(n);
   t1 = get(w,'start');         % start of w (datenum)
   t2 = get(w,'end');           % end of w (datenum)
   m1 = (t1-floor(t1))*24*60;   % number of decimal minutes from day start
   m2 = (t2-floor(t2))*24*60;   % number of decimal minutes from day end
   gap1 = rem(m1,h.mpl)/24/60;  % gap from w start to mpl-adjusted start
   tt1 = t1-gap1;               % mpl-adjusted start time
   if (gap1 > 0)
      N1 = round(gap1*24*60*60*get(w,'freq')); % length of gap1 (samples)
      pad1 = ones(N1,1)*NaN;
      dat = [pad1; get(w(n),'data')];
      w = set(w,'data',dat);
      w = set(w,'start',tt1);
      h.wave(n) = w;
   end
end

