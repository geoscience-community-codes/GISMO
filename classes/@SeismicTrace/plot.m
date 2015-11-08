function varargout = plot(T, varargin)
   %plot   plots a SeismicTrace
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
   %   W.plot(); % plots the waveform with seconds on the x axis
   %   hold on;
   %   W2.plot('xunit','s', 'color', [.5 .5 .5]);  % plots your other
   %                                       % waveform, starting in unison
   %                                       % with the prev waveform, then
   %                                       % change the color of the new
   %                                       % plot to grey (RGB)
   %
   %
   %  also, now Y can be autoscaled with the property pair: 'autoscale',true
   %  although it only works for single waveforms...
   %
   %  See also datetick, plot
   
   % AUTHOR: Celso Reyes, with contribution from Jason Amundson
   
   if isscalar(T),
      yunit = T.units;
   else
      yunit = arrayfun(@(tr) tr.units, T, 'UniformOutput',false); %
      yunit = unique(yunit);
   end
   
   %Look for an odd number of arguments beyond the first.  If there are an odd
   %number, then it is expected that the first argument is the formatting
   %string.
   
   evenInputs =  ~mod(nargin,2);
   hasFormatString = evenInputs && nargin > 1; % including the SeismicTrace
   if hasFormatString
      formString = varargin{1};
      varargin(1)=[];
   end
   
   p = inputParser;
   p.KeepUnmatched = true;
   p.CaseSensitive = false;
   p.StructExpand = false;
   addParameter(p,'autoscale', false);
   addParameter(p,'xunit', 's');
   addParameter(p,'fontsize', 10);
   p.parse(varargin{:}); % intercepted values end up in p.Results, all the rest goes to p.Unmatched
   xunit = p.Results.xunit;
   
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
   
   % put together a new varargin to pass to the plotting routine.
   f = fieldnames(p.Unmatched);
   if isempty(f)
      if hasFormatString; newParams = {formString}; else newParams = {}; end
   else
      v = struct2cell(p.Unmatched);
      if hasFormatString;
         newParams = [{formString} horzcat(f,v)];
      else
         newParams = horzcat(f,v);
      end
   end
   h = plot(Xvalues, double(T,'nan') , newParams{:} );
   
   if p.Results.autoscale
      yunit = SeismicTrace.autoscale(h, yunit);
   end
   
   yh = ylabel(yunit,'fontsize',p.Results.fontsize);
   
   xh = xlabel(xunit,'fontsize',p.Results.fontsize);
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
   
   set(th,'fontsize',p.Results.fontsize);
   set(gca,'fontsize',p.Results.fontsize);
   % return the graphics handles if desired
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
end %plot


function [unitName, secondMultiplier] = parse_xunit(unitName)
   % parse_xunit returns a labelname and a multiplier for an incoming xunit
   % value.  This routine was removed to centralize this function
   % [unitName, secondMultiplier] = parse_xunit(unitName)
   
   switch lower(unitName)
      case {'m','minutes'}
         unitName = 'Minutes';
         secondMultiplier = 60; % seconds / minute
      case {'h','hours'}
         unitName = 'Hours';
         secondMultiplier = 3600; % seconds / hour
      case {'d','days'}
         unitName = 'Days';
         secondMultiplier = 86400; % seconds / day
      case {'doy','day_of_year'}
         unitName = 'Day of Year';
         secondMultiplier = 86400; % seconds/ day
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