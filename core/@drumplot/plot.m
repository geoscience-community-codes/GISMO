function fh = plot(drumplotobj)
%PLOT: Drumplot plotting function. A drumplot object contains no
%  graphical elements, but is instead a blueprint for how the drumplot
%  figure should be assembled. Information in drumplotobj includes waveform data,
%  number of minutes per line, color scheme, multi-waveform display type,
%  and a Catalog object to highlight over the drumplot. Calling plot(drumplotobj) will
%  assemble the drumplot figure based the information in drumplotobj. Plot returns
%  the figure handle if an output argument is provided, otherwise, there is
%  no output.
%
%USAGE: plot(drumplotobj) --> Create drumplot figure from drumplot object
%       fh = plot(drumplotobj) --> Also return drumplot figure handle
%
%INPUTS: drumplotobj - drumplot object
%                           
%OUTPUTS: fh - figure handle of drumplot
%
% See also DRUMPLOT
%
% Author: Dane Ketner, Alaska Volcano Observatory
% Modified: Glenn Thompson 2016-04-19
% $Date$
% $Revision$

% B is the 'builder structure' which contains the following fields:
%
% B.fh --> Figure handle of drumplot
% B.ax --> Axes handle of drumplot
% B.scale --> scaling factor to apply to each waveform
%  the value max(w)-min(w) is scaled such
%  that is spans 4 drumplot lines. If waveform w has a max value 
%  appearing on drumplot line 16, then that maximum point should fall 
%  near the middle of line 14 (2 lines above 16). Note that for any 
%  waveform in a drumplot, B.scale is consistant throughout (no different 
%  scaling on different lines for the same waveform). B.scale is multiplied 
%  by drumplotobj.scale, which by default is equal to 1. B.scale cannot be accessed
%  directly, but it can be increased or decreased indirectly by setting
%  drumplotobj.scale to a different value: h = set(h,'scale',2); will double the
%  displayed amplitude assuming there is only one waveform in drumplot.
% B.lines_per_waveform --> Number of drumplot lines occupied by a single waveform
% B.number_of_lines --> Total number of drumplot lines
% B.line_offset --> Trace offset from bottom of H.ax
% B.line_waveform_continuous --> 1 waveform object per line
% B.line_waveform_events --> 1 waveform object per line set to NaN between
%  events from Catalog
    %% INITIALIZE DRUMPLOT FIGURE
    B.fh = figure('Name','Drumplot');% New drumplot figure handle
    fh = B.fh;
    B.ax = axes('position',[.10 .07 .83 .86]); % New drumplot axes handle
    title(B.ax,'Plotting Drumplot...','FontSize',12)
%     %refresh(B.fh)
%     refresh(gcf)
drawnow
%     pause(0.1)

    %% INITIALIZE BUILDER STRUCTURE FIELDS
    % pad waveform object
    [snum enum] = gettimerange(drumplotobj.wave);
    snum = floorminute(snum+1/86400, drumplotobj.mpl);
    enum = ceilminute(enum-1/86400, drumplotobj.mpl);
    
    % find start and end times for each line
    B.number_of_lines = 1440*(enum-snum)/drumplotobj.mpl;
    days_per_line = (enum-snum)/B.number_of_lines;
    B.starttimes=snum:days_per_line:enum-days_per_line;
    B.endtimes=snum+days_per_line:days_per_line:enum;
    
    % split drumplotobj.wave into one waveform per line for continuous data
    B.line_waveform_continuous = extract(drumplotobj.wave, 'time', B.starttimes, B.endtimes);
    
    % if there are catalog events, add waveform objects, return one waveform per line for event data
    B.line_waveform_events = [];
    w = [];
    if drumplotobj.catalog.numberOfEvents > 0
        
        if isempty(drumplotobj.catalog.waveforms)
            drumplotobj.catalog = drumplotobj.catalog.addwaveforms(drumplotobj.wave);
        end
        w = [drumplotobj.catalog.waveforms{1,:}];
    end
    
     if numel(drumplotobj.arrivals.time) > 0
        pretrigsecs = 1; posttrigsecs = 1;
        if isempty(drumplotobj.arrivals.waveforms)
            drumplotobj.arrivals = drumplotobj.arrivals.addwaveforms(drumplotobj.wave, pretrigsecs, posttrigsecs);
        end
        w = [drumplotobj.arrivals.waveforms{1,:}];
     end
    
     if drumplotobj.detections.numel() > 0
        temp_cobj = associate(drumplotobj.detections, 0.01);
        
        
        if isempty(temp_cobj.waveforms)
            pretrigsecs = 1; posttrigsecs = 1;
            temp_cobj = temp_cobj.addwaveforms(drumplotobj.wave, pretrigsecs, posttrigsecs);
        end
        w = [temp_cobj.waveforms{1,:}];
    end
