%% setup
if ~admin.antelope_exists()
    addpath('/opt/antelope/5.7')
    setup
end

% run setup_rocket_event_YYYYMMDD.m first
[~,figureOutDirectory] = fileparts(dbpath);
figureOutDirectory = sprintf('%s_v8',figureOutDirectory)
matfilename = fullfile(figureOutDirectory, 'eventmatfile.mat');
mkdir('.',figureOutDirectory);
diary(fullfile(figureOutDirectory, 'diary.txt'));
diary on

% in NASA data, the bearing the data is coming from is recorded, so need to
% add 180 to get where it is going
wind_direction = mod(wind_direction_from + 180, 360);
% NASA wind speed is in knots, convert into m/s
wind_speed = wind_speed_knots * 0.514444; 

% coords is copied directly out of Excel and is for seismometer, and then
% RWB infrasound. this is how to convert into channel order
lat = [coords(2:4,1); repmat(coords(1,1),3,1) ];
lon = [coords(2:4,2); repmat(coords(1,2),3,1) ];

%% compute speed of sound based on temperature & rel. humidity
temperatureC = fahrenheit2celsius(temperatureF);
speed_of_sound = computeSpeedOfSound(temperatureC, relativeHumidity);
disp(sprintf('speed of sound at %.1f Celsius and %f percent relative humidity is %.1f',temperatureC, relativeHumidity, speed_of_sound));
savedata

%% load waveform data
disp('Loading waveform data...')
w=waveform(ds,scnl,snum,enum);
savedata

%% Filter waveform data to center around zero
wfilt = butterworthFilter(w, 'h', 0.5, 3)
savedata

%% plot raw waveform data
if make_figures
    plot_panels(w);
    outfile = sprintf('%s/waveforms_raw.png',figureOutDirectory)
    feval('print', '-dpng', outfile); 
    close
end 

%% plot filtered waveform data
if make_figures
    plot_panels(wfilt);
    outfile = sprintf('%s/waveforms_filt.png',figureOutDirectory);
    feval('print', '-dpng', outfile); 
    close
end 

%% compute predicted travel times for infrasound waves based on GPS coords & wind
%% also add lat, lon, distance and bacaz fields to waveform objects
predictedTravelTimes;
savedata

%% compute Eastings & Northings
[easting,northing]=latlon2eastingsNorthings(source.lat, source.lon, lat, lon)
savedata

% %% SPACEX ONLY 2016/09/01 override Easting & Northing with data from Laura GPS sruevy, which use WGS84 UTM Zone 17N ellipsoid
% % also see online tools
% source.lon = -80.57719; %-80.57718;
% source.lat = 28.56195; %28.562106;
% 
% easting = [461.091 473.067 447.133 465.217 465.217 465.217];
% northing = [1343.9 1306.23 1320.01 1321.26 1321.26 1321.26];

%% plot array map & compute eastings and northings
eventMap;
savedata

%% Load arrivals
disp('Loading arrivals...')
% add check for arrivals table here
if ~(antelope.dbtable_present(dbpath, 'arrival'))
    return
end
arrivals=Arrival.retrieve('antelope', dbpath);
savedata

%% Subset out N-wave arrivals
disp('Subsetting arrivals...')
arrivals = arrivals.subset('iphase', 'N');
savedata

%% Associate events
maxTimeDiffForAssoc = 0.1;
[cobj, numEvents] = arrivals.associate(maxTimeDiffForAssoc);
savedata

%% Segment event waveforms
pretrigger = 0.2;
posttrigger = 0.3;
wevent = segment_event_waveforms(wfilt, cobj, pretrigger, posttrigger);
savedata

%% Plot infrasound events
if make_figures
    plot_events(wevent, 'waveforms_infrasoundEvent', figureOutDirectory);
end

%% Make automatic measurements
infrasoundEvent = auto_measure_amplitudes(infrasoundEvent, wevent, 'auto_measure_event1', predicted_traveltime_seconds, figureOutDirectory);
save%data

%% Let's add snr values too
for c=1:numEvents
    infrasoundEvent(c).snr = infrasoundEvent(c).p2p./infrasoundEvent(c).rms;
end

%% correlate
infrasoundEvent = xcorr3C(wevent, infrasoundEvent, make_figures, figureOutDirectory, pretrigger)
save%data

%% plot normalized correlation values (3x3 matrix for each event)
a=[infrasoundEvent.maxCorr];
figure
for row=1:3
    for col=1:3
        ind = (row-1) * 3 + col;
        subplot(3,3,ind)
        plot(a(ind:9:end),'.')
        ylabel('r');
        xlabel('event #');%           meanSecsDiff - an array of size N*N where N = number of array
