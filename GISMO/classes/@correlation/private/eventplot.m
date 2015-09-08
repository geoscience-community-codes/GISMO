function eventplot(c,scale,howmany);

% Private method. See ../plot for details.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


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
    warning('Time corrections from LAG field have not been applied to traces. ADJUSTTRIG may be necessary');
end;

% TEST FOR NUMBER OF CLUSTERS
if (howmany > max(c.clust))
    error(['There are only ' num2str(max(c.clust)) ' clusters in this set of traces']);
end

% FIND CLUSTERS AND STACK TRACES
c1 = correlation;   % get new correlation object without correlation info
c1.W = c.W;
c1.trig = c.trig;
for i = 1:howmany
    index{i} = find(c,'CLU',i);
    ntraces(i) = length(index{i});
    c1 = stack(c1,index{i});
end


% MAKE PLOT OF STACKS
c1 = subset(c1,[ length(c1.trig)-howmany+1 : length(c1.trig) ]);
plot(c1,'wig',scale);
set(gcf,'Position',[50 500 850 300]);
Xlim = get(gca,'Xlim');
for i = 1:length(index)
    text(Xlim(1),i-0.3,['  #' num2str(i) ' (' num2str(ntraces(i)) ' traces)'],'HorizontalAlignment','Left');
end


% PLOT EVENTS VS. DATE
figure('Color','w','Position',[50 92 850 250]);
xleft = min(c.trig) - 0.05*(max(c.trig)-min(c.trig));
xright = max(c.trig) + 0.05*(max(c.trig)-min(c.trig));
box on; hold on;
for i = 1:length(ntraces)
    t = index{i};
    plot([xleft xright],[i i],'k:');
    plot(c.trig(index{i}),i*ones(size(index{i})),'ko','MarkerFaceColor',[.5 .5 1]);
    text(xleft,i-0.3,['  #' num2str(i)],'HorizontalAlignment','Left');
end
set(gca,'YTick',[]);
set(gca,'YDir','reverse');
xlabel('Date');
ylabel('Cluster');
datetick('x');
axis([xleft xright 0 length(ntraces)+1]);





%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );
% print(gcf, '-depsc2', 'FIG.ps')

