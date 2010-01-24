function corrderived_plot_swarm_history(c,varargin)

%SEISMICSWARM_PLOT_HISTORY plots relevent details of seismic swarms
% SEISMICSWARM_PLOT_HISTORY(C)reads correlation object C and plots various
% parameters to characterize the swarm. Typical input will be a correlation
% object containing waveforms from a single station for numerous events. 
% This function requires that the CLUST and WAVEFORM fields of the
% correlation object be filled. The heavily lifting will have already been
% done by the LINKAGE and CLUSTER functions. This is predominantly a
% plotting function. Plots include:
%    - A histogram of all events and clustered events
%    - An amplitude measure of all events
%    - A plot showing the "lifespan" of each cluster
%
% SEISMICSWARM_PLOT_HISTORY(C,CLUSTERSIZE) specifies the minimum number of
% events to be counted as a cluster. The default is 5. Note that the
% clusters defined in the correaltion object may have a few as 1 event. For
% analysis purposes however, the user will often want to set a minimum
% size for significant clusters. CLUSTERSIZE is this value.
%
% The trace amplitude plot is based on the maximum value of the hilbert
% transform of the input data. The user may wish to narrow the window of
% data to a portion of the input trace by using the cop function. Example
%     c1 = crop(c,-1,3)
%     corrderived_plot_swarm_history(c1,10)
%
% See also correlation/linkage correlation/cluster

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% CHECK INPUTS
if nargin>2
    error('Incorrect number of inputs');
end
if ~isa(c,'correlation')
    error('First argument must be a correlation object');
end

if isempty(get(c,'CLUST'))
    error('CLUSTER field must be filled in input argument. See HELP CLUSTER');
end

if numel(varargin)==1
    clusterSize = varargin{1};
else
    clusterSize = 5;
end


% FIND EVENTS IN/OUT OF CLUSTERS
inMult = find(c,'BIG',clusterSize);
% find non-multiplets
for n = 1:get(c,'TRACES')
    if numel(find(inMult==n))==0
        notInMult(n) = 1;
    else
        notInMult(n) = 0;
    end
end
notInMult = find(notInMult)';
inMult = sort(inMult);


% GET STA_CHAN
if ~check(c,'STA') | ~check(c,'CHAN')
   warning('This function was written assuming data from a single sta_chan'); 
end
wtmp = waveform(c);
wtmp = wtmp(1);
nscl = [ get(wtmp,'NETWORK') '_' get(wtmp,'STATION') '_' get(wtmp,'CHANNEL') '_' get(wtmp,'LOCATION') ];




% PLOT IT
figure('Color','w','Position',[0 0 1100 850]);
box on; hold on;
set(gcf,'DefaultLineLineWidth',0.1);
set(gcf,'DefaultAxesFontSize',12);

% PLOT EVENT RATES
subplot(3,1,1)
disp('Preparing event rate histograms ...');
c1 = subset(c,inMult);
c1 = sort(c1);
trigMult = get(c1,'TRIG');
trigAll = get(c,'TRIG');
edges = [floor(min(trigAll)):1/24:ceil(max(trigAll))];
nMult = histc(trigMult,edges);
nAll = histc(trigAll,edges);
%
bar(edges,nAll,'y');
%h = findobj(gca,'Type','patch');
%set(h,'FaceColor',[.7 .7 .7])
hold on;
bar(edges,nMult,'r');
h = findobj(gca,'Type','patch');
set(h,'EdgeColor',[0 0 0],'LineWidth',0.1)
xlim([[min(trigAll)-1/24 max(trigAll)+1/24]]);
datetick('x','KeepLimits');
legend('All events','Clustered events');

title('Event rates');
ylabel('Events per hour');



% AMPLITUDE PLOT
disp('Preparing amplitude measures ...');
subplot(3,1,2)
c1 = crop(c,-1,4);
w = waveform(c1);
w = hilbert(w);
amp = max(double(w));
trig = get(c1,'TRIG');
plot(trig(notInMult),amp(notInMult),'ko','MarkerFaceColor','y','MarkerSize',4);
hold on;
plot(trig(inMult),amp(inMult),'ko','MarkerFaceColor','r','MarkerSize',4);
set(gca,'YScale','log');
xlim([[min(trigAll)-1/24 max(trigAll)+1/24]]);
ylim([min(amp) max(amp)]);
datetick('x','KeepLimits');
%set(gca,'YGrid','on')
ylabel('amplitude (nm/s)')
legend('All events','Clustered events');
title(['Event amplitudes    (derived from  ' nscl ')'],'Interpreter','none');



% PLOT EVENT RATES
subplot(3,1,3)
disp('Preparing cluster lifespan plot ...');
family = getclusterstat(c);
index = find(family.numel>=clusterSize);
[tmp,index] = sort(family.begin(index));

box on; hold on;
for n = 1:numel(index)
    plot([ family.begin(index(n)) family.finish(index(n)) ],[n n],'-','Color',[0.7 0.7 0.7],'LineWidth',1);
    plot(family.trig{index(n)},repmat(n,family.numel(index(n)),1),'o','Color',[0 0 0],'MarkerFaceColor','r','MarkerSize',4);

end
xlim([[min(trigAll)-1/24 max(trigAll)+1/24]]);
ylim([0 numel(index)+1]);
datetick('x','KeepLimits');
set(gca,'YTick',[1:numel(index)]);
set(gca,'YTickLabel',index);
ylabel('cluster rank')
title(['Cluster lifespan  (clusters of ' num2str(clusterSize) ' or more events)']);


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );
print(gcf,'-dpsc2','FIG_SWARM_HISTORY.ps');
