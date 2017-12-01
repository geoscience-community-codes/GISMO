%% This is where all output will go
OUTDIR='/Users/gt/Dropbox/scratch_matlab/RocketSeismology/SpaceXplosion/video';
mkdir(fullfile(OUTDIR,'ymatfiles'));
mkdir(fullfile(OUTDIR,'yimages'));
SECONDS_PER_DAY = 86400;
FPS = 30; % frames per second

%% locate the video clips from SpaceX and provide their start times (all different)
fname = fullfile(OUTDIR,'SpaceX - Static Fire Anomaly - AMOS-6 - 09-01-2016.mov');
FPS=30; % frames per second
starttime = datenum(2016,9,1,13,06,00)+(1-1)/FPS/SECONDS_PER_DAY;

%% loop over each file, importing each frame and saving it as a mat-file
endtime = 0;

v=VideoReader( fname );
s = struct('cdata',zeros(v.Height,v.Width,3,'uint8'),...
    'colormap',[]);
k = 1;
while hasFrame(v)
    s(k).cdata = readFrame(v);
    thisframe = s(k).cdata;
    thistime = starttime + (k-1)/FPS/SECONDS_PER_DAY;
    if thistime > endtime
        endtime = thistime;
    end
    save( fullfile(OUTDIR,'ymatfiles',sprintf('%s.mat',datestr(thistime,'HHMMSS.FFF'))), 'thisframe');
    if mod(k,FPS)==0
        fprintf('%d ',k/FPS);
    end
    k = k+1;
end

%%
clear s c k crap thisframe thistime 

%% Define the figure panel setup
close all
vw = v.Width;
vh = v.Height;
spacer = 40;
imacaspectratio=16/9;
traceHeight = 200;
figureHeight = vh + 2 * traceHeight + 4 * spacer;
figureWidth = figureHeight * imacaspectratio;
fh=figure('Units','pixels','Position',[10 10 figureWidth figureHeight]);

ax(1)=axes('Units','pixels','Position',[spacer        spacer*3+traceHeight*2 vw             vh]);
set(ax(1),'XTick',[],'YTick',[]);
ax(2)=axes('Units','pixels','Position',[spacer        spacer*2+traceHeight          vw traceHeight]);
ax(3)=axes('Units','pixels','Position',[spacer        spacer                  vw traceHeight]);
% time label
ax(4) = axes('Units','pixels','Position',[vw/2-spacer spacer*2+traceHeight*2 spacer*4 spacer],'Visible','off');

%% Load the seismic and infrasound data corresponding to the time window of the video files
dbpath = '/Volumes/data/rockets/rocketmaster';
ds = datasource('antelope', dbpath); 
chantag=ChannelTag('FL.BCHH.*.*')
w=waveform(ds,chantag,starttime,endtime)
w=clean(w);

%% plot the seismic and infrasound data in panels 3 & 2 respectively
ph1=plot(ax(2),get(w(1),'timevector'),get(w(1),'data'));
xlim(ax(2),[starttime endtime]);
datetick(ax(2),'x','keeplimits')
ylabel(ax(2),'Pa')
pylims=get(ax(2),'YLim');
ph2=plot(ax(3),get(w(6),'timevector'),1e-6*get(w(6),'data'));
xlim(ax(3),[starttime endtime]);
datetick(ax(3),'x','keeplimits')
ylabel(ax(3),'mm/s');
sylims=get(ax(3),'YLim');



%% Now loop over time from first frame to final frame
realstart = min(starttime);
kmax = floor((endtime - realstart) * SECONDS_PER_DAY * FPS)
for k=1:kmax
    realtime = realstart + (k-1)/FPS/SECONDS_PER_DAY;    
    
    % draw line to mark where on seismic and infrasound traces the video
    % frames being shown right now are
    lh1=line(ax(2),[realtime realtime], pylims,'LineWidth',2,'Color','k');
    lh2=line(ax(3),[realtime realtime], sylims,'LineWidth',2,'Color','k');
    infratime = realtime + 4/SECONDS_PER_DAY;
    if infratime < endtime
        lh3=line(ax(2),[infratime infratime], pylims,'LineWidth',2,'Color','r');
        lh4=line(ax(3),[infratime infratime], sylims,'LineWidth',2,'Color','r');
    end
    uistack(ph1);
    uistack(ph2);
    
    % add time
    th1=text(ax(4),0,0,datestr(realtime,'HH:MM:SS.FFF'),'FontSize',32);
    
    % find matfiles (i.e. frames) for this time sample
    dstr = datestr(realtime,'HHMMSS.FFF');
    filepattern = fullfile(OUTDIR,'ymatfiles',sprintf('*%s.mat',dstr));
    df=dir(filepattern);
    if numel(df)>0
        load(fullfile(df(1).folder,df(1).name));

            
        % plot the frame in the appropriate panel corresponding to posn
        % variable
        if posn>0
            disp(sprintf('%s %s.%02d %d',dstr,datestr(realtime,'HHMMSS'), round(mod(realtime*SECONDS_PER_DAY,1)*30)+1,  df(1).name, posn));
            image(ax(1),thisframe)
            set(ax(1),'XTick',[],'YTick',[]);
        end


        % now all panels are plotted, save the figure window as a new jpeg
        % file
        jpgfile = fullfile(OUTDIR,'yimages',sprintf('%s.jpg',dstr));
        disp(jpgfile)
        print('-djpeg',jpgfile);
    end
    
    % delete the lines we drew to mark the time on the seismic and
    % infrasound panels
    delete(lh1)
    delete(lh2)
    if infratime < endtime
        delete(lh3)
        delete(lh4)
    end
    delete(th1)
end

%% Write video file from the JPG images - no longer need to use ImageJ which never seems to export all the images
d=dir(fullfile(OUTDIR,'yimages','*.jpg'));
v=VideoWriter(fullfile(OUTDIR,'yuncompressed.avi'),'Uncompressed AVI')
open(v)
for c=1:numel(d)
    disp(sprintf('Processing frame %d of %d',c,numel(d)))
    a=imread(fullfile(d(c).folder,d(c).name));
    writeVideo(v,a);
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



