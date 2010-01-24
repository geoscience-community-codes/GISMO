function occurrenceplot(c,scale,clusternum);

% Private method. See ../plot for details.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end;

% if isempty(get(c,'LINK'))
%     error('LINK field must be filled in input object');
% end;

if isempty(get(c,'CORR'))
    error('CORR field must be filled in input object');
end;

if isempty(get(c,'CLUST'))
    error('CLUST field must be filled in input object');
end;

if ~isempty(get(c,'LAG'))
    disp('Note: Time corrections from LAG field have not been applied to traces. Each cluster will be aligned for plotting only. Note that actual data is unaffected.');
end;

% TEST FOR NUMBER OF CLUSTERS
if (max(clusternum) > max(c.clust))
    error(['Exceeded maximum cluster number. There are only ' num2str(max(c.clust)) ' clusters in this set of traces']);
end
if (numel(clusternum)> 10)
    error('The occurence plot is limited to no more than 8 clusters. Consider making two plots');
end



% MAKE FIGURE
% height = 100 + 200*numel(clusternum);
% if height>1200
% 	height = 1200;
% end;
height = 1200;
figure('Color','w','Position',[20 20 1000 height]);
set(gcf,'DefaultAxesFontSize',12);

% GET HISTOGRAM BINS
nmax = numel(clusternum);
if max(c.trig)-min(c.trig) > 730
    bins = datenum(min(c.trig)):30:datenum(max(c.trig));
elseif max(c.trig)-min(c.trig) > 14
    bins = datenum(min(c.trig)):1:datenum(max(c.trig));
else
    bins = datenum(min(c.trig)):1/24:datenum(max(c.trig));
end

% LOOP THROUGH CLUSTERS
for n = 1:nmax
	f = find(c,'clu',clusternum(n));
    c1 = subset(c,f);
	doplotrow(c1,n,nmax,bins,clusternum(n));
end;
%subplot(nmax,2,nmax*2-1);
%binsize = bins(2)-bins(1);
%xlabel(['bin size: ' num2str(binsize) ' days']);


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );
print(gcf, '-depsc2', 'FIG.ps')





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DOPLOTROW
% This function plots one row of the figure

function doplotrow(c1,n,nmax,bins,nclust)


if ~isempty(get(c1,'LAG'))
	c1 = adjusttrig(c1);
end

traces = get(c1,'TRACES');
if traces > 50
	include = 1:round(traces/20):traces;
else
	include = 1:1:traces;
end


% DO HISTOGRAM PLOT
subplot('Position',[.07 .99-.094*n .42 .09]);
T = get(c1,'TRIG');
N = histc(T,bins);
h1 = bar(bins,N,'b');
hold on;
ylabel('');
if n==nmax
    datetick('x');
else
   set(gca,'XTickLabel',[]); 
end
xlim([min(bins) max(bins)]);
XLIMS = get(gca,'Xlim');
PosX = XLIMS(1) + 0.03*(XLIMS(2)-XLIMS(1));
YLIMS = get(gca,'Ylim');
set(gca,'Ylim',YLIMS);  % not sure why this is necessary?
PosY = YLIMS(2) - 0.15*(YLIMS(2)-YLIMS(1));
text(PosX,PosY,['Cluster #' num2str(nclust)],'Color','k','FontWeight','bold');
 

% DO STACK PLOT
subplot('Position',[.5 .99-.094*n .47 .09]);
c1 = subset(c1,include);
Ts = 86400*(get(c1.W,'START')-c1.trig);
Te = 86400*(get(c1.W,'END')-c1.trig);
c1 = stack(c1);
c1 = norm(c1);
c1 = crop(c1,mean(Ts),mean(Te));
w = get(c1,'WAVEFORMS');
xlim([0 get(w(end),'DURATION_EPOCH')]);
plot(w,'Color',[.7 .7 .7],'LineWidth',.5);
hold on;
plot(w(end),'Color','k','LineWidth',1);
xlim([0 get(w(end),'DURATION_EPOCH')]);
ylabel(' '); set(gca,'YTickLabel',[]);
title('');
if n ~= nmax
   set(gca,'XTickLabel',''); 
   xlabel('');
else
    binsize = bins(2)-bins(1);
    xlabel(['bin size: ' num2str(binsize) ' days']);
end


XLIMS = get(gca,'Xlim');
PosX = XLIMS(2) - 0.03*(XLIMS(2)-XLIMS(1));
YLIMS = get(gca,'Ylim');
set(gca,'Ylim',YLIMS);  % not sure why this is necessary?
PosY = YLIMS(2) - 0.15*(YLIMS(2)-YLIMS(1));
text(PosX,PosY,[ num2str(numel(include)) ' of ' num2str(traces) ' traces shown'],'Color','k','FontWeight','bold','HorizontalAlignment','Right');
 


