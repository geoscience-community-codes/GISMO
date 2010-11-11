function plot2(TC,varargin)

%PLOT2 a figure of three component traces (depricated).
%  PLOT2(TC) Plots the three components of a threecomp object. Time axis is
%  relative to the trigger time. Note that plot only operates on a single
%  threecomp object at once. ** PLOT2 has been depricated and superceded by
%  PLOT which is follows mirrors waveform/plot. **
%
%  PLOT(TC,SCALE) scales the trace amplitudes by a factor of SCALE. Default
%  SCALE value is 1.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if numel(TC)>1
    error('Threecomp:plot:tooManyObjects', ...
        ['Plot only operates on a single threecomp object. ' ...
        'Select a single object using an index such as TC(n).']);
end


figure('Color','w','Position',[50 50 1200 400])
set(gcf,'DefaultAxesFontSize',14);
hold on; box on;

set(gcf,'DefaultAxesFontSize',14);
if length(varargin)>=1
   scale = varargin{1}; 
else 
    scale = 1;
end


% PLOT TRACES
w = TC.traces;
normval = max(max(abs(w)));
w = scale * w./normval;			% do not normalize trace amplitudes
plot(w(1)+1,'Color',[0 0 0.3]);
plot(w(2)+0,'Color',[0.3 0 0]);
plot(w(3)-1,'Color',[0 0.3 0]);



% SET X AXIS TO TIME RELATIVE TO TRIGGER
timeOffset = 86400 * (TC.trigger - get(w(1),'START'));
tickList = get(gca,'XTick');
tickIncrement = tickList(2) - tickList(1);
tickCenter = -1*round(timeOffset/tickIncrement);
tickListNew = timeOffset + tickIncrement *(tickCenter + [-10:10]);
tickListNewLabel = num2str(tickListNew'-timeOffset);
set(gca,'XTick',tickListNew);
set(gca,'XTickLabel',tickListNewLabel);


% ADD SCALE BAR
set(gca,'YTick',[-0.5 0.5]);
set(gca,'YTickLabel',num2str(normval*[-1 1]'));
xLimits = get(gca,'XLim');
xLoc = xLimits(1) + 0.01 * (xLimits(2) - xLimits(1));
plot([xLoc xLoc],[-0.5 0.5],'-','Color',[0.6 0.6 0.6]);


% LABEL TRACES
chan = get(w,'CHANNEL');
orientation = TC.orientation;
text(2*xLoc,-0.9,[chan{3} ' ' num2str(round(orientation(5)),' [%d') ' ' num2str(round(orientation(6)),'%d]')],'FontSize',14);
text(2*xLoc,0.1,[chan{2} ' ' num2str(round(orientation(3)),' [%d') ' ' num2str(round(orientation(4)),'%d]')],'FontSize',14);
text(2*xLoc,1.1,[chan{1} ' ' num2str(round(orientation(1)),' [%d') ' ' num2str(round(orientation(2)),'%d]')],'FontSize',14);


% SET TITLE
NSCL = get(TC,'NSCL');
titleStr = ([ NSCL{1} '     at ' datestr(TC.trigger,'yyyy/mm/dd HH:MM:SS.FFF')]);
if isfield(w(1),'ORIGIN_ORID')
    orid = num2str(get(w(1),'ORIGIN_ORID'));
    titleStr = [titleStr '      orid: ' orid];
else
    title(titleStr,'FontSize',14,'Interpreter','none');
end
    


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.5 2 10 4.5] );
%print(gcf, '-depsc2', 'FIG_THREECOMP_PLOT.ps');








