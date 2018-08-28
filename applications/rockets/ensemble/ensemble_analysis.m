close all
clear all
clc
mkdir('ensemble1')
cd('ensemble1')

%% 0. have we run this before and saved the data?
if exist('rocketmaster.mat', 'file')
    load rocketmaster.mat
else

    %% 1. Define datasources, channels etc
    dbpath = '/raid/data/rockets/rocketmaster2';
    ds = datasource('antelope', dbpath); 

    %% 2. Load arrival table into an Arrival object
    arrivalobj = Arrival.retrieve('antelope', dbpath );
    if isempty(arrivalobj)
       error('No arrivals loaded') 
    end
    
    %% 3. Add a short waveform for each arrival for arrival waveform metrics
    pretrigsecs = 5; posttrigsecs = 90;
	arrivalobj = arrivalobj.addwaveforms(ds, pretrigsecs, posttrigsecs);
    
    %% 4. Compute an amplitude (and other waveform metrics) for each arrival
    max_time_diff = 1.0; % max seconds between min and max
    arrivalobj = arrivalobj.addmetrics(max_time_diff);
    
    %% 5. Associate arrivals into events in a Catalog
    % 20 seconds seems to be most from BCHH to TANK infrasound
    catalogobj = arrivalobj.associate(30*60);

    %% 6. Add waveforms for each event in the Catalog
    pretriggersecs = 30; posttriggersecs = 120; 
    ctag = ChannelTag({'FL.BCHH.*.*'});
    catalogobj = catalogobj.addwaveforms(ds, ctag, pretriggersecs, posttriggersecs);
    
    %% 7. Add waveform metrics to event waveforms in Catalog
    for eventnum = 1:catalogobj.numberOfEvents
        w = [catalogobj.waveforms{eventnum}];
        maxTimeDiff = 2.0;
        catalogobj.waveforms{eventnum} = addmetrics(w, maxTimeDiff);
    end

    %% 8. save the data
    save rocketmaster.mat
    
    %% 9. write Catalog to Antelope db
    [dname, dfile] = fileparts(dbpath);
    dbpath2 = sprintf('./%s_new',dfile);
    catalogobj.write('antelope',dbpath2);
    !chmod 775 *_new* *.png
    !chgrp seismiclab *_new*
    
  
end

