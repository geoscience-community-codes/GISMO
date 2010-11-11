% This script was used once to create the demo dataset
% private/demo_waveforms.m. It has no further use and is kept only as
% sample. The originla dataset was California earthquake data in SAC files
% provided by Carl Tape. Original source unknown.
%
% To be run from within private directory. At the time demo data was
% created, a directory sample_data was in private/ as well.



% clear
% clear classes
% rmgismo
% addpath('/home/field/GISMO_BRANCH/GISMO/');
% startup_GISMO


% LOAD DATA
fileList = struct2cell(dir('sample_data/9155518*S*.BHZ.*'));
filesZ = strcat('sample_data/', fileList(1,:)');
fileList = struct2cell(dir('sample_data/9155518*S*.BHN.*'));
filesN = strcat('sample_data/', fileList(1,:)');
fileList = struct2cell(dir('sample_data/9155518*S*.BHE.*'));
filesE = strcat('sample_data/', fileList(1,:)');
files = [filesZ filesN filesE];
w = loadsacfile(files);
%save junk


% TRIM SIZE
w = w([36 19 20 4 21 9 18 10 17 11 8 5 14 26],:);


% ADJUST FIELDS
backAzimuth = get(w(:,1),'BAZ');
for n = 1:numel(w)
     w(n) = addfield( w(n) , 'stationLatitude' , get(w(n), 'STLA') ); 
     w(n) = addfield( w(n) , 'stationLongitude' , get(w(n), 'STLO') ); 
     w(n) = addfield( w(n) , 'originLatitude' , get(w(n), 'EVLA') ); 
     w(n) = addfield( w(n) , 'originLongitude' , get(w(n), 'EVLO') );
    channel = get(w(n), 'CHANNEL');
    w(n) = set( w(n) , 'CHANNEL' , channel(1:3) );
    network = get(w(n), 'NETWORK');
    w(n) = set( w(n) , 'NETWORK' , network(1:2) );
end
w = delfield(w,'AZ');
w = delfield(w,'BAZ');
w = delfield(w,'CMPAZ');
w = delfield(w,'CMPINC');
w = delfield(w,'DIST');
w = delfield(w,'EVDP');
w = delfield(w,'GCARC');
w = delfield(w,'HISTORY');
w = delfield(w,'IFTYPE');
w = delfield(w,'IZTYPE');
w = delfield(w,'KEVNM');
w = delfield(w,'KT1');
w = delfield(w, 'KT2');
w = delfield(w,'KUSER0');
w = delfield(w,'LCALDA');
w = delfield(w,'LOVROK');
w = delfield(w,'LPSPOL');
w = delfield(w,'NZHOUR');
w = delfield(w,'NZJDAY');
w = delfield(w,'NZMIN');
w = delfield(w,'NZMSEC');
w = delfield(w,'NZSEC');
w = delfield(w,'NZYEAR');
w = delfield(w,'O');
w = delfield(w,'SCALE');
w = delfield(w,'STDP');
w = delfield(w,'STEL');
w = delfield(w,'T1');
w = delfield(w,'T2');
w = delfield(w,'STLA');
w = delfield(w,'STLO');
w = delfield(w,'EVLA');
w = delfield(w,'EVLO');


% PLOT LOCATIONS
figure;
plot( get(w(:,1),'STATIONLONGITUDE') , get(w(:,1),'STATIONLATITUDE') , 'b+');
hold on;
plot( get(w(:,1),'ORIGINLONGITUDE') , get(w(:,1),'ORIGINLATITUDE') , 'ro');
set(gca,'DataAspectRatio',[1 cosd(35) 1]);
for n=1:length(backAzimuth)
   text( get(w(n,1),'STATIONLONGITUDE') , get(w(n,1),'STATIONLATITUDE') , num2str(n) );
end


% SAVE DEMO DATA
save('demo_waveforms.mat','w','backAzimuth');