%                          components. Each element represents mean travel
%                          time difference between the array elements
%                          represented by that row and column
    end
end
suptitle('Normalized correlation values for infrasound component pairs');

%% beamform each event, searching for azimuth & speed
disp('Beamforming to estimate backazimuth of source from array & wave speed')
for eventnum = 1:numel(infrasoundEvent)
    [bestbackaz,bestsoundspeed,distanceDiff,speedMatrix] = beamform2d(easting(1:3), northing(1:3), infrasoundEvent(eventnum).secsDiff); 
%     [bestbackaz,bestsoundspeed,distanceDiff,speedMatrix] = beamform2d(easting(1:3), northing(1:3), infrasoundEvent(eventnum).secsDiff, 0, mean(effective_speed)); 
%     [bestbackaz,bestsoundspeed,distanceDiff,speedMatrix] = beamform2d(easting(1:3), northing(1:3), infrasoundEvent(eventnum).secsDiff, mean(backaz)); 
    infrasoundEvent(eventnum).bestbackaz = bestbackaz;
    infrasoundEvent(eventnum).bestsoundspeed = bestsoundspeed;
    infrasoundEvent(eventnum).distanceDiff = distanceDiff;
    infrasoundEvent(eventnum).speedMatrix = speedMatrix;
end
savedata

%% let's choose events only with high correlation values
meanCorrAll=[infrasoundEvent.meanCorr];
good = find(meanCorrAll>=0.8);
bestsoundspeedAll=[infrasoundEvent(good).bestsoundspeed];
bestsoundspeed = median(bestsoundspeedAll);
bestbackazAll=[infrasoundEvent(good).bestbackaz];
bestbackaz = median(bestbackazAll);
disp(sprintf('Based on %d events with a mean xcorr of %.1f or greater, best backaz = %.1f degrees, best sound speed = %.1f m/s',numel(good),0.8,bestbackaz,bestsoundspeed));
save%data

%% compute distance from source to array channels
for chanNum = 1:6
    array_distance_in_km(chanNum) = sqrt(easting(chanNum).^2 + northing(chanNum).^2)/1000.0;
end
save%data

%% compute reduced Pressure
for c=1:numEvents
    infrasoundEvent(c).reducedPressure = infrasoundEvent(c).p2p(1:3).*array_distance_in_km(1:3);
end
save%data

%% compute energies
densityEarth = 2000; % (kg/m3) sandstone is 2000-2650, limestone 2000, wet sand 1950
%pWaveSpeed = 2000; % (m/s) sandstone 2000-3500, limestone 3500-6000, wet sand 1500-2000
densityAir = 1.225; % (kg/m3)
pWaveSpeed = 885; % from onset sub-event
for c=1:numEvents
    ev = infrasoundEvent(c);
    for chanNum = 1:3
        infrasoundEnergy(chanNum) = 2 * pi * (array_distance_in_km(chanNum).^2 * 1e6) * ev.energy(chanNum) / (densityAir * speed_of_sound);
    end
    seismicEnergy = sum(ev.energy(4:6)) * 2 * pi * (array_distance_in_km(6).^2 * 1e6) * densityEarth * pWaveSpeed *1e-18;
    infrasoundEvent(c).infrasoundEnergy = median(infrasoundEnergy);
    infrasoundEvent(c).seismicEnergy = seismicEnergy;
end
save%data

%% get event times
etime=[infrasoundEvent.FirstArrivalTime];
etime_good = etime(good);

%% plot meanSecsDiff vs event time - proof of well correlated events
meanSecsDiff = [infrasoundEvent.meanSecsDiff];
meanSecsDiff_good = [infrasoundEvent(good).meanSecsDiff];

figure
semilogy(etime,meanSecsDiff,'r.');
hold on;
semilogy(etime_good,meanSecsDiff_good,'kx');
datetick('x');
axis tight;
ylabel('Mean Secs Diff');
xlabel('Time');
feval('print','-dpng',fullfile(figureOutDirectory,'meansecsdiff.png'));

%% plot amplitudes vs event time - well correlated events have higher amplitudes
p2p = [infrasoundEvent.p2p];

p2p_good = [infrasoundEvent(good).p2p];
figure
for chanNum = 1:3
    subplot(3,1,chanNum );
    semilogy(etime,p2p(chanNum:6:end),'r.');
    hold on;
    semilogy(etime_good,p2p_good(chanNum:6:end),'kx');
    datetick('x');
    axis tight;
    if chanNum==2
        ylabel('Pressure change Pa');
    end
    if chanNum==3
        xlabel('Time');
    end
end
suptitle('N wave peak-trough amplitude')
feval('print','-dpng',fullfile(figureOutDirectory,'amplitude_infrasound.png'));


