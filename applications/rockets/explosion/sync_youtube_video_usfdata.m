%
Improvements:
1. on zoomed plots, add 5-s to time on xticks
2. move to red lines to where they would be based on speed of sound travel time, so marks line up on each infrasound component



%% This is where all output will go
OUTDIR='~/Movies/RocketSeismology/SpaceXplosion';
mkdir(fullfile(OUTDIR,'ymatfiles'));
mkdir(fullfile(OUTDIR,'yimages'));
SECONDS_PER_DAY = 86400;

%% locate the video clips from SpaceX and provide their start times (all different)
fname = fullfile(OUTDIR,'SpaceXStaticFireAnomalyAMOS_6_Youtube.mov');
FPS=30; % frames per second
starttime = datenum(2016,9,1,13,06,00)+(1-1)/FPS/SECONDS_PER_DAY;

%% loop over each file, importing each frame and saving it as a mat-file
start_recording_time = datenum(2016,9,1,13,07,05);
end_recording_time = datenum(2016,9,1,13,07,45);
endtime = 0;

v=VideoReader( fname );
d=dir(fullfile(OUTDIR,'ymatfiles'));
if numel(d)==0
    s = struct('cdata',zeros(v.Height,v.Width,3,'uint8'),...
        'colormap',[]);
    k = 1;
    while hasFrame(v) & endtime < end_recording_time
        s(k).cdata = readFrame(v);
        thisframe = s(k).cdata;
        thistime = starttime + (k-1)/FPS/SECONDS_PER_DAY;
        if thistime > endtime
            endtime = thistime;
        end
        if thistime >= start_recording_time
            %save( fullfile(OUTDIR,'ymatfiles',sprintf('%s.mat',datestr(thistime,'HHMMSS.FFF'))), 'thisframe');
        end
        if mod(k,FPS)==0
            fprintf('%d ',k/FPS);
        end
        k = k+1;
    end

    %%
    clear s c k crap thisframe thistime 
end

%% Define the figure panel setup
close all
rf = 0.5; % reduction factor
vw = v.Width * rf;
vh = v.Height *rf;
spacer = 40 ;%* rf;
imacaspectratio=16/9;
traceHeight = 200 *rf;
figureHeight = vh + 2 * traceHeight + 4 * spacer;
figureWidth = figureHeight * imacaspectratio;
zoomspacer = traceHeight * 0.6;
zoombottom = spacer*3+traceHeight*2;
zoomtraceHeight = traceHeight * 0.45;
fh=figure('Units','pixels','Position',[10 10 figureWidth figureHeight]); % figure

ax(1)=axes('Units','pixels','Position',[spacer*1.0        spacer*3+traceHeight*2  vw vh]); % video
set(ax(1),'XTick',[],'YTick',[]);
ax(2)=axes('Units','pixels','Position',[spacer*2.0        spacer*2+traceHeight    vw-spacer traceHeight]); % overall infrasound trace
ax(3)=axes('Units','pixels','Position',[spacer*2.0        spacer                  vw-spacer traceHeight]); % overall seismic trace
% time label
ax(4) = axes('Units','pixels','Position',[vw*.85-spacer spacer*2.5+traceHeight*2 spacer*4 spacer],'Visible','off'); % time stamp
ax(5) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*5+spacer/2  figureWidth-spacer*4-vw zoomtraceHeight]); % infra 1
ax(6) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*4+spacer/2  figureWidth-spacer*4-vw zoomtraceHeight]); % infra 2
ax(7) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*3+spacer/2 figureWidth-spacer*4-vw zoomtraceHeight]); % infra 3
ax(8) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*2 figureWidth-spacer*4-vw zoomtraceHeight]); % seismic Z
ax(9) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*1 figureWidth-spacer*4-vw zoomtraceHeight]); % seismic R
ax(10) = axes('Units','pixels','Position',[3*spacer+vw zoombottom+zoomspacer*0 figureWidth-spacer*4-vw zoomtraceHeight]); % seismic T
ax(11) = axes('Units','pixels','Position',[3*spacer+vw spacer*1.5 figureWidth-spacer*4-vw traceHeight*2]); % rectilinearity
%ax(12) = axes('Units','pixels','Position',[spacer+vw+spacer spacer figureWidth-spacer*3-vw traceHeight]); % ??

%% Load the seismic and infrasound data corresponding to the time window of the video files
windowlength = 5; % time (s) for showing in the zoomed plots
dbpath = '/Volumes/data/rockets/rocketmaster2';
ds = datasource('antelope', dbpath); 
chantag=ChannelTag('FL.BCHH.*.*')
w=waveform(ds,chantag,start_recording_time,end_recording_time+windowlength/SECONDS_PER_DAY);
if isempty(w)
    error('no waveform data')
end
w=clean(w);

%% Rotate seismogram
figure
t = threecomp(w([6 5 4])',199.5);
tr = t.rotate()
tr2 = tr.particlemotion();
%tr2.plotpm()
wzrt=get(tr,'waveform');


%% plot the seismic and infrasound data in panels 3 & 2 respectively
ph1=plot(ax(2),get(w(1),'timevector'),get(w(1),'data'),'LineWidth',2); % infrasound trace
xlim(ax(2),[start_recording_time end_recording_time]);
xticks = start_recording_time:5/86400:end_recording_time;%-5/86400;
yticks = [-200:200:800];
ylim(ax(2),[-200 800]);
set(ax(2),'XTick',xticks,'YTick',yticks);
datetick(ax(2),'x','keepticks')
ylabel(ax(2),'Pa')
text(ax(2),0.1,0.9,'infraBSU 1','FontSize',20,'Units','normalized');
pylims=get(ax(2),'YLim');
ph2=plot(ax(3),get(wzrt(1),'timevector'),1e-6*get(w(6),'data'),'LineWidth',2); % vertical seismic trace
xlim(ax(3),[start_recording_time end_recording_time]);
yticks = [-3:1:3];
ylim(ax(3),[-3 3]);
set(ax(3),'XTick',xticks,'YTick',yticks);
datetick(ax(3),'x','keepticks')
ylabel(ax(3),'mm/s');
text(ax(3),0.1,0.9,'seismic vertical','FontSize',20,'Units','normalized');
sylims=get(ax(3),'YLim');



%% Now loop over time from first frame to final frame
kmax = floor((end_recording_time - start_recording_time) * SECONDS_PER_DAY * FPS);
for k=1:kmax
    realtime = start_recording_time + (k-1)/FPS/SECONDS_PER_DAY;   
    disp(sprintf('Processing frame %d of %d, corresponding to %s',k,kmax,datestr(realtime)));
    
    % draw line to mark where on seismic and infrasound traces the video
    % frames being shown right now are
    lh1=line(ax(2),[realtime realtime], pylims,'LineWidth',3,'Color','k');
    lh2=line(ax(3),[realtime realtime], sylims,'LineWidth',3,'Color','k');
    infratime = realtime + 4/SECONDS_PER_DAY; % predicted airwave time if something happens at realtime
    if infratime < end_recording_time + windowlength/SECONDS_PER_DAY
        lh3=line(ax(2),[infratime infratime], pylims,'LineWidth',3,'Color','r');
        lh4=line(ax(3),[infratime infratime], sylims,'LineWidth',3,'Color','r');
    end
    seismictime = realtime + 1/SECONDS_PER_DAY; % predicted P wave time if something happens at realtime
    if seismictime < end_recording_time + windowlength/SECONDS_PER_DAY
        lh5=line(ax(3),[seismictime seismictime], sylims,'LineWidth',3,'Color','g');
    end    
    uistack(ph1);
    uistack(ph2);
    
    % add time
    th1=text(ax(4),0,0,datestr(realtime,'HH:MM:SS.FFF'),'FontSize',28);
    
    % add lines to these plots
    startsecs = (realtime - start_recording_time) * SECONDS_PER_DAY;
    for axnum=5:11
        %hold(ax(axnum), 'on')
        lh6(axnum)=line(ax(axnum), [startsecs startsecs], ylim(ax(axnum)),'LineWidth',2,'Color','k');
        lh7(axnum)=line(ax(axnum),[startsecs+4 startsecs+4], ylim(ax(axnum)),'LineWidth',2,'Color','r');
    end
    for axnum=8:11
        lh8(axnum)=line(ax(axnum),[startsecs+1 startsecs+1], ylim(ax(axnum)),'LineWidth',2,'Color','g');
    end 
    
    % add zoomed infrasound traces
    xlims = SECONDS_PER_DAY * ([realtime - start_recording_time           realtime + windowlength/SECONDS_PER_DAY - start_recording_time]);
    wiz = extract(w(1:3),'time',realtime,realtime+windowlength/SECONDS_PER_DAY);
    t = ( get(wiz(1), 'timevector')  - start_recording_time) * 86400;

    hold(ax(5),'on')
    hi1=plot(ax(5), t, get(wiz(1), 'data'),'b'); 
    set(ax(5),'XLim',xlims);
    set(hi1,'LineWidth',2)
    title(ax(5),'Zoomed infrasound plots');
    ylabel(ax(5),'Pa'); 
    set(ax(5),'XTickLabel',{})
    %legend(ax(5),hi1,'HD1'); 
    
    hold(ax(6),'on')
    hi2=plot(ax(6), t, get(wiz(2), 'data'),'b'); 
    set(hi2,'LineWidth',2)
    set(ax(6),'XLim',xlims);
    set(ax(6),'XTickLabel',{})
    ylabel(ax(6),'Pa'); 
    %legend(ax(6),hi2,'HD2'); 
    
    hold(ax(7),'on')
    hi3=plot(ax(7), t, get(wiz(3), 'data'),'b');
    set(hi3,'LineWidth',2)
    set(ax(7),'XLim',xlims);
    ylabel(ax(7),'Pa'); 
    %legend(ax(7),hi3,'HD3');
    
    % add zoomed seismic traces
    wsz = extract(wzrt,'time',realtime,realtime+windowlength/SECONDS_PER_DAY);
    
    hold(ax(8),'on')
    hs1=plot(ax(8), t, get(wsz(1), 'data')/1000,'b');
    set(hs1,'LineWidth',2)
    set(ax(8),'XLim',xlims);
    ylabel(ax(8),'\mum/s'); 
    title(ax(8),'Zoomed seismic plots')
    text(ax(8),0.1,0.9,'vertical','Units','normalized','FontSize',18)
    set(ax(8),'XTickLabel',{})
    %legend(ax(8),hs1,'HHZ');
    
    hold(ax(9),'on')
    hs2=plot(ax(9), t, get(wsz(2), 'data')/1000,'b'); 
    set(hs2,'LineWidth',2)
    set(ax(9),'XLim',xlims);
    ylabel(ax(9),'\mum/s'); 
    text(ax(9),0.1,0.9,'radial','Units','normalized','FontSize',18)
    set(ax(9),'XTickLabel',{})
    %legend(ax(9),hs2,'HHR');
    
    hold(ax(10),'on')
    hs3=plot(ax(10), t, get(wsz(3), 'data')/1000,'b');
    set(ax(10),'XLim',xlims);
    set(hs3,'LineWidth',2)
    ylabel(ax(10),'\mum/s'); 
    text(ax(10),0.1,0.9,'transverse','Units','normalized','FontSize',18)
    %legend(ax(10),hs3,'HHT');
    xlabel('Seconds');

    % rectilinearity plot
    wsz2 = extract(w([6 5 4]),'time',realtime,realtime+windowlength/SECONDS_PER_DAY);
    tc = threecomp(wsz2',199.5);
    tc1 = tc.rotate();
    tc2 = tc1.particlemotion();
    rl=get(tc2, 'rectilinearity');
    pl=get(tc2, 'planarity');
    tv = get(rl,'timevector'); 
    tv = (tv - start_recording_time)*SECONDS_PER_DAY;
    
    hold(ax(11),'on')
    hrl=plot(ax(11), tv,get(rl,'data'),'m-','LineWidth',2);
    text(ax(11),0.1,0.9,'rectilinearity','Color','m','Units','normalized','FontSize',18)
    hold(ax(11),'on');
    hpl=plot(ax(11), tv, get(pl,'data'),'c-','LineWidth',2);
    text(ax(11),0.5,0.9,'planarity','Color','c','Units','normalized','FontSize',18)
    xlabel(ax(11),'Seconds');
    set(ax(11),'XLim',xlims);
    %legend(ax(11),[hrl hpl],'Rectilinearity','Planarity');
    title(ax(11),'');
    set(ax(11),'XGrid','on','YLim',[0 1])
    hold(ax(11),'off')
    
% 
%     uistack(hi1);
%     uistack(hi2);
%     uistack(hi3);
%     uistack(hs1);
%     uistack(hs2);
%     uistack(hs3);
%     uistack(hrl);
%     uistack(hpl);

    
    % make sure there are no extra figures - there should just be 1 - these
    % can otherwise mean printing the wrong figure to jpg/png
    hfigs =  findobj('type','figure');
    nfigs = length(hfigs);
    if nfigs>1
        for fignum=2:nfigs
            close(fignum)
        end
    end
    
    % find matfiles (i.e. frames) for this time sample
    dstr = datestr(realtime,'HHMMSS.FFF');
    filepattern = fullfile(OUTDIR,'ymatfiles',sprintf('*%s.mat',dstr));
    df=dir(filepattern);
    if numel(df)>0
        load(fullfile(df(1).folder,df(1).name));

            
        % plot the frame in the appropriate panel corresponding to posn
        % variable
        disp(sprintf('%s %s.%02d',dstr,datestr(realtime,'HHMMSS'), round(mod(realtime*SECONDS_PER_DAY,1)*30)+1,  df(1).name));
        image(ax(1),thisframe)
        set(ax(1),'XTick',[],'YTick',[]);
        
        % set font sizes
        set(0,'DefaultAxesFontSize',16);

        % now all panels are plotted, save the figure window as a new jpeg
        % file
        
        jpgfile = fullfile(OUTDIR,'yimagesjpg',sprintf('%s.jpg',dstr));
        disp(jpgfile)
        print('-djpeg','-f1',jpgfile);
        pngfile = fullfile(OUTDIR,'yimagespng',sprintf('%s.png',dstr));
        disp(pngfile)
        print('-dpng','-f1',pngfile);       
    end
    
    % delete the lines we drew to mark the time on the seismic and
    % infrasound panels
    delete(lh1)
    delete(lh2)
    if infratime < end_recording_time + windowlength/SECONDS_PER_DAY
        delete(lh3)
        delete(lh4)
    end
    if seismictime < end_recording_time + windowlength/SECONDS_PER_DAY
        delete(lh5)
    end
    set(th1,'String','  :  :  .   ', 'FontSize',32);
    delete(th1)
    delete(lh6)
    delete(lh7)
    delete(lh8)
    delete(hrl)
    delete(hpl)
    
    % set hold off
    for axnum=5:11
        hold(ax(axnum),'off');
    end
end

%% Write video file from the JPG images - no longer need to use ImageJ which never seems to export all the images
d=dir(fullfile(OUTDIR,'yimagespng','*.png'));
v=VideoWriter(fullfile(OUTDIR,'yuncompressed2.avi'),'Uncompressed AVI')
open(v)
skippedframes = 0;
savedframes = 0;
for c=1:numel(d)
    disp(sprintf('Processing frame %d of %d',c,numel(d)))
    a=imread(fullfile(d(c).folder,d(c).name));
    if size(a)==[1500 2667 3]
        writeVideo(v,a);
        savedframes = savedframes + 1;
    else
        skippedframes = skippedframes + 1;
        disp(sprintf('- wrong size. frame is %dx%dx%d',size(a)));
    end
    disp(sprintf('- Skipped %d, Saved %d', skippedframes, savedframes));
end
close(v);

%% create wav audio files for infrasound and seismic traces
fmmod_waveform(w(1),16,fullfile(OUTDIR,'yinfra.wav'));
fmmod_waveform(w(6),20,fullfile(OUTDIR,'yseismic.wav'));


%%
% QUICK TIME then be used to compress the 15 GB AV file to a < 1 GB .mov
% file
% iMovie can then be used to combine the .mov and .wav files, and write
% them back out to a new .mov file.

%% --------------------- FUNCTIONS FOLLOW ----------------------------- %%
function w2=fmmod_waveform(w,n,outfile)
    w=interp_waveform(w,n);
    for c=1:numel(w)
        thisw=w(c);
        fs=get(thisw,'freq')
        fc=fs*0.4;
        thisw=taper(normalize(detrend(thisw)),0.1);
        x=get(thisw,'data');
        y=fmmod(x,fc,fs,fc/4);
        w2(c)=thisw;
        w2(c)=set(w2(c),'data',y);
        %sound(y,fs)
        audiowrite(outfile,y,fs);
    end
end

function w2=interp_waveform(w,n)
    SECONDS_PER_DAY = 86400;
    for c=1:numel(w)
        x=get(w(c),'data');
        fs=get(w(c),'freq');
        t=get(w(c),'timevector');
        t2=t(1)+(1/SECONDS_PER_DAY)*(0:1/fs/n:(length(t)-1)*1/fs);
        x2=interp1(t,x,t2);
        w2(c) = w(c);
        w2(c)=set(w2(c),'data',x2);
        w2(c)=set(w2(c),'freq',fs*n);
    end
end



