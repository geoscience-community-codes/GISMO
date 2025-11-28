function corrderived_plot_swarm_history(c, clusterSize, outfile)
%CORRDERIVED_PLOT_SWARM_HISTORY Plot swarm evolution diagnostics from a correlation object
%
%   corrderived_plot_swarm_history(C)
%   corrderived_plot_swarm_history(C, CLUSTERSIZE)
%   corrderived_plot_swarm_history(C, CLUSTERSIZE, OUTFILE)
%
%   C            = correlation object with CLUST and WAVEFORM populated
%   CLUSTERSIZE  = minimum number of events to be considered a cluster (default = 5)
%   OUTFILE      = optional output filename (e.g. 'swarm_history.png')
%
%   This function produces:
%       1) Event-rate comparison (all vs clustered)
%       2) Event amplitude evolution
%       3) Cluster lifespan plot
%
%   Requires that LINKAGE and CLUSTER have already been run on C.
%
% Author: Michael West (original)
% Refactor: Glenn Thompson + ChatGPT (2025)
% 
% See also: correlation/linkage, correlation/cluster, getclusterstat

% ---------------------------
% Input checking
% ---------------------------
if nargin < 1 || ~isa(c,'correlation')
    error('First argument must be a correlation object.');
end

if isempty(get(c,'CLUST'))
    error('CLUST field must be populated. Run CLUSTER first.');
end

if nargin < 2 || isempty(clusterSize)
    clusterSize = 5;
end

if nargin < 3
    outfile = '';
end

% ---------------------------
% Identify clustered / non-clustered events
% ---------------------------
inMult = find(c,'BIG',clusterSize);
nTraces = get(c,'TRACES');

notInMult = true(nTraces,1);
notInMult(inMult) = false;
notInMult = find(notInMult);
inMult    = sort(inMult);

% ---------------------------
% Station metadata (best-effort)
% ---------------------------
if ~check(c,'STA') || ~check(c,'CHAN')
    warning('Station/channel metadata incomplete.');
end

wtmp = waveform(c);
wtmp = wtmp(1);
nscl = sprintf('%s_%s_%s_%s', ...
    get(wtmp,'NETWORK'), ...
    get(wtmp,'STATION'), ...
    get(wtmp,'CHANNEL'), ...
    get(wtmp,'LOCATION'));

% ---------------------------
% Extract trigger times
% ---------------------------
trigAll = get(c,'TRIG');

if isempty(trigAll)
    error('No trigger times found in correlation object.');
end

% ---------------------------
% Create figure
% ---------------------------
figure('Color','w','Position',[100 100 1100 850]);
set(gcf,'DefaultLineLineWidth',0.8);
set(gcf,'DefaultAxesFontSize',12);

% ===========================
% 1) EVENT RATE HISTOGRAM
% ===========================
subplot(3,1,1)
disp('Preparing event-rate histograms ...')

c1 = subset(c,inMult);
c1 = sort(c1);

trigMult = get(c1,'TRIG');

edges = floor(min(trigAll)) : 1/24 : ceil(max(trigAll));
nMult = histcounts(trigMult, edges);
nAll  = histcounts(trigAll,  edges);

bar(edges(1:end-1), nAll, 1, 'FaceColor',[1 1 0.6]); hold on;
bar(edges(1:end-1), nMult,1, 'FaceColor',[1 0.4 0.4]);

datetick('x','keeplimits')
xlim([min(trigAll)-1/24 max(trigAll)+1/24])
ylabel('Events per hour')
title('Event Rates')
legend('All events','Clustered events')

% ===========================
% 2) AMPLITUDE EVOLUTION
% ===========================
subplot(3,1,2)
disp('Preparing amplitude measures ...')

c2 = crop(c,-1,4);
w  = waveform(c2);
w  = hilbert(w);

amp  = max(abs(double(w)));
trig = get(c2,'TRIG');

u = get(w(1),'units');
if isempty(u)
    u = 'unknown units';
end

plot(trig(notInMult),amp(notInMult),'ko','MarkerFaceColor','y','MarkerSize',4); hold on;
plot(trig(inMult),   amp(inMult),   'ko','MarkerFaceColor','r','MarkerSize',4);

set(gca,'YScale','log')
xlim([min(trigAll)-1/24 max(trigAll)+1/24])
ylim([min(amp) max(amp)])
datetick('x','keeplimits')

ylabel(['Amplitude (' u ')'])
title(['Event Amplitudes – ' nscl],'Interpreter','none')
legend('All events','Clustered events')

% ===========================
% 3) CLUSTER LIFESPAN
% ===========================
subplot(3,1,3)
disp('Preparing cluster lifespan plot ...')

family = getclusterstat(c);
idx    = find(family.numel >= clusterSize);

if isempty(idx)
    warning('No clusters meet minimum clusterSize=%d',clusterSize);
    title('No clusters above size threshold')
    return
end

[~,ix] = sort(family.begin(idx));
idx = idx(ix);

for n = 1:numel(idx)
    plot([family.begin(idx(n)) family.finish(idx(n))],[n n],'-', ...
        'Color',[0.7 0.7 0.7],'LineWidth',1); hold on

    plot(family.trig{idx(n)}, ...
         repmat(n,family.numel(idx(n)),1), ...
         'o','Color','k','MarkerFaceColor','r','MarkerSize',4)
end

xlim([min(trigAll)-1/24 max(trigAll)+1/24])
ylim([0 numel(idx)+1])
datetick('x','keeplimits')

set(gca,'YTick',1:numel(idx))
set(gca,'YTickLabel',idx)

ylabel('Cluster rank')
title(sprintf('Cluster Lifespans (≥ %d events)',clusterSize))

% ===========================
% Optional output file
% ===========================
if ~isempty(outfile)
    [~,~,ext] = fileparts(outfile);
    switch lower(ext)
        case '.png'
            print(gcf,'-dpng','-r150',outfile)
        case '.pdf'
            print(gcf,'-dpdf','-r150',outfile)
        case '.ps'
            print(gcf,'-dpsc2',outfile)
        otherwise
            warning('Unknown output format: %s', ext);
    end
end

end