%%
figure
for chanNum = 4:6
    subplot(3,1,chanNum-3);
    semilogy(etime,p2p(chanNum:6:end),'r.');
    hold on;
    semilogy(etime_good,p2p_good(chanNum:6:end),'kx');
    datetick('x');
    axis tight;
    if chanNum==5
        ylabel('Velocity change nm/s');
    end
    if chanNum==6
        xlabel('Time');
    end
end
suptitle('N wave peak-trough amplitude')
feval('print','-dpng',fullfile(figureOutDirectory,'amplitude_seismic.png'));

%% plot amplitudes vs event time - well correlated events have higher amplitudes
p2p = [infrasoundEvent.p2p];
p2p_good = [infrasoundEvent(good).p2p];
figure
p2p1 = p2p(1:6:end);
p2p2 = p2p(2:6:end);
p2p3 = p2p(3:6:end);
p2pbest = median([p2p1; p2p2; p2p3],1);
p2pbestgood = p2pbest(good);
subplot(2,1,1);
semilogy(etime,p2pbest,'kx','MarkerSize',4);
hold on;
semilogy(etime_good,p2pbestgood,'ko','MarkerSize',6,'MarkerFaceColor','k');
datetick('x');
axis tight;
ylabel(sprintf('Pressure change\n(Pa)'));
xlabel('Time');
set(gca,'XLim',[datenum(2016,9,1,13,0,0) datenum(2016,9,1,13,36,0)]);
%suptitle('peak to peak amplitude')
% ylims=get(gca,'YLim');
% set(gca,'YLim',[ylims(1)/2,ylims(2)*2]);
% yticks=logspace(log10(ylims(1)/2),log10(ylims(2)*2),7);
% set(gca,'YTick',round(yticks));
set(gca,'YLim',[1 2000]);
set(gca,'YTick',[1 10 100 1000]);

p2p1 = p2p(4:6:end);
p2p2 = p2p(5:6:end);
p2p3 = p2p(6:6:end);
p2pbest = sqrt(p2p1.^2 + p2p2.^2 + p2p3.^2);
p2pbestgood = p2pbest(good);
subplot(2,1,2);
semilogy(etime,p2pbest,'kx','MarkerSize',4);
hold on;
semilogy(etime_good,p2pbestgood,'ko','MarkerSize',6,'MarkerFaceColor','k');
datetick('x');
axis tight;
ylabel(sprintf('Ground velocity\n(nm/sec)'));
xlabel('Time');
%suptitle('N wave peak-trough amplitude')
set(gca,'XLim',[datenum(2016,9,1,13,0,0) datenum(2016,9,1,13,36,0)]);
set(gca,'YLim',[1e4 1e7]);
feval('print','-dpng',fullfile(figureOutDirectory,'N_wave_amplitude.png'));
%%
figure
for chanNum = 4:6
    subplot(3,1,chanNum-3);
    semilogy(etime,p2p(chanNum:6:end),'r.');
    hold on;
    semilogy(etime_good,p2p_good(chanNum:6:end),'kx');
    datetick('x');
    axis tight;
    if chanNum==5
        ylabel('Velocity change nm/s');
    end
    if chanNum==6
        xlabel('Time');
    end
end
suptitle('N wave peak-trough amplitude')
feval('print','-dpng',fullfile(figureOutDirectory,'amplitude_seismic.png'));


%% plot signal-to-noise vs event time - not all well correlated events have good SNR (especially seismic)
snrall = [infrasoundEvent.snr];
snr_good = [infrasoundEvent(good).snr];

figure
for chanNum = 1:3
    subplot(3,1,chanNum );
    plot(etime,snrall(chanNum:6:end),'r.');
    hold on;
    plot(etime_good,snr_good(chanNum:6:end),'kx');
    datetick('x');
    axis tight;
    if chanNum==2
        ylabel('SNR - Infrasound');
    end
    if chanNum==3
        xlabel('Time');
    end
end
feval('print','-dpng',fullfile(figureOutDirectory,'snr_infrasound.png'));
%%
figure
for chanNum = 4:6
    subplot(3,1,chanNum-3);
    plot(etime,snrall(chanNum:6:end),'r.');
    hold on;
    plot(etime_good,snr_good(chanNum:6:end),'kx');
    datetick('x');
    axis tight;
    if chanNum==5
        ylabel('SNR - Seismic');
    end
    if chanNum==6
        xlabel('Time');
    end
end
feval('print','-dpng',fullfile(figureOutDirectory,'snr_seismic.png'));

%% Make master event
masterEvent = make_master_event(infrasoundEvent(good))
savedata

%% beamform master
[Mbestbackaz,Mbestsoundspeed,MdistanceDiff,MspeedMatrix] = beamform2d(easting(1:3), northing(1:3), masterEvent.secsDiff);
MspeedMatrix
savedata