%% 10. Make seismograms, spectrograms and sound files
close all
publish = 0;
for eventnum = 2:catalogobj.numberOfEvents
    
    % get waveform
    w = [catalogobj.waveforms{eventnum}];
    thisA = catalogobj.arrivals{eventnum};
    dstr = datestr(min(get(w,'start')),'yyyymmdd.HHMM');
    tstr = sprintf('Event %2d: %s', eventnum, dstr);
    
    % plot seismograms
    plot_panels(w(:),'alignWaveforms',1,'arrivals',thisA);
    suptitle(sprintf('Raw waveform plot\n%s',tstr));
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_raw_waveform.png',dstr)  );
    end
    close
    
    % clean data
    w=clean(w);
    
    % plot spectrograms of infrasound channels
    figure
    [Tcelli, Fcelli, Ycelli, meanfi, peakfi] = spectrogram(w(1:3), 'spectralobject', spectralobject(1024,1000,100,[30 80]) , 'plot_metrics', 0 );  
    suptitle(sprintf('Infrasound Spectrogram\n%s',tstr));
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_infrasound_spectrogram.png',dstr)  );
    end
    close

    % plot spectrograms of seismic channels
    figure
    [Tcells, Fcells, Ycells, meanfs, peakfs] = spectrogram(w(4:end), 'spectralobject', spectralobject(1024,1000,100,[70 140]), 'plot_metrics', 0  );
    suptitle(sprintf('Seismic Spectrogram\n%s',tstr));
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_seismic_spectrogram.png',dstr)  );
    end
    close
   
    % make sound files
    infrasoundwavname = sprintf('%s_infrasound.wav',dstr );
    waveform2sound(w(3), 30,  infrasoundwavname);
    seismicwavname = sprintf('%s_seismic.wav',dstr );
    waveform2sound(w(end), 30, seismicwavname);
    
    % frequency metrics
    
    % average meanf and peakf
    % - infrasound
    mfi = mean(cell2mat(meanfi),2);
    pfi = mean(cell2mat(peakfi),2);
    thisyi = Ycelli{1};
    for count=2:numel(Ycelli)
        thisyi = thisyi + Ycelli{count};
    end
    thisyi = thisyi / numel(Ycelli);  
    % - seismic
    mfs = mean(cell2mat(meanfs),2);
    pfs = mean(cell2mat(peakfs),2);
    thisys = Ycells{1};
    for count=2:numel(Ycells)
        thisys = thisys + Ycells{count};
    end
    thisys = thisys / numel(Ycells);   
    
    % replace small spectrogram amplitudes with NaN
    % - infrasound
    minyi = min(min(thisyi));
    maxyi = max(max(thisyi));
    yithresh = minyi + (maxyi-minyi) * 0.5; %* 0.675;
    mfi(yithresh > max(thisyi)) = NaN;
    pfi(yithresh > max(thisyi)) = NaN;
    % - seismic
    minys = min(min(thisys));
    maxys = max(max(thisys));
    ysthresh = minys + (maxys-minys) * 0.4; % 0.58;
    mfs(ysthresh > max(thisys)) = NaN;
    pfs(ysthresh > max(thisys)) = NaN;    
    
    % smooth the plots
    smoothsize = 20;
    mfsi = smooth(mfi, smoothsize);
    mfsi(find(isnan(mfi)))=NaN;
     pfsi = smooth(pfi, smoothsize);
     pfsi(find(isnan(pfi)))=NaN;
    mfss = smooth(mfs, smoothsize);
    mfss(find(isnan(mfs)))=NaN;
     pfss = smooth(pfs, smoothsize);
     pfss(find(isnan(pfs)))=NaN;
    
    % plot
    figure
    hmfi=plot(Tcelli{1}, mfsi,'k');
    set(hmfi, 'LineWidth',4);
    datetick('x')
    hold on
    hmfs=plot(Tcells{1}, mfss,'b');
    set(hmfs, 'LineWidth',0.4);
    datetick('x')    
    hpfi=plot(Tcelli{1}, pfsi);
    set(hpfi, 'LineWidth',3,'Color',[0.8 0.8 0.8]);
    datetick('x');
    hpfs=plot(Tcelli{1}, pfss);
    set(hpfs, 'LineWidth',0.3,'Color',[0 0 0.8]);
    datetick('x');    
    ylabel('Frequency (Hz)')
    legend('mean F - infrasound','mean F - seismic', 'peak F - infrasound','peak F - seismic');
    set(gca,'XLim',[Tcelli{1}(1) Tcelli{1}(end)], 'YLim', [0 50]);
    hold off
    suptitle(sprintf('Frequency analysis\n%s',tstr));
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_frequency_parameters.png',dstr)  );
    end
    %input('<ENTER> to continue')
    close
    
    % frequency to velocity
    speed_of_sound = 350;
    T=Tcelli{1};
     
    [maxf,maxf_index]=max(mfsi);
    velocity = speed_of_sound * (maxf./mfsi  - 1);
    velocity(1:maxf_index)=0;
    vals = find(velocity>0);
    X1 = velocity(1:max(vals));
    T1 = T(1:max(vals));
    X1(isnan(X1)) = interp1(find(~isnan(X1)), X1(~isnan(X1)), find(isnan(X1)),'linear'); 
     
    [maxf,maxf_index]=max(pfsi);
    velocity = speed_of_sound * (maxf./pfsi  - 1);
    velocity(1:maxf_index)=0;
    vals = find(velocity>0);
    X2 = velocity(1:max(vals));
    T2 = T(1:max(vals));
    X2(isnan(X2)) = interp1(find(~isnan(X2)), X2(~isnan(X2)), find(isnan(X2)),'linear'); 
    
    figure
    subplot(2,1,1)
    h1=plot(T1,X1/1000);
    set(h1, 'LineWidth',3,'Color',[0 0 0]);
    datetick('x')
    hold on
    h2=plot(T2,smooth(X2/1000));
    set(h2, 'LineWidth',3,'Color',[0.8 0.8 0.8]);
    ylabel('Speed (km/s)');
    datetick('x')
    
    samprate = 1/0.2560;
    subplot(2,1,2)
    h1=plot(T1,cumsum(X1/1000)/samprate);
    set(h1, 'LineWidth',3,'Color',[0 0 0]);
    datetick('x') 
    hold on
    subplot(2,1,2)
    h2=plot(T2,cumsum(smooth(X2/1000))/samprate);
    set(h2, 'LineWidth',3,'Color',[0.8 0.8 0.8]);
    ylabel('Distance (km)');
    datetick('x')    
    %input('<ENTER> to continue')
    suptitle(sprintf('Rocket trajectory\n%s',tstr));
    
    
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_trajectory.png',dstr)  );
    end    
    close
    
    % envelope plot
    figure
    ax1=subplot(2,1,1);
    plot(smooth(hilbert(clean(w(1:3))),1000),'axeshandle',ax1);
    title(sprintf('infrasound amplitude starting at %s',dstr))    
    ax2=subplot(2,1,2);
    plot(smooth(hilbert(clean(w(4:end))),1000),'axeshandle',ax2);
    title(sprintf('seismic amplitude starting at %s',dstr))
    suptitle(sprintf('envelope %s',tstr));
    if publish
        snapnow;
    else
        print('-dpng', sprintf('%s_envelope.png',dstr)  );
    end    
    close  
    
    

    !chmod 775 *.wav *.png
    !chgrp seismiclab *.wav *.png


end

%%
plot_waveform_metrics(catalogobj)


%% make a plot of 1 infrasound & 1 seismic for each event
winfra=[];
wseismic=[];
for eventnum = 1:catalogobj.numberOfEvents
    % get waveform
    w = [catalogobj.waveforms{eventnum}];
    index1 = find(ismember(get(w,'channel'),'HD1_00'));
    index2 = find(ismember(get(w,'channel'),'HHZ_00'));
    if eventnum>1
        daysdiff = abs(get(winfra(end),'start') - get(w(index1),'start'));
        if daysdiff>1
            winfra = [winfra w(index1)];
            wseismic = [wseismic w(index2)];
        end
    else
        winfra = w(index1);
        wseismic = w(index2);
    end

end
plot_panels(winfra,'alignWaveforms',1);
plot_panels(wseismic,'alignWaveforms',1);


%%  
plot_average_frequency(wseismic)

%%


