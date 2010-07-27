function response_plot(response,xLimits,noLegend)

%RESPONSE_PLOT plot an instrument response
%  RESPONSE_PLOT(RESPONSE) creates instrument response plots for a response
%  structure given by RESPONSE. See DB_GET_RESPONSE for the format of a
%  response structure.
%
%  RESPONSE_PLOT(RESPONSE,XLIMITS) specifies explicit limits on the x-axes.
%
%  RESPONSE_PLOT(RESPONSE,XLIMITS,'nolegend') supresses the legend. This
%  may be desireable for large numbers of responses.

% 
% if numel(response) > 10
%     response = response(1:10);
%     warning('Only the first 10 responses will be included');
% end



figure('Color','w','Position',[20 20 680 880]);
set(gcf,'DefaultAxesFontSize',14);
set(gcf,'DefaultLineLineWidth',2);
colorList = jet;
if numel(response)==1
    row = 1;
else
    row = 1 + round([0:numel(response)-1] ./ (numel(response)-1) * (size(colorList,1)-1));
end


subplot(2,1,1);
hold on; box on;
for n = 1:numel(response)
    plot( response(n).frequencies , angle(response(n).values)*180/pi , '-' , 'Color' , colorList(row(n),:) )
end
set(gca,'XScale','log');
if exist('xLimits')==1
    xlim(xLimits);
end
ylim([-180 180]);
set(gca,'YTick',[-180 -135 -90 -45 0 45 90 135 180]);
ylabel('Phase (degrees)');



subplot(2,1,2);
hold on; box on;
for n = 1:numel(response)
    plot(response(n).frequencies,abs(response(n).values),'-','Color',colorList(row(n),:) )
end
set(gca,'XScale','log');
set(gca,'YScale','log');
if exist('xLimits')==1
    xlim(xLimits);
end
ylim([10e-4 3]);
xlabel('Frequency (Hz)');
ylabel('Normalized amplitude');



%% CREATE LEGEND INFORMATION
%if ~exist('noLegend')
%    for n = 1:numel(response)
%        textLabel(n) = {[ get(response(n).scnl,'NSCL_STRING') '    ' datestr(response(n).time,29) ]};
%    end
%    legend(textLabel,'Location','South','Interpreter','None','FontSize',8);
%end


% SETUP PRINTED FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );

