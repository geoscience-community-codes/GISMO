function varargout = plot(TC, varargin)

%PLOT plots a threecomp object
%   H = PLOT(TC, ...) creates a simple plot of the three traces contained in the
%   threecomp object TC. Only one threecomp object can be plotted in a
%   single function call. It is possible however to overlay subsequent
%   threecomp objects on the same axes. Trace amplitudes are scaled
%   independently for each event, but accurately reflect the relative
%   amplitudes between components. The default x-axis displays time in
%   seconds relative to the trigger time. This can be overridden however
%   using any of the waveform time scale options. See WAVEFORM/PLOT. If
%   included, H returns a 3x1 vector of handles - one for each trace. These
%   can used to further customize the plot. See GET(H) for options that can
%   be set.
%
%   PLOT(TC,...,'scale',AMP,...) scales the trace amplitudes by a factor of
%   AMP. Default AMP value is 1.
%
%   PLOT(TC,...,'xunit',XVALUE,...) sets the units for the xaxis.
%   Possible values for XVALUE are
%     'seconds' or 's':         seconds
%     'minutes' or 'm':         minutes
%     'hours' or 'h':           hours
%     'day_of_year' or 'doy':   day of year
%     'date':                   full date
%
%   PLOT(TC, ...,'PROPERTYNAME',PROPERTYVALUE,...) accepts the standard
%   options allowed by the native Matlab plot function to set colors, line
%   styles, widths, etc. For example, to make a very ugly plot, try:
%       h = plot(TC(1),'--','LineWidth',5,'Color',[1 .5 .5])
%
%  see also waveform/plot

% Code borrowed heavily from waveform/plot by C. Reyes. In particular the
% argument handling was lifted directly from waveform/plot, including the
% necessary private functions. This was done to provide a comparable style
% of argument handling and axis options.
%
% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if isscalar(TC),
  yunit = get(TC.traces(1),'units');
    w = TC.traces;
else
    error('Threecomp:plot:tooManyObjects', ...
        ['Plot only operates on a single threecomp object. ' ...
        'Select a single object using an index such as TC(n).']);
end


% CHECK TO SEE IF THERE IS A FORMATTING STRING (VARARGIN IS ODD)
hasExtraArg = mod(numel(varargin),2);
if hasExtraArg
  proplist=  parseargs(varargin(2:end));
else
  proplist=  parseargs(varargin);
end


% CHECK FOR CUSTOM PROPERTIES
[isfound,xunit,proplist] = getproperty('xunit',proplist,'s');
[isfound,scale,proplist] = getproperty('scale',proplist,1);


% GET SCALING FACTOR FOR X AXIS
mins = 60;
hrs = 3600;
days = 3600*24;
switch lower(xunit)
  case {'m','minutes'}
    xunit = 'Minutes';
    xfactor = mins;
  case {'h','hours'}
    xunit = 'Hours';
    xfactor = hrs;
  case {'d','days'}
    xunit = 'Days';
    xfactor = days;
  case {'doy','day_of_year'}
% GET A SCALING FACTOR FOR
    xunit = 'Day of Year';
    xfactor = days;
  case 'date',
    xunit = 'Date';
    xfactor = 1 / get(w(1),'freq');
  otherwise,
    xunit = 'Seconds';
    xfactor = 1;
end


% CREATE TIME VECTORS
switch lower(xunit)
  case 'date'
    % we need the actual times...
    tv = get(w,'timevector');
    if ~isa(tv,'cell')
      tv = {tv}; %make it a cell for ease of use...
    end
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
    dec31 = datenum(startvec(1)-1,12,31); % 12/31/xxxx of previous year in Matlab format
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
    dl = get(w,'data_length');
    Xvalues = nan(max(dl),numel(w));
    freqs = get(w,'freq');
    for n=1:numel(w)
      Xvalues(1:dl(n),n) = (1:dl(n))./ freqs(n) ./ xfactor;
    end
    timeOffset = 86400 / xfactor * (TC.trigger - get(w(1),'START'));
    Xvalues = Xvalues - timeOffset;
end


% PASS ALONG PROPERTY ARGUMENTS
if hasExtraArg
  varargin = [varargin(1),property2varargin(proplist)];
else
  varargin = property2varargin(proplist);
end


% PLOT TRACES
hold on; box on;
set(gcf,'Color','w');
normval = max(max(abs(w)));
w = scale * w./normval;			% do not normalize trace amplitudes
w(1) = w(1)+1;
w(2) = w(2)+0;
w(3) = w(3)-1;
h = plot(Xvalues, double(w,'nan') , varargin{:} );
xlim([min(Xvalues(:,1)) max(Xvalues(:,1))]);


% ADJUST DEFAULT TRACE COLORS
colors = get(h,'color');
if all(colors{1}==[0 0 1]) && all(colors{2}==[0 0.5 0]) && all(colors{3}==[1 0 0])
    set(h(1),'Color',[0 0 0.4]);
    set(h(2),'Color',[0.4 0 0]);
    set(h(3),'Color',[0 0.4 0]);
end


% SET YAXIS AND ADD SCALE BAR
set(gca,'YTick',[-0.5 0.5]);
set(gca,'YTickLabel',num2str(normval*[-1 1]',3));
xLimits = get(gca,'XLim');
xLoc = xLimits(1) + 0.01 * (xLimits(2) - xLimits(1));
plot([xLoc xLoc],[-0.5 0.5],'-','Color',[0.6 0.6 0.6]);


% LABEL DATA AXIS IF NECESSARY
xlabel(xunit);
switch lower(xunit)
  case 'date'
    datetick('keepticks','keeplimits');
end


% LABEL TRACES
chan = get(w,'CHANNEL');
orientation = TC.orientation;
text(2*xLoc,-0.8,[chan{3} ' ' num2str(round(orientation(5)),' [%d') ' ' num2str(round(orientation(6)),'%d]')],'FontSize',12);
text(2*xLoc,0.2,[chan{2} ' ' num2str(round(orientation(3)),' [%d') ' ' num2str(round(orientation(4)),'%d]')],'FontSize',12);
text(2*xLoc,1.2,[chan{1} ' ' num2str(round(orientation(1)),' [%d') ' ' num2str(round(orientation(2)),'%d]')],'FontSize',12);


% SET TITLE
NSCL = get(TC,'NSCL');
titleStr = ([ NSCL{1} '     at ' datestr(TC.trigger,'yyyy/mm/dd HH:MM:SS.FFF')]);
if isfield(w(1),'ORIGIN_ORID')
    orid = num2str(get(w(1),'ORIGIN_ORID'));
    titleStr = [titleStr '      orid: ' orid];
else
    title(titleStr,'FontSize',14,'Interpreter','none');
end
    

% RETURN HANDLE
if nargout == 1,
  varargout(1) = {h};
end


% PREP PRINT OUT
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.5 2 10 4.5] );
%print(gcf, '-depsc2', 'FIG_THREECOMP_PLOT.ps');


