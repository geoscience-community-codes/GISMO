function mastercorr_plot_stats(W)

%MASTERCORR_PLOT_STATS plot statistics from master correlation algorithm
% W = MASTERCORR_PLOT_STATS(W) plots summary statistics following an
% application of MASTERCORR_SCAN. This summary is useful for assessing the
% quality and the nature of the detected events. The input waveform W may
% be any dimension. However it must contain the fields produced by
% MASTERCORR_SCAN including: MASTERCORR_TRIG, MASTERCORR_CORR,
% MASTERCORR_ADJACENT_CORR 
%
% *** NOTE ABOUT MULTIPLE WAVEFORMS ***
% This function is designed to accept NxM waveform matrices as input. In
% this case the plot will contain relevent data from all element waveforms
% of W. This is useful, for example, when W is a 24x1
% matrix of hourly waveforms. However, unexpected (or clever!) results may
% be produced when W is complicated by elements with different channels or
% master waveform snippets. For some uses it may prove wise to pass only
% selected elements of W to this function. For example:
% C = MASTERCORR_EXTRACT(W(1:5)) 
% 
% See also mastercorr_scan, mastercorr_extract

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% CHECK INPUTS
if nargin ~= 1
    error('Incorrect number of inputs');
end
if ~isa(W,'waveform') 
    error('First argument must be waveform objects');
end


% READ MASTERCORR FIELDS
trig = [];
corr = [];
corrAdj = [];
if numel(W)>1
    for n=1:numel(W)
        trig = [trig ; get(W(n),'MASTERCORR_TRIG')];
        corr = [corr ; get(W(n),'MASTERCORR_CORR')];
        corrAdj = [corrAdj ; get(W(n),'MASTERCORR_ADJACENT_CORR')];
        
    end
else
    trig = get(W,'MASTERCORR_TRIG');
    corr = get(W,'MASTERCORR_CORR');
    corrAdj = get(W,'MASTERCORR_ADJACENT_CORR');
end


if numel(trig)==0
   disp('No MASTERCORR_TRIG field in this data');
   return;
end



% SORT BY TIME
[tmp,index] = sort(trig);
trig = trig(index);
corr = corr(index);
corrAdj = corrAdj(index);




% MAKE PLOT
figure('Color','w','Position',[50 50 850 1100]);
box on; hold on;
set(gcf,'DefaultLineLineWidth',1);
set(gcf,'DefaultAxesFontSize',12);
set(gcf,'DefaultLineMarkerSize',5);


% TIME HISTORY
subplot(3,1,1);
plot([trig' ; trig'],[corr' ; corrAdj'],'-','Color',[0.7 0.7 0.7])
hold on;
plot(trig,corr,'ok','MarkerFaceColor','y')
xlim([min(trig) max(trig)]);
ylim([0.5 1.0]);
datetick('x','KeepLimits');
set(gca,'YGrid','on')
set(gca,'YTick',[0:.1:1]);
ylabel('Correlation coefficient')
legend('adjacent peak','location','SouthWest');

subplot(3,1,2);
plot(trig(2:end),86400*(trig(2:end)-trig(1:end-1)),'ko','MarkerFaceColor','y')
set(gca,'YScale','log');
xlim([min(trig) max(trig)]);
datetick('x','KeepLimits');
set(gca,'YGrid','on')
%set(gca,'YTick',10.^[1:10]);
ylabel('Time (s)')
legend('Event spacing','location','SouthWest');

subplot(3,1,3)
hist(corr,[0.5:0.01:1]);
xlim([0.5 1]);
h = findobj(gca,'Type','patch');
set(h,'FaceColor','y','EdgeColor','k')
legend('Correlation','location','SouthWest');


% PLOT INTEREVENT TIME AGAINST CORRELATION VALUE
%figure
%tDiff = 86400*(trig(2:end)-trig(1:end-1));
%plot([tDiff' ; tDiff'],[corr(2:end)' ; corr(1:end-1)'],'k-')
%hold on;
%plot(tDiff,max([corr(2:end)' ; corr(1:end-1)']),'ko');
%set(gca,'XScale','log');




%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );

