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
    arrivalobj = Arrival.retrieve('antelope', dbpath);
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
    catalogobj = arrivalobj.associate(20);

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
    %antelope.dbcp(dbpath, dbpath2);
    %%
    catalogobj.write('antelope',dbpath2);
end

%% 10. Make seismograms, spectrograms and sound files
for eventnum = 1:catalogobj.numberOfEvents
    % get waveform
    w = [catalogobj.waveforms{eventnum}];
    thisA = catalogobj.arrivals{eventnum};
    dstr = sprintf('Event %2d: %s', eventnum, datestr(min(get(w,'start')), 26));
    
    % plot seismograms
    plot_panels(w(:),'alignWaveforms',1,'arrivals',thisA);
    suptitle(dstr); snapnow; close
    
    % clean data
    w=clean(w);
    
    % plot spectrograms of infrasound channels
    figure
    spectrogram(w(1:3), 'spectralobject', spectralobject(256,250,100,[30 100]) , 'plot_metrics', 1 );
    suptitle(dstr); 
    print('-dpng', sprintf('%s_infrasound.png',datestr(get(w(1),'start')))  );
    snapnow; close

    % plot spectrograms of seismic channels
    figure
    spectrogram(w(4:end), 'spectralobject', spectralobject(256,250,100,[70 140]), 'plot_metrics', 1  );
    suptitle(dstr); 
    print('-dpng',sprintf('%s_seismic.png',datestr(get(w(1),'start'))) );
    snapnow; close
    
    % make sound files
    infrasoundwavname = sprintf('%s_infrasound.wav',datestr(get(w(1),'start')) );
    waveform2sound(w(3), 30,  infrasoundwavname);
    seismicwavname = sprintf('%s_seismic.wav',datestr(get(w(4),'start')) );
    waveform2sound(w(end), 30, seismicwavname);
    
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



