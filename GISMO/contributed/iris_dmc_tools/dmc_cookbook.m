function dmc_cookbook


disp('UNDER CONSTRUCTION ...');


% CREATE WAVEFORMS
% These waveforms are empty but contain network_station_channel info
scnl = scnlobject({'CKN' 'CGL' 'CRP' 'CRP' 'CRP' 'CRP' 'SPU' 'CKL' 'CKT' 'BGL' 'NCG' 'JUNK'},'EHZ','AV','');
for n = 1:numel(scnl)
   w(n) = set(waveform,'SCNLOBJECT',scnl(n));
   w(n) = set(w(n),'DATA',rand(1)*sin(2*pi*rand(1):.05:100));
   w(n) = set(w(n),'FREQ',20);
   w(n) = set(w(n),'START',randi([datenum('2008/01/01') datenum('2011/01/01')]));
end

% LOAD TEST DATA FROM THE MASTER EVENT CORRELATION TOOLBOX
load mastercorr_cookbook_data.mat

% QUERY THE IRIS DMC FOR STATION METADATA
% The final waveform does not contains a network_station combination that 
% does not exist in the DMC. No metadata is returned for this station. The
% boolean mask SUCCESS can be used to test for this.
[w,success] = dmc_station_meta(w)
[w,success] = dmc_station_meta(w,'CheckEach')