w(1)
w(2)
     
     if ~isempty(w)
        % go through w and check the channeltag is same as drumplotobj.wave
        mainctag = get(drumplotobj.wave,'ChannelTag');
        w2=[];
        for wavnum=1:numel(w)
            thisctag = get(w(wavnum),'ChannelTag');
            if strcmp(thisctag.string(), mainctag.string())
                w2 = [w2 w(wavnum)];
            end
        end
        w = combine(w2);
        w = pad(w, snum, enum, NaN);
        B.line_waveform_events = extract(w, 'time', B.starttimes, B.endtimes);
        clear w
    end
    
    % now we just need to plot each line with an appropriate offset
    
    % scaling
    y = get(drumplotobj.wave, 'data');
    max_amplitude = (nanmax(y)-nanmin(y))/2;
    B.scale=drumplotobj.scale/(B.number_of_lines*max_amplitude);

    %% PLOT DRUMPLOT TRACES WITH EVENT OVERLAY
    for n = 1:B.number_of_lines % Glenn 20160513: For cookbook examples I had to add 1 here. Not sure why. Doesn't work in other cases
      B.line_offset(n) = (B.number_of_lines-n+0.5)/B.number_of_lines; % Trace offset from bottom
      B.line_waveform_continuous(n) = B.line_waveform_continuous(n) * B.scale + B.line_offset(n);
      plot(B.line_waveform_continuous(n), 'color', drumplotobj.trace_color, 'xunit', 'minutes', 'axeshandle', B.ax);
      hold on;
      if ~isempty(B.line_waveform_events)
          B.line_waveform_events(n) = B.line_waveform_events(n) * B.scale + B.line_offset(n);
          plot(B.line_waveform_events(n), 'color', drumplotobj.event_color, 'xunit', 'minutes', 'axeshandle', B.ax);
      end
    end % Finished plotting all drumplot trace data

    %% ADD FINISHING TOUCHES TO DRUMPLOT FIGURE
    add_title(drumplotobj,B);
    add_y_ticks(drumplotobj,B);
    set(B.ax,'XGrid','on')
    xlim([0 drumplotobj.mpl])
    set(B.ax, 'YLim', [0 1]);

%     %% OUTPUT
%     if nargout == 0
%     elseif nargout == 1
%        B(1) = {B.fh};
%     else
%        warning('DRUMPLOT/PLOT Too many outputs')
%     end
end

%% ADD TITLE TO DRUMPLOT FIGURE
function add_title(drumplotobj,B)
    if isempty(drumplotobj.wave)
        title(B.ax,'No Data Selected','FontSize',12);
    else
        scn_str = [];
        sta = get(drumplotobj.wave,'station');
        cha = get(drumplotobj.wave,'channel');
        net = get(drumplotobj.wave,'network');
        scn_str = [net,'.',sta,'.',cha];
        h_title = sprintf('%s:\n%s to %s',scn_str, datestr(B.starttimes(1),31), datestr(B.endtimes(end),31) );
        title(B.ax,h_title);
    end
end

%% ADD Y-AXES TICKS AND LABELS
function add_y_ticks(drumplotobj,B)

    if ~isempty(drumplotobj.wave)
        ylabel(B.ax,'')
        tick_positions = B.line_offset;
        tick_labels = datestr(B.starttimes,15);
        set(B.ax,'YTick',fliplr(tick_positions))
        set(B.ax,'YTickLabel',flipud(tick_labels))
    end
end
    
