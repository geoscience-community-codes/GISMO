function varargout = plot(T, varargin)
   %plot   plots a SeismicTrace
   %   plot(traces) Plots traces, handling the title and axis labeling.
   %  
   %   [h, handles] = plot(traces) will return handles to various elements
   %   of the plot.  H will contain the line handles, while HANDLES will be
   %   a struct that includes handles to the line as well as titles and
   %   axis labels.
   %
   %   h = plot(traces, ...)
   %   Plots a trace, passing additional parameters to matlab's PLOT
   %   routine.  Trace specific parameters are discussed below.
   %
   %   h = plot(..., 'xunit', xvalue)
   %   sets the xunit property of the graph, which is used to determine how
   %   the times of the traces are interpereted.  Possible values for XVALUE
   %   are 's', 'm', 'h', 'd', 'doy', 'date'.
   %
   %        'seconds' - seconds
   %        'minutes' - minutes
   %        'hours' - hours
   %        'day_of_year' - day of year
   %        'date' - full date
   %        'samples' - sample number
   %
   %   for multiple traces, specifying XUNITs of 's', 'm', and 'h' will
   %   cause all the traces to be plotted starting at 0.  An XUNIT of
   %   'date' will force all traces to plot starting at their starttimes.
   %
   %   the default XUNIT is seconds
   %
   %  h = plot(..., 'fontsize', value) will set the fontsize for the axis,
   %  title, and labels.
   %
   %  For the following examples:
   %  % T is a SeismicTrace, and T2 is a smaller trice (from within T)
   %  T = SeismicTrace('SSLN','SHZ','04/02/2005 01:00:00', '04/02/2005 01:10:00');
   %  T2 = extract(T,'date','04/02/2005 01:06:10','04/02/2005 01:06:33');
   %
   % EXAMPLE 1:
   %   % This example plots the traces at their absolute times...
   %   plot(T, 'xunit','date'); % plots the trace
   %   hold on;
   %   h = T2.plot('xunit','date', 'r', 'linewidth', 1);
   %          % plots your other trace in red, and with a wider line
   %
   % EXAMPLE 2:
   %   % This example plots the traces, starting at time 0
   %   plot(T); % plots the trace with seconds on the x axis
   %   hold on;
   %   plot(T2, 'xunit','s', 'color', [0.5 0.5 0.5]);  % plots your other
   %                                       % trace, starting in unison
   %                                       % with the prev trace, then
   %                                       % change the color of the new
   %                                       % plot to grey (RGB)
   %
   %
   %  Y values can be autoscaled with the property pair: 'autoscale',true
   %  although it only works for single traces...
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
   %peelFormat   identifies and removesline format descriptor from the argument list
   %
   %   [formatDescriptor, params] = peelFormat(params) will look to see if
   %   there are an uneven number of [property, value] pairs.  If there are,
   %   then it is assumed that the first argument is the formatting string
   %   sample formatting strings: 'b', '-' 's+', etc.
   %
   %   See also plot
   hasOddInputs =  mod(numel(params),2);
   if hasOddInputs
      formatDescriptor = params{1};
      params(1)=[];
   else
      formatDescriptor = '';
   end
   
end

function p = parseParameters(argList)
   %parseParameters   return an inputParer object containing the parsed args
   %   p = parseParameters(argList)
   %
   %   p.Results contains arguments specific to the trace implementation of plot.
   %   These are: autoscale,xunit, and fontsize
   %   All other values are returned in p.unmatched.
   %
   %   See also inputParser
   p = inputParser;
   p.KeepUnmatched = true;
   p.CaseSensitive = false;
   p.StructExpand = false;
   if verLessThan('matlab','8.2'); %r2013b
      addParameter = @addParamValue;
   end
      addParameter(p,'autoscale', false);
      addParameter(p,'xunit', 's');
      addParameter(p,'fontsize', 10);
   p.parse(argList{:});
end

function yunit = getYunit(T)
   %getYunit   returns the unique labels for Y based on the traces' units
   if isscalar(T)
      yunit = T.units;
   else
      yunit = arrayfun(@(tr) tr.units, T, 'UniformOutput',false);
      yunit = unique(yunit);
   end
end

function [xLabel, Xvalues] = prepareXvalues(T, xunit)
   %prepareXvalues   changes x axis based on type of plot
   %   [xLabel, Xvalues] = prepareXvalues(T, xunit)
   %
   %   xunit:
   %      'date'  - use the sample times for the x axis
   %      'day of year' - use the day of year for the x axis
   %      otherwise, uses seconds for the x axis
   [xLabel, xfactor] = parse_xunit(xunit);
   
   switch lower(xLabel)
      case 'date'
         % sample Times
         traceToX = @(tr) tr.sampletimes;
         
      case {'day of year','day_of_year'}
         % sampleNumber (from 0)  .*  periodInUnits  + dayOfYear
         traceToX = @(tr) (0:(tr.nsamples()-1)) .* ...
                          (tr.period() ./ xfactor) + ...
                          dayOfYearFromTrace(tr);
         
      case 'samples'
         % sampleNumber
         traceToX = @(tr) 1:tr.nsamples;
         
      otherwise
         % sampleNumber  ./  timescale
         traceToX = @(tr) (1:tr.nsamples) ./ ...
            (tr.samplerate .* xfactor);
   end
   
   traceLengths = T(:).nsamples();
   Xvalues = nan(max(traceLengths), numel(T)); %preallocate
   for n=1:numel(T)
      Xvalues(1:traceLengths(n),n) = traceToX(T(n));
   end
   
end

function doy = dayOfYearFromTrace(T)
   %dayOfYearFromTrace
   [y, ~, ~] = datevec(T.firstsampletime());
   doy = datenum(T.firstsampletime()) - datenum(y,12,31,0,0,0);
end
   
function titletext = getTitleText(T)
   %getTitleText   generate title text based on size of trace plus contents
   if isscalar(T)
      titletext = sprintf('%s (%s) @ %3.2f samp/sec', T.name, T.start, T.samplerate);
   else
      titletext = sprintf('Multiple Traces.  Trace(1) = %s - starting %s', T(1).name, T(1).start);
   end;
end

function [unitName, secondMultiplier] = parse_xunit(unitName)
   %parse_xunit   returns a labelname and a multiplier for an incoming
   %   xunit value.  This routine was removed to centralize this function
   %   [unitName, secondMultiplier] = parse_xunit(unitName)
   
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
      case {'samples'}
         unitName = 'Samples';
         secondMultiplier = nan;
      otherwise,
         unitName = 'Seconds';
         secondMultiplier = 1;
   end
end

function newParams = buildParameterList(formatDescriptor, paramStruct)
   %newParams   creates argument list from a struct to pass to the builtin plot
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
         newParams = newParams';
         newParams = newParams(:);
      end
   end
end
