if ismac
    % Code to run on Mac plaform
    cd('~/Dropbox/scratch_matlab')
elseif isunix
    % Code to run on Linux plaform
    localgismo
    cd('~/Dropbox/scratch_matlab')
elseif ispc
    % Code to run on Windows platform
else
    disp('Platform not supported')
end

close all
clear all
clc
mkdir('ensemble1')
cd('ensemble1')



%% 1. Define datasources, channels etc
dbpath = '/Volumes/data/rockets/rocketmaster2';
ds = datasource('antelope', dbpath); 

if exist('rocketmaster.mat','file')
    load rocketmaster.mat
else
    
    %% 2. Load arrival table into an Arrival object
    arrivalobj = Arrival.retrieve('antelope', dbpath);

    %% 3. Add a short waveform for each arrival for arrival waveform metrics
    pretrigsecs = 2; posttrigsecs = 4;
    arrivalobj = arrivalobj.addwaveforms(ds, pretrigsecs, posttrigsecs);
    save rocketmaster.mat

    %% 4. Compute an amplitude (and other waveform metrics) for each arrival
    max_time_diff = 1.0; % max seconds between min and max
    arrivalobj = arrivalobj.addmetrics(max_time_diff);

    %% 5. Associate arrivals into events in a Catalog
    % 20 seconds seems to be most from BCHH to TANK infrasound
    catalogobj = arrivalobj.associate(20);

    %% 6. Add waveforms for each event in the Catalog
    pretriggersecs = 30; posttriggersecs = 120; % before and after first arrival in event
    ctag = ChannelTag({'FL.BCHH.*.*'});
    catalogobj = catalogobj.addwaveforms(ds, ctag, pretriggersecs, posttriggersecs);

    %% 7. Add waveform metrics to event waveforms in Catalog
    for eventnum = 1:catalogobj.numberOfEvents
        w = [catalogobj.waveforms{eventnum}];
        catalogobj.waveforms{eventnum} = addmetrics(w);
    end

    %% 8. save the data
    save rocketmaster.mat

end

%% 9. write Catalog to Antelope db
[dname, dfile] = fileparts(dbpath);
dbpath2 = sprintf('./%s3',dfile);
if ~exist(dbpath2,'file')
    antelope.dbcp(dbpath, dbpath2); % we need a copy of the site tables
    catalogobj.write('antelope',dbpath2,'overwrite'); % we can overwrite or append to existing tables
end

%% 10. List waveform metrics
catalogobj.list_waveform_metrics()

%% 11. Make seismograms, spectrograms and sound files
for eventnum = 1:catalogobj.numberOfEvents
    % get waveform
    w = [catalogobj.waveforms{eventnum}];
    thisA = catalogobj.arrivals{eventnum};
    dstr = sprintf('Event %2d: %s', eventnum, datestr(min(get(w,'start')), 26));
    
    % plot seismograms
    plot_panels(w(:),'alignwaveforms',1,'arrivals',thisA);
    suptitle(dstr); snapnow; close
    
    % clean data
    w = fillgaps(w, 'interp');
    w = detrend(w);
    
    % plot spectrograms of infrasound channels
    figure
    spectrogram(w(1:3), spectralobject(256,250,100,[30 100])  );
    suptitle(dstr); snapnow; close

    % plot spectrograms of seismic channels
    figure
    spectrogram(w(4:end), spectralobject(256,250,100,[70 140])  );
    suptitle(dstr); snapnow; close
    
    % make sound files
    infrasoundwavname = sprintf('%s_infrasound.wav',datestr(get(w(3),'start')) );
    waveform2sound(w(3), 30,  infrasoundwavname);
    seismicwavname = sprintf('%s_seismic.wav',datestr(get(w(3),'start')) );
    waveform2sound(w(end), 30, seismicwavname);
    
end

%%
%plot_waveform_metrics(catalogobj)

