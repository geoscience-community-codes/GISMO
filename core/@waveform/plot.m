function varargout = plot(w, varargin)
   %PLOT plots a waveform object
   %   h = plot(waveform)
   %   Plots a waveform object, handling the title and axis labeling.  The
   %   output parameter h is optional.  If used, the handle to the waveform
   %   plots will be returned.  These can be used to change properties of the
   %   plotted waveforms.
   %
   %   h = plot(waveform, ...)
   %   Plots a waveform object, passing additional parameters to matlab's PLOT
   %   routine.
   %
   %   h = plot(waveform, 'xunit', xvalue, ...)
   %   sets the xunit property of the graph, which is used to determine how
   %   the times of the waveform are interpereted.  Possible values for XVALUE
   %   are 's', 'm', 'h', 'd', 'doy', 'date'.
   %
   %        'seconds' - seconds
   %        'minutes' - minutes
   %        'hours' - hours
   %        'day_of_year' - day of year
   %        'date' - full date
   %
   %   for multiple waveforms, specifying XUNITs of 's', 'm', and 'h' will
   %   cause all the waveforms to be plotted starting at 0.  An XUNIT of
   %   'date' will force all waveforms to plot starting at their starttimes.
   %
   %   the default XUNIT is seconds
   %
   %   plot(waveform, 'axeshandle', axh, ...) plots the waveform in the axes
   %   defined by axh, rather than starting with a new figure.
   %
   %   plot(waveform, 'starttime', datenum(2000,1,1,1,0,0), 'endtime', datenum(2001,1,1,1,10,0), ...)
   %   will force the plot to start and end at those times, regardless of
   %   the time data in the waveform.
   %
   %
   %  For the following examples:
   %  % W is a waveform, and W2 is a smaller waveform (from within W)
   %  W = waveform('SSLN','SHZ','04/02/2005 01:00:00', '04/02/2005 01:10:00');
   %  W2 = extract(W,'date','04/02/2005 01:06:10','04/02/2005 01:06:33');
   %
   % EXAMPLE 1:
   %   % This example plots the waveforms at their absolute times...
   %   plot(W,'xunit','date'); % plots the waveform in blue
   %   hold on;
   %   h = plot(W2,'xunit','date', 'r', 'linewidth', 1);
   %          %plots your other waveform in red, and with a wider line
   %
   % EXAMPLE 2:
   %   % This example plots the waveforms, starting at time 0
   %   plot(W); % plots the waveform in blue with seconds on the x axis
   %   hold on;
   %   plot(W2,'xunit','s', 'color', [.5 .5 .5]);  % plots your other
   %                                       % waveform, starting in unison
   %                                       % with the prev waveform, then
   %                                       % change the color of the new
   %                                       % plot to grey (RGB)
   %
   %  For a list of properties you can set (such as color, linestyle, etc...)
   %  type get(h) after plotting something.
   %
   %  also, now Y can be autoscaled with the property pair: 'autoscale',true
   %  although it only works for single waveforms...
   %
   %  see also DATETICK, WAVEFORM/EXTRACT, PLOT
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   % modified 11/17/2008 by Jason Amundson (amundson@gi.alaska.edu) to allow
   % for "day of year" flag
   %
   % 11/25/2008 changed how parameters are parsed, fixing a bug where you
   % could not specify both an Xunit and a plot-style ('.', for example)
   %
   % individual frequencies used instead of assumed to be equal
   
   
   if isscalar(w),
      yunit = get(w,'units');
   else
      yunit = unique(get(w,'units')); %
   end
   
   %secs = 1;
   % mins = 60;
   % hrs = 3600;
   % days = 3600*24;
   
   %Look for an odd number of arguments beyond the first.  If there are an odd
   %number, then it is expected that the first argument is the formatting
   %string.
   hasExtraArg = mod(numel(varargin),2);
   if hasExtraArg
      proplist=  parseargs(varargin(2:end));
   else
      proplist=  parseargs(varargin);
   end
   
   
   
   [isfound,useAutoscale,proplist] = getproperty('autoscale',proplist,false);
   [isfound,xunit,proplist] = getproperty('xunit',proplist,'s');
   [isfound,currFontSize,proplist] = getproperty('fontsize',proplist,8);
   
   % new properties added by Glenn 2016/10/12
   [isfound,axeshandle,proplist] = getproperty('axeshandle',proplist,0);
   [isfound,startTime,proplist] = getproperty('startTime',proplist,0);
   [isfound,endTime,proplist] = getproperty('endTime',proplist,0);
   if axeshandle == 0
       fh = figure;
       axeshandle = axes();
   end
   %%%%%%%%% Glenn 2016/10/12 new autoscale method
   if useAutoscale
       w = normalize(w); % a new method
       for c=1:numel(w)
            w(c) = w(c) + numel(c)+1-c;
       end
   end
   %%%%%%%%%%%%% see old method bwlow (after plot) %%%%%
   
   if startTime~=0 || endTime~=0
       % extract
       [snum enum] = gettimerange(w);
       snum=min(snum);
       enum=max(enum);
       if startTime == 0
           startTime = snum;
       end
       if endTime == 0
           endTime = enum;
       end
       w = extract(w, 'time', snum, enum);
   end
   
   [xunit, xfactor] = parse_xunit(xunit);
   
   switch lower(xunit)
      case 'date'
         % we need the actual times...
         tv = get(w,'timevector');
         if ~isa(tv,'cell')
            tv = {tv}; %make it a cell for ease of use...
         end
         % preAllocate Xvalues
         tvl = zeros(size(tv));
         for n=1:numel(tv)
            tvl(n) = numel(tv{n}); %tvl : TimeVectorLength
         end
         
         Xvalues = nan(max(tvl),numel(w)); %fill empties with NaN (no plot)
         
         for n=1:numel(tv)
            Xvalues(1:tvl(n),n) = tv{n};
         end
         
         
      case 'day of year'
         startvec = datevec(get(w,'start'));
         dec31 = datenum([startvec(1)-1,12,31,0,0,0]); % 12/31/xxxx of previous year in Matlab format
         startdoy = datenum(get(w,'start')) - dec31;
         
         dl = zeros(size(w));
         for n=1:numel(w)
            dl(n) = get(w(n),'data_length'); %dl : DataLength
         end
         
         Xvalues = nan(max(dl),numel(w));
         
         freqs = get(w,'freq');
         for n=1:numel(w)
            Xvalues(1:dl(n),n) = (1:dl(n))./ freqs(n) ./ ...
               xfactor + startdoy(n) - 1./freqs(n)./xfactor;
         end
         
      otherwise,
         %dl = zeros(size(w));
         dl = get(w,'data_length');
         %for n=1:numel(w)
         %  dl(n) = length(w(n).data); %dl : DataLength
         %end
         
         Xvalues = nan(max(dl),numel(w));
         
         freqs = get(w,'freq');
         for n=1:numel(w)
            Xvalues(1:dl(n),n) = (1:dl(n))./ freqs(n) ./ xfactor;
         end
   end
   
   
   if hasExtraArg
      varargin = [varargin(1),property2varargin(proplist)];
   else
      varargin = property2varargin(proplist);
   end
   % %
   
   if axeshandle == 0
       h = plot(Xvalues, double(w,'nan') , varargin{:} );
   else
       h = plot(axeshandle, Xvalues, double(w,'nan') , varargin{:} ); 
   end
   
   %%%%%%%%% Glenn 2016/10/12 override this with clean simple method above
