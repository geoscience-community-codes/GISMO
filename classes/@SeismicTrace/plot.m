function varargout = plot(T, varargin)
   %PLOT plots a SeismicTrace
   %   h = plot(trace)
   %   Plots a waveform object, handling the title and axis labeling.  The
   %      output parameter h is optional.  If u, thto the waveform
   %   plots will be returned.  These can be used to change properties of the
   %   plotted waveforms.
   %
   %   h = trace.plot(...)
   %   Plots a waveform object, passing additional parameters to matlab's PLOT
   %   routine.
   %
   %   h = trace.plot('xunit', xvalue, ...)
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
   %  For the following examples:
   %  % W is a waveform, and W2 is a smaller waveform (from within W)
   %  W = waveform('SSLN','SHZ','04/02/2005 01:00:00', '04/02/2005 01:10:00');
   %  W2 = extract(W,'date','04/02/2005 01:06:10','04/02/2005 01:06:33');
   %
   % EXAMPLE 1:
   %   % This example plots the waveforms at their absolute times...
   %   W.plot('xunit','date'); % plots the waveform in blue
   %   hold on;
   %   h = W2.plot('xunit','date', 'r', 'linewidth', 1);
   %          %plots your other waveform in red, and with a wider line
   %
   % EXAMPLE 2:
   %   % This example plots the waveforms, starting at time 0
   %   W.plot(); % plots the waveform in blue with seconds on the x axis
   %   hold on;
   %   W2.plot('xunit','s', 'color', [.5 .5 .5]);  % plots your other
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
   %  see also DATETICK, SeismicTrace.plot, PLOT
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   %
   % modified 11/17/2008 by Jason Amundson (amundson@gi.alaska.edu) to allow
   % for "day of year" flag
   %
   % 11/25/2008 changed how parameters are parsed, fixing a bug where you
   % could not specify both an Xunit and a plot-style ('.', for example)
   %
   % individual sample rates used instead of assumed to be equal
   
   
   if isscalar(T),
      yunit = T.units;
   else
      yunit = arrayfun(@(tr) tr.units, T, 'UniformOutput',false); %
      yunit = unique(yunit);
   end
   
   %Look for an odd number of arguments beyond the first.  If there are an odd
   %number, then it is expected that the first argument is the formatting
   %string.
   [formString, proplist] = getformatstring(varargin);
   hasExtraArg = ~isempty(formString);
   [~, useAutoscale, proplist] = getproperty('autoscale',proplist,false);
   [~, xunit, proplist] = getproperty('xunit',proplist,'s');
   [~, currFontSize, proplist] = getproperty('fontsize',proplist,10);
   
   [xunit, xfactor] = parse_xunit(xunit);
   
   switch lower(xunit)
      case 'date'
         % we need the actual times...
         for n=numel(T):-1:1
            tv(n) = {T(n).sampletimes};
         end
         % preAllocate Xvalues
         tvl = zeros(size(tv));
         for n=1:numel(tv)
            tvl(n) = numel(tv{n}); %tvl : TimeVectorLength
         end
         
         Xvalues = nan(max(tvl),numel(T)); %fill empties with NaN (no plot)
         
         for n=1:numel(tv)
            Xvalues(1:tvl(n),n) = tv{n};
         end
         
         
      case 'day of year'
         allstarts = [T.mat_starttime];
         startvec = datevec(allstarts(:));
         dec31 = datenum(startvec(1)-1,12,31,0,0,0); % 12/31/xxxx of previous year in Matlab format
         startdoy = datenum(allstarts(:)) - dec31;
         
         dl = zeros(size(T));
         for n=1:numel(T)
            dl(n) = numel(T(n).data); %dl : DataLength
         end
         
         Xvalues = nan(max(dl),numel(T));
         periodsInUnits = T.period() ./ xfactor;
         for n=1:numel(T)
            Xvalues(1:dl(n),n) = (0:dl(n)-1) .* periodsInUnits(n) + startdoy(n);
            % (1:dl(n)) .* periodsInUnits(n) + startdoy(n) - periodsInUnits(n);
         end
         
      otherwise,
         longest = max(arrayfun(@(tr) numel(tr.data), T));
         while numel(longest) > 1
            longest = max(longest);
         end
         Xvalues = nan(longest, numel(T));
         for n=1:numel(T)
            dl = numel(T(n).data);
            Xvalues(1:dl,n) = (1:dl) ./ T(n).samplerate ./ xfactor;
         end
   end
   
   if hasExtraArg
      varargin = [varargin(1),property2varargin(proplist)];
   else
      varargin = property2varargin(proplist);
   end
   % %
   
   h = plot(Xvalues, double(T,'nan') , varargin{:} );
   
   if useAutoscale
      yunit = SeismicTrace.autoscale(h, yunit);
   end
   
   yh = ylabel(yunit,'fontsize',currFontSize);
   
   xh = xlabel(xunit,'fontsize',currFontSize);
   switch lower(xunit)
      case 'date'
         datetick('keepticks','keeplimits');
   end
   if isscalar(T)
      th = title(sprintf('%s (%s) @ %3.2f samp/sec',...
         T.name, T.start, T.samplerate),'interpreter','none');
   else
      th = title(sprintf('Multiple Traces.  wave(1) = %s (%s) - starting %s',...
         T(1).station, T(1).channel, T(1).start),'interpreter','none');
   end;
   
   
   
   set(th,'fontsize',currFontSize);
   set(gca,'fontsize',currFontSize);
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
   
   function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
      %GETPROPERTY returns a property value from a property list, or a default
      %  value if none is available
      %[isfound, foundvalue, properties] =
      %      getproperty(desiredproperty,properties,defaultvalue)
      %
      % returns a property value (if found) from a property list, removing that
      % property pair from the list.  only removes the first encountered property
      % name.
      
      pmask = strcmpi(desiredproperty,properties.name);
      isfound = any(pmask);
      if isfound
         foundlist = find(pmask);
         foundidx = foundlist(1);
         foundvalue = properties.val{foundidx};
         properties.name(foundidx) = [];
         properties.val(foundidx) = [];
      else
         if exist('defaultvalue','var')
            foundvalue = defaultvalue;
         else
            foundvalue = [];
         end
         % do nothing to properties...
      end
   end
   
   function [formString, proplist] = getformatstring(arglist)
      hasExtraArg = mod(numel(arglist),2);
      if hasExtraArg
         proplist =  parseargs(arglist(2:end));
         formString = arglist{1};
      else
         proplist =  parseargs(arglist);
         formString = '';
      end
   end
   
   function c = property2varargin(properties)
      %PROPERTY2VARARGIN makes a cell array from properties
      %  c = property2varargin(properties)
      % properties is a structure with fields "name" and "val"
      c = {};
      c(1:2:numel(properties.name)*2) = properties.name;
      c(2:2:numel(properties.name)*2) = properties.val;
   end
   function [properties] = parseargs(arglist)
      % PARSEARGS creates a structure of parameternames and values from arglist
      %  [properties] = parseargs(arglist)
      % parse the incoming arguments, returning a cell with each parameter name
      % as well as a cell for each parameter value pair.  parseargs will also
      % doublecheck to ensure that all pnames are actually strings... otherwise,
      % there will be a mis-parse.
      %check to make sure these are name-value pairs
      %
      % see also waveform/private/getproperty, waveform/private/property2varargin
      
      argcount = numel(arglist);
      evenArgumentCount = mod(argcount,2) == 0;
      if ~evenArgumentCount
         error('Waveform:parseargs:propertyMismatch',...
            'Odd number of arguments means that these arguments cannot be parameter name-value pairs');
      end
      
      %assign these to output variables
      properties.name = arglist(1:2:argcount);
      properties.val = arglist(2:2:argcount);
      
      for i=1:numel(properties.name)
         if ~ischar(properties.name{i})
            error('Waveform:parseargs:invalidPropertyName',...
               'All property names must be strings.');
         end
      end
   end
   function [unitName, secondMultiplier] = parse_xunit(unitName)
      % PARSE_XUNIT returns a labelname and a multiplier for an incoming xunit
      % value.  This routine was removed to centralize this function
      % [unitName, secondMultiplier] = parse_xunit(unitName)
      secsPerMinute = 60;
      secsPerHour = 3600;
      secsPerDay = 3600*24;
      
      switch lower(unitName)
         case {'m','minutes'}
            unitName = 'Minutes';
            secondMultiplier = secsPerMinute;
         case {'h','hours'}
            unitName = 'Hours';
            secondMultiplier = secsPerHour;
         case {'d','days'}
            unitName = 'Days';
            secondMultiplier = secsPerDay;
         case {'doy','day_of_year'}
            unitName = 'Day of Year';
            secondMultiplier = secsPerDay;
         case 'date',
            unitName = 'Date';
            secondMultiplier = nan; %inconsequential!
         case {'s','seconds'}
            unitName = 'Seconds';
            secondMultiplier = 1;
            
         otherwise,
            unitName = 'Seconds';
            secondMultiplier = 1;
      end
   end
end %plot
