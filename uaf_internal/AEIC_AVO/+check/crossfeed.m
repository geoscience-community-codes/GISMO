function crossfeed(varargin)

%CROSSFEED Checks for crossfeeding and duplicate data channels
% CROSSFEED Reads a short snippet of data from an entire network and cross
% correlates each trace against all others (without time shifting). Events
% are then clustered and a directory of png images is written out showing
% raw and filtered versions of the waveforms in each cluster. These images
% can be used to check for data problems across the network. The image
% directory is named FIG_yyyymmdd_HHMMSS according to the start time. 
%
% CROSSFEED(STARTTIME) specify a start time in Matlab date format
%
% CROSSFEED(STARTTIME,DURATION) specify a trace duration in seconds.
%
% CROSSFEED(STARTTIME,DURATION,THRESHOLD) specify a cross correlation
% threshold for clustering.
%
% CROSSFEED(STARTTIME,DURATION,THRESHOLD,NETWORK) specify a network to
% examine.
%
% Using CROSSFEED with no arguments is equivalent to:
%    CROSSFEED( floor(now)-0.5 , 30 , 0.7 , 'AV' )
%
% Note that "now" is returned in local time. So the default data examined
% is 8 to 9 hours old, assuming AKST/AKDT.
%
% -- CAVEATS --
% This function is hardwired to run in the UAF Seis Lab assuming one day
% archive databases that contain waveforms and station-related tables (to
% get network affiliations)




% READ ARGUMENTS AND SET DEFAULT VALUES
if numel(varargin)>=1
    startTime = varargin{1};
else
     startTime = floor(now)-0.5;
end

if numel(varargin)>=2
    duration = varargin{2}/86400;
else
     duration = 30/86400;
end

if numel(varargin)>=3
    threshold = varargin{3};
else
     threshold = 0.7;
end

if numel(varargin)==4
    networkName = varargin{4};
else
     networkName = 'AV';
end
    


% GET CHANNEL LIST FROM DATABASE
dbWfdisc = ['/aerun/sum/db/archive/archive_' datestr(startTime,'yyyy') '/archive_' datestr(startTime,'yyyy') '_' datestr(startTime,'mm') '_' datestr(startTime,'dd')];
disp(['Reading STA_CHANs for network ' networkName ' from database: ']);
disp([ '   ' dbWfdisc ' ...']);

db = dbopen(dbWfdisc,'r');
db = dblookup(db,'','wfdisc','','');
db1 = dblookup(db,'','affiliation','','');
db = dbjoin(db,db1);
db = dbsubset(db,['net=="' networkName '"']);
[wfdisc.sta wfdisc.chan wfdisc.net] = dbgetv(db,'sta','chan','net');
dbclose(db);


% GET LIST OF UNIQUE STA CHANs 
staChanNetList = strcat(wfdisc.sta,'#',wfdisc.chan,'#',wfdisc.net);
staChanNetList = unique(staChanNetList);
for n = 1:numel(staChanNetList)
    tmp = regexp(staChanNetList(n), '#', 'split');
    scnl(n) = scnlobject(tmp{1}{1},tmp{1}{2},tmp{1}{3},'');
end


% READ IN WAVEFORMS
disp(['Loading ' num2str(numel(scnl)) ' waveforms for this time period ...']);
disp(['   start time: ' datestr(startTime)]);
disp(['   duration:   ' num2str(duration*86400) ' seconds']);
ds = datasource('antelope',dbWfdisc);
w = waveform(ds,scnl,startTime,startTime+duration);
w = demean(w);
w = fillgaps(w,0);
w = detrend(w);


% PREP WAVEFORMS AND CROSS CORRELATE
c = correlation(w);
c = detrend(c);
c = demean(c);
c = taper(c);
c = butter(c,[2 12]);
%c = xcorr(c);


% DO ZERO LAG XCORR
D = get(c,'DATA');
wcoeff = 1./sqrt(sum(D.*D));
%wcoeff(find(wcoeff==Inf)) = 0;
corr = zeros(size(D,2));
lag = zeros(size(D,2));
for col = 1:size(D,2)
    for row = 1:size(D,2)
        corr(col,row) = sum(D(:,col).*D(:,row)) .* wcoeff(col) .* wcoeff(row);
    end
end
f = find(corr<0);
corr(f) = 0;
f = find(isnan(corr));
corr(f) = 0;
c = set(c,'corr',corr);
c = set(c,'lag',lag);
c = linkage(c);
c = cluster(c,threshold);



% MAKE FIGURE DIRECTORY
dirName = [networkName '_' datestr(startTime,'yyyy') datestr(startTime,'mm') datestr(startTime,'dd') '_' datestr(startTime,'HH') datestr(startTime,'MM') datestr(startTime,'SS')];
if ~exist(dirName,'dir')
    disp(['Creating new directory: ' dirName]);
    mkdir(dirName);
end


% PLOT TRACE CLUSTERS
index = find(c,'BIG',2);
clust = get(c,'CLUST');
disp('--> dbpick selection strings: ');
for n = 1:max(clust(index))
    f = find(clust==n);
    figure('Color','w','Position',[50 50 800 1100]);
    set(gcf,'DefaultAxesFontSize',14)
    
    % RAW TRACE FIGURE

    wOrig = set(w(f),'UNITS','normalized scale');
    wOrigCrop = extract(wOrig,'TIME',startTime+5/86400,startTime+25/86400);
    wOrigCrop = demean(detrend(wOrigCrop));
    for i = 1:numel(wOrigCrop)
       wOrigCrop(i) = 0.25 * wOrigCrop(i) ./ std(wOrigCrop(i)) + i; 
    end
    wOrigCrop = set(wOrigCrop,'UNITS','normalized scale');

    subplot(2,1,1)
    plot(wOrigCrop);
    legend(wOrigCrop);
    xlim([0 20]);
    ylim([0 numel(wOrig)+1]);
    text(19.3,0.05 *(numel(wOrig)+1),['correlation threshold: ' num2str(threshold)],'HorizontalAlignment','Right','FontSize',12);
    text(19.3,0.10 *(numel(wOrig)+1),['trace duration: ' num2str(duration*86400) 's'],'HorizontalAlignment','Right','FontSize',12);
    text(19.3,0.15 *(numel(wOrig)+1),'Raw traces','HorizontalAlignment','Right','FontSize',12,'FontWeight','Bold');

    
    % PLOT FILTERED CROPPED TRACE
    subplot(2,1,2)
    c2 = subset(c,f);
    wFilt = waveform(c2);
    wFilt = set(wFilt,'UNITS','normalized scale');
    wFiltCrop = extract(wFilt,'TIME',startTime+10/86400,startTime+13/86400);
    for i = 1:numel(wOrig)
       wFiltCrop(i) = 0.25 * wFiltCrop(i) ./ std(wFiltCrop(i)); 
    end
    plot(wFiltCrop,'Linewidth',1);
    legend(wFiltCrop);
    xlim([0 3]);
    ylim([-0.8 0.8]);
    text(2.9,-0.75,'Filtered on 2-12 Hz','HorizontalAlignment','Right','FontSize',12,'FontWeight','Bold');

    % WRITE OUT FIGURES
    subSta = get(wFilt,'STATION');
    subChan = get(wFilt,'CHANNEL');
    scList = [];
    fileName = [dirName '/overlays_' subSta{1} '_' subChan{1} '-' subSta{2} '_' subChan{2} '.png'];
    set(gcf, 'paperorientation', 'portrait');
    set(gcf, 'paperposition', [.25 .25 8 11] );
    print('-dpng',fileName);
    %
    close all
    
    
    % WRITE DBPICK TEXT
    scList = [];
    for i = 1:numel(subSta)
        scList = [scList subSta{i} ':' subChan{i} ','];
    end
    scList = scList(1:end-1);
    disp(['sc ' scList]);
end
disp(['ts ' datestr(startTime,'yyyy/mm/dd HH:MM:SS')]);




