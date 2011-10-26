function cookbook

%COOKBOOK example program using the IRIS DMC web services
% COOKBOOK This is a simple example designed to demonstrate how the 
% IRIS DMC web services mechanism can be used to grab seismic metadata 
% from within Matlab. This example fetches basic station metadata.
%
% For more information about the IRIS DMC Web Services, see:
%    http://www.iris.edu/ws


% CREATE WAVEFORMS
% These waveforms are empty but contain network_station_channel info
scnl = scnlobject({'CKN' 'CGL' 'CRP' 'CRP' 'CRP' 'CRP' 'SPU' 'CKL' 'CKT' 'BGL' 'NCG' 'JUNK'},'EHZ','AV','');
for n = 1:numel(scnl)
   w(n) = set(waveform,'SCNLOBJECT',scnl(n));
   w(n) = set(w(n),'DATA',rand(1)*sin(2*pi*rand(1):.05:100));
   w(n) = set(w(n),'FREQ',20);
   w(n) = set(w(n),'START',randi([datenum('2008/01/01') datenum('2011/01/01')]));
end


% LOAD ANOTRHER TEST DATA SET (FROM THE MASTER EVENT CORRELATION TOOLBOX)
W6 = mastercorr.load_cookbook_data;


% QUERY THE IRIS DMC FOR STATION METADATA
% The final waveform in this example contains a network_station combination 
% that does not exist in the DMC. No metadata is returned for this station. The
% boolean mask SUCCESS can be used to test for this.
[w,success] = irisdmc.station_meta(w)


% CHECK EACH WAVEFORM INDIVIDUALLY EVEN THOUGH THEY ARE THE SAME STA/CHAN
[W6,success] = irisdmc.station_meta(W6,'CheckEach')