%    if useAutoscale
%       yunit = autoscale(h, yunit);
%    end
   % new method
   if useAutoscale
       w = normalize(w); % a new method
       for c=1:numel(w)
            w(c) = w(c) + numel(c)+1-c;
       end
   end
   %%%%%%%%%%%%%
   
   yh = ylabel(axeshandle,yunit,'fontsize',currFontSize);
   
   xh = xlabel(axeshandle,xunit,'fontsize',currFontSize);
   switch lower(xunit)
      case 'date'
         datetick('keepticks','keeplimits');
   end
   if isscalar(w)
      th = title(axeshandle,sprintf('%s (%s) - starting %s',...
         get(w,'station'),get(w,'channel'),get(w,'start_str')),'interpreter','none');
   else
      th = title(axeshandle,sprintf('Multiple waves.  wave(1) = %s (%s) - starting %s',...
         get(w(1),'station'),get(w(1),'channel'),get(w(1),'start_str')),'interpreter','none');
   end;
   
   
   
   %set(th,'fontsize',currFontSize);
   set(axeshandle,'fontsize',currFontSize);
   %% return the graphics handles if desired
   if nargout >= 1,
      varargout(1) = {h};
   end
   
   % return additional information in a structure: when varargout ==2
   plothandles.title = th;
   plothandles.xunits = xh;
   plothandles.yunits = yh;
   if nargout ==2,
      varargout(2) = {plothandles};
   end
end