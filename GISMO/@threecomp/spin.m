function [TC,c2, c3] = spin(TCin,varargin)

%SPIN rotate and plot horizontal components
% SPIN(TC) rotates a single threecomp object TC through a range of
% horizontal orientations. By default, the range is [0:10:360].
%
% SPIN(TC,ORIENTATIONS) rotates the horizontal components to orientations
% specified by the numerical vector ORIENTATIONS.
%
% TC2 = SPIN(TC, ...) Returns the multiply-rotated threecomp object as TC2.
%
% [TC2, C2, C3] = SPIN(...) Returns the threecomp object TC2 as well as
% correlation objects C2 and C3 containing the traces from the second and
% third components (the horizontals).

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if numel(TCin)>1
    error('Threecomp:plot:tooManyObjects', ...
        ['Plot only operates on a single threecomp object. ' ...
        'Select a single object using an index such as TC(n).']);
end


if length(varargin)>=1
   if isa(varargin{1},'double') && numel(varargin{1})>3
        bearing = mod(varargin{1},360);
        bearing = reshape(bearing,numel(bearing),1);
   else
       error('Threecomp:spin:badOrientationList','orientation argument must be a numeric vector');
   end
else   
    bearing = [0:10:360]';   
end


% GENERATE ROTATED TRACES
TC = threecomp;
for n = 1:numel(bearing)
   TC(n) = rotate(TCin,bearing(n)); 
end
TC = reshape(TC,numel(TC),1);


% PLOT ROTATED TRACES
% This plotting approach makes use of the correlation toolbox.
bearing2Text = num2str(bearing);
bearing3Text = num2str(mod(bearing+90,360));
w = get(TC,'WAVEFORM');
trig = get(TC,'TRIGGER');

c2 = correlation(w(:,2),trig);
c3 = correlation(w(:,3),trig);
plot(c2,'raw',0.7)
set(gcf,'Position',[0 0 700 800]);
title([get(w(1,2),'NETWORK') '_' get(w(1,2),'STATION') '_' get(w(1,2),'CHANNEL') '_' get(w(1,2),'LOCATION')],'FontSize',15,'Interpreter','None');
set(gca,'yTickLabel',bearing2Text);
ylabel('Horizontal orientation (degrees)','FontSize',14);
%labelbackazimuth(bearing,TCin)

plot(c3,'raw',0.7)
set(gcf,'Position',[700 0 700 800]);
title([get(w(1,3),'NETWORK') '_' get(w(1,3),'STATION') '_' get(w(1,3),'CHANNEL') '_' get(w(1,3),'LOCATION')],'FontSize',15,'Interpreter','None');
set(gca,'yTickLabel',bearing3Text);
ylabel('Horizontal orientation (degrees)','FontSize',14);
%labelbackazimuth(bearing+90,TCin)


   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add lines to label backazimuth
%
% TODO: Disabled because the plotting function doesn't wrap 0 appropriately.

function labelbackazimuth(bearing,TC)

TC.backAzimuth
if ~isempty(TC.backAzimuth)
    baz = TC.backAzimuth;
    bazList = mod([baz baz+180],360);
    bazListOpp = mod([baz+90 baz+270],360);
    xLimit = get(gca,'XLim');
    if bazList(1)>=bearing(1) && bazList(1)<=bearing(end)
        height = (bazList(1)-bearing(1))/(bearing(end)-bearing(1))*length(bearing);
        plot(xLimit,[height height],'-','Color',[1 .7 .7],'LineWidth',5);
    end
    if bazList(2)>=bearing(1) && bazList(2)<=bearing(end)
        height = (bazList(2)-bearing(1))/(bearing(end)-bearing(1))*length(bearing);
        plot(xLimit,[height height],'--','Color',[0 0 .5]);
    end
    if bazListOpp(1)>=bearing(1) && bazListOpp(1)<=bearing(end)
        height = (bazListOpp(1)-bearing(1))/(bearing(end)-bearing(1))*length(bearing);
        plot(xLimit,[height height],'-','Color',[.7 .7 .7]);
    end
    if bazListOpp(2)>=bearing(1) && bazListOpp(2)<=bearing(end)
        height = (bazListOpp(2)-bearing(1))/(bearing(end)-bearing(1))*length(bearing);
        plot(xLimit,[height height],'-','Color',[.7 .7 .7]);
    end
end