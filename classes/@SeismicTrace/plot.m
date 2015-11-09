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
   
   
   
   %Look for an odd number of arguments beyond the first.  If there are an odd
   %number, then it is expected that the first argument is the formatting
   %string.
   
   [formatDescriptor, params] = peelFormat(varargin);
   p = parseParameters(params);
   xunit = p.Results.xunit;
   [xunit, Xvalues] = prepareXvalues(T, xunit);
   
   newParams = buildParameterList(formatDescriptor, p.Unmatched);
   ax = gca;
   plotHandles = struct(); % contain the various plotting handles
   plotHandles.axis = ax;
   plotHandles.lines = plot(ax, Xvalues, double(T,'nan') , newParams{:} );
   
      
   if p.Results.autoscale
      % modify yunit and rescale the plot data
      yunit = SeismicTrace.autoscale(plotHandles.lines, getYunit(T));
   else 
      yunit = getYunit(T);
   end
   
   switch lower(xunit)
      case 'date'
         datetick(ax, 'x', 'keepticks','keeplimits');
      otherwise
         % do nothing
   end
   
   % label the plot
   plotHandles.yunits = ylabel(ax, yunit, 'fontsize',p.Results.fontsize);
   plotHandles.xunits = xlabel(ax, xunit, 'fontsize',p.Results.fontsize);
   plotHandles.title = title(ax, getTitleText(T), 'interpreter', 'none');
   set(plotHandles.title,'fontsize', p.Results.fontsize);
   set(ax,'fontsize', p.Results.fontsize);
   
   % return the graphics handles if desired
   switch nargout
      case 0
         % do nothing
      case 1
         varargout = {plotHandles.lines};
      case 2
         varargout = {plotHandles.lines, plotHandles};
   end
end %plot

function [formatDescriptor, params] = peelFormat(params)
   %Look for an odd number of arguments beyond the first.  If there are an odd
   %number, then it is expected that the first argument is the formatting
   %string.
   hasOddInputs =  mod(numel(params),2);
   if hasOddInputs
      formatDescriptor = params{1};
      params(1)=[];
   else
      formatDescriptor = '';
   end
   
end
function p = parseParameters(argList)
   p = inputParser;
   p.KeepUnmatched = true;
   p.CaseSensitive = false;
   p.StructExpand = false;
   if ismethod(p,'addParameter')
      addParameter(p,'autoscale', false);
      addParameter(p,'xunit', 's');
      addParameter(p,'fontsize', 10);
   else % older usage: pre r2013b
      addParamValue(p,'autoscale', false);
      addParamValue(p,'xunit', 's');
      addParamValue(p,'fontsize', 10);
   end
   p.parse(argList{:}); % intercepted values end up in p.Results, all the rest goes to p.Unmatched
end

function yunit = getYunit(T)
   if isscalar(T)
      yunit = T.units;
   else
      yunit = arrayfun(@(tr) tr.units, T, 'UniformOutput',false);
      yunit = unique(yunit);
   end
end

function [xLabel, Xvalues] = prepareXvalues(T, xunit)
   [xLabel, xfactor] = parse_xunit(xunit);
   switch lower(xLabel)
      case 'date'
         traceLengths = T(:).nsamples();
         Xvalues = nan(max(traceLengths),numel(T)); %fill empties with NaN (no plot)
         for n=1:numel(T)
            Xvalues(1:traceLengths(n),n) = T(n).sampletimes;
         end
         
      case 'day of year'
         allstarts = T.firstsampletime();
         [y, ~, ~] = datevec(allstarts(:));
         dec31 = datenum(y,12,31,0,0,0); % 12/31/xxxx of previous year in Matlab format
         startdoy = datenum(allstarts(:)) - dec31;
         
         dl = T.nsamples();
                  
         Xvalues = nan(max(dl),numel(T));
         periodsInUnits = T.period() ./ xfactor;
         for n=1:numel(T)
            Xvalues(1:dl(n),n) = (0:dl(n)-1) .* periodsInUnits(n) + startdoy(n);
         end
         
      otherwise
         traceLengths = T(:).nsamples();
         Xvalues = nan(max(traceLengths), numel(T)); %preallocate
         timescales = [T.samplerate] .* xfactor;
         for n=1:numel(T)
            Xvalues(1:traceLengths,n) = (1:traceLengths) ./ timescales(n);
         end
   end
end
function titletext = getTitleText(T)
   if isscalar(T)
      titletext = sprintf('%s (%s) @ %3.2f samp/sec', T.name, T.start, T.samplerate);
   else
      titletext = sprintf('Multiple Traces.  Trace(1) = %s - starting %s', T(1).name, T(1).start);
   end;
end

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

function newParams = buildParameterList(formatDescriptor, paramStruct)
   fieldList = fieldnames(paramStruct);
   if isempty(fieldList)
      if ~isempty(formatDescriptor); 
         newParams = {formatDescriptor}; 
      else
         newParams = {};
      end
   else
      v = struct2cell(paramStruct);
      if ~isempty(formatDescriptor);
         newParams = [{formatDescriptor} horzcat(fieldList,v)];
      else
         newParams = horzcat(fieldList,v);
      end
   end
end