%% relative calibrations
figure;
ratio1v3 = p2p_good(1:6:end)./p2p_good(3:6:end);
ratio2v3 = p2p_good(2:6:end)./p2p_good(3:6:end);
subplot(2,1,1)
plot(etime_good, ratio1v3,'x' );
datetick('x')
ylabel('Amplitude BD1 / BD3')
subplot(2,1,2)
plot(etime_good, ratio2v3,'x' );
ylabel('Amplitude BD2 / BD3')
datetick('x')
suptitle('Calibrations relative to BD3 - based on good events')
disp(sprintf('Amp ratio of BD1 vs BD3: mean %.3f, median %.3f, stdev %.3f',mean(ratio1v3), median(ratio1v3), std(ratio1v3)));
disp(sprintf('Amp ratio of BD2 vs BD3: mean %.3f, median %.3f, stdev %.3f',mean(ratio2v3), median(ratio2v3), std(ratio2v3)));
feval('print','-dpng',fullfile(figureOutDirectory,'calibrations.png'));

%% Compute best sound speed given actual coordinates of source and array
for row=1:3
    for col=1:3
        distDiff(row,col) = arclen(row) - arclen(col);
    end
end
for c=1:numEvents
    d=distDiff./infrasoundEvent(c).secsDiff;
    infrasoundEvent(c).apparentSpeed = nanmean(nanmean(d(1:end)));
    infrasoundEvent(c).apparentSpeedError = nanstd(d(1:end));
end
save%data

%% write events to csv file
writeEvents(fullfile(figureOutDirectory, 'catalog.csv'), infrasoundEvent, array_distance_in_km);

%% particle motion for all good events
for c=1:numEvents
    thisw = wevent{c};
    t = threecomp(thisw([6 5 4])',199);
    tr = t.rotate()
    tr2 = tr.particlemotion();
    tr2.plotpm()
    feval('print','-dpng',fullfile(figureOutDirectory,sprintf('pm_event%03d.png',c)));
    close
end

% %% spectrum for all good events
% for c=1:numEvents
%     plot_spectrum(wevent{c});
%     feval('print','-dpng',fullfile(figureOutDirectory,sprintf('spectrum_event%03d.png',c)));
%     close
% end

%% time shift traces & produce a stacked infrasound trace, and save them


%% look for P arrival by stacking on ground coupled airwaves for good events
% let's plot the Z channel first for all events with a normalized waveform
% plot

%%

if 0 
    %% plot largest event
    wlargestevent = extract(wfilt, 'time', datenum(2016,9,1,13,7,10), datenum(2016,9,1,13,7,45));
    plot_panels(wlargestevent);
    %%
    plot_spectrum(wlargestevent([2 6]));
    legend('Infrasound 2 (Pa/Hz)','Seismic Z (nm/sec/Hz)','location','south')
    grid on
    %%
    t = threecomp(wlargestevent([6 5 4])',199.5);
    tr = t.rotate()
    tr2 = tr.particlemotion();
    tr2.plotpm()

    %% plot buildup
    wbu = extract(wfilt, 'time', datenum(2016,9,1,13,7,21), datenum(2016,9,1,13,7,28));
    plot_panels(wbu);
    plot_spectrum(wbu([2 6]));
    legend('Infrasound 2 (Pa/Hz)','Seismic Z (nm/sec/Hz)','location','south')
    grid on
    t = threecomp(wbu([6 5 4])',199.5);
    tr = t.rotate()
    tr2 = tr.particlemotion();
    tr2.plotpm()
    %%
    scroll(wbu,16)

    %% Helicorder plots for whole sequence
    plot_helicorder(wfilt(2),'scale',20,'mpl',1);
    plot_helicorder(wfilt(6),'scale',20,'mpl',1);
    %% Plot ZRT seismogram
    t = threecomp(wfilt([6 5 4])',199.5);
    tr = t.rotate()
    tr2 = tr.particlemotion();
    tr2.plotpm()
    %% Plot R helicorder
    wzrt=get(tr,'waveform');
    %plot_helicorder(wzrt(2),'scale',10,'mpl',1);
    %%
    mkdir('sacfiles')
    savesac(wzrt(1,1), 'sacfiles', 'wz.sac');
    savesac(wzrt(1,2), 'sacfiles', 'wr.sac');
    savesac(wzrt(1,3), 'sacfiles', 'wt.sac');
    %%
    for c=1:numel(wzrt)
        0
        wzrt(1,c)
        1
        ct = get(wzrt(c),'ChannelTag')
        2
        savesac(wzrt(c), 'sacfiles', sprintf('%s.sac',ct.string()));
    end
    %%
end
diary off