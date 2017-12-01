%% This is where all output will go
OUTDIR='/Users/gt/Dropbox/scratch_matlab/RocketSeismology/SpaceXplosion/video';
mkdir(fullfile(OUTDIR,'matfiles'));
mkdir(fullfile(OUTDIR,'images'));
SECONDS_PER_DAY = 86400;
FPS = 30; % frames per second

%% locate the video clips from SpaceX and provide their start times (all different)
video_dir = '/Users/gt/Dropbox/Professional/Fieldwork/PROJECTS/KSC_projects/20160901_SpaceXplosion';
d = dir(fullfile(video_dir,'*.mov'));
FPS=30; % frames per second
starttime(1) = datenum(2016,9,1,13,07,07)+(1-1)/FPS/SECONDS_PER_DAY;
starttime(2) = datenum(2016,9,1,13,07,06)+(6-1)/FPS/SECONDS_PER_DAY;
starttime(3) = datenum(2016,9,1,13,07,12)+(1-1)/FPS/SECONDS_PER_DAY;
starttime(4) = datenum(2016,9,1,13,07,06)+(7-1)/FPS/SECONDS_PER_DAY;

%% loop over each file, importing each frame and saving it as a mat-file
endtime = 0;

for c=1:numel(d)
    fprintf('\n%s ',d(c).name);
    v=VideoReader( fullfile(video_dir, d(c).name) );
    s = struct('cdata',zeros(v.Height,v.Width,3,'uint8'),...
        'colormap',[]);
    k = 1;
    while hasFrame(v)
        s(k).cdata = readFrame(v);
        if hasFrame(v)
            crap = readFrame(v); % since 2 consecutive frames are always the same
        end
        thisframe = s(k).cdata;
        thistime = starttime(c) + (k-1)/FPS/SECONDS_PER_DAY;
        if thistime > endtime
            endtime = thistime;
        end
        save( fullfile(OUTDIR,'matfiles',sprintf('%s.%s.mat',d(c).name,datestr(thistime,'HHMMSS.FFF'))), 'thisframe');
        if mod(k,FPS)==0
            fprintf('%d ',k/FPS);
        end
        k = k+1;
    end
end
%%
clear s c k crap thisframe thistime 

%% Define the figure panel setup
close all
vw = v.Width/2;
vh = v.Height/2;
imacaspectratio=16/9;
figureHeight=1152; % previously figure was 1360 x 1160
figureWidth=figureHeight*imacaspectratio; % important for iMovie
fh=figure('Units','pixels','Position',[10 10 figureWidth figureHeight]);
spacer = 40;
ax(1)=axes('Units','pixels','Position',[spacer        (spacer+vh)*2-spacer/2 vw             vh]);
ax(2)=axes('Units','pixels','Position',[spacer*1.5+vw (spacer+vh)*2-spacer/2 vw             vh]);
ax(3)=axes('Units','pixels','Position',[spacer        (spacer+vh)*1          vw             vh]);
ax(4)=axes('Units','pixels','Position',[spacer*1.5+vw (spacer+vh)*1          vw             vh]);
for c=1:4
    set(ax(c),'XTick',[],'YTick',[]);
end
ax(5)=axes('Units','pixels','Position',[spacer        (spacer+vh)*0.55        vw*2+spacer/2 vh*0.45]);
ax(6)=axes('Units','pixels','Position',[spacer        spacer                  vw*2+spacer/2 vh*0.45]);
% time label
%ax(7) = axes('Units','pixels','Position',[vw-spacer spacer+vh*2 spacer*4 spacer],'Visible','off');
ax(7) = axes('Units','pixels','Position',[spacer*2 vh spacer*4 spacer],'Visible','off');

%% Load the seismic and infrasound data corresponding to the time window of the video files
dbpath = '/Volumes/data/rockets/rocketmaster';
ds = datasource('antelope', dbpath); 
snum=datenum(2016,9,1,13,07,06.167);
enum=datenum(2016,9,1,13,07,31.433);
chantag=ChannelTag('FL.BCHH.*.*')
w=waveform(ds,chantag,snum,enum)
w=clean(w);

%% plot the seismic and infrasound data in panels 6 and 5 respectively
ph1=plot(ax(5),get(w(1),'timevector'),get(w(1),'data'));
xlim(ax(5),[snum enum]);
datetick(ax(5),'x','keeplimits')
ylabel(ax(5),'Pa')
pylims=get(ax(5),'YLim');
ph2=plot(ax(6),get(w(6),'timevector'),1e-6*get(w(6),'data'));
xlim(ax(6),[snum enum]);
datetick(ax(6),'x','keeplimits')
ylabel(ax(6),'mm/s');
sylims=get(ax(6),'YLim');



%% Now loop over time from first frame to final frame
realstart = min(starttime);
kmax = floor((endtime - realstart) * SECONDS_PER_DAY * FPS)
for k=1:kmax
    realtime = realstart + (k-1)/FPS/SECONDS_PER_DAY;    
    
    % draw line to mark where on seismic and infrasound traces the video
    % frames being shown right now are
    lh1=line(ax(5),[realtime realtime], pylims,'LineWidth',2,'Color','k');
    lh2=line(ax(6),[realtime realtime], sylims,'LineWidth',2,'Color','k');
    infratime = realtime + 4/SECONDS_PER_DAY;
    if infratime < endtime
        lh3=line(ax(5),[infratime infratime], pylims,'LineWidth',2,'Color','r');
        lh4=line(ax(6),[infratime infratime], sylims,'LineWidth',2,'Color','r');
    end
    uistack(ph1);
    uistack(ph2);
    
    % add time
    th1=text(ax(7),0,0,datestr(realtime,'HH:MM:SS.FFF'),'FontSize',32);
    
    % find matfiles (i.e. frames) for this time sample
    dstr = datestr(realtime,'HHMMSS.FFF');
    filepattern = fullfile(OUTDIR,'matfiles',sprintf('*%s.mat',dstr));
    df=dir(filepattern);
    if numel(df)>0
        for c=1:numel(df)
            load(fullfile(df(c).folder,df(c).name));
            fparts = split(df(c).name,'.mov');
            
            % decide which panel they belong to based on which video they
            % came from
            switch fparts{1}
                case 'f9-29_ne_twr', posn=2;
                case 'f9-29_nw_ptz', posn=1;
                case 'f9-29_ucs3', posn=3;
                case 'f9-29_west_fixed', posn=4;
                otherwise
                    posn=0;
            end
            
            % plot the frame in the appropriate panel corresponding to posn
            % variable
            if posn>0
                disp(sprintf('%s %s.%02d %d',dstr,datestr(realtime,'HHMMSS'), round(mod(realtime*SECONDS_PER_DAY,1)*30)+1,  df(c).name, posn));
                image(ax(posn),thisframe)
                title(ax(posn),fparts{1},'Interpreter','None');
                set(ax(posn),'XTick',[],'YTick',[]);
            end
        end

        % now all panels are plotted, save the figure window as a new jpeg
        % file
        jpgfile = fullfile(OUTDIR,'images',sprintf('%s.jpg',dstr));
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
d=dir(fullfile(OUTDIR,'images','*.jpg'));
v=VideoWriter(fullfile(OUTDIR,'uncompressed.avi'),'Uncompressed AVI')
open(v)
for c=1:numel(d)
    disp(sprintf('Processing frame %d of %d',c,numel(d)))
    a=imread(fullfile(d(c).folder,d(c).name));
    writeVideo(v,a);
end
close(v);

%% create wav audio files for infrasound and seismic traces
fmmod_waveform(w(1),16,fullfile(OUTDIR,'infra.wav'));
fmmod_waveform(w(6),20,fullfile(OUTDIR,'seismic.wav'));


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



