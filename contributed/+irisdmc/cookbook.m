function cookbook
%% IRISDMC COOKBOOK (LEGACY / DEPRECATED)
%
% This cookbook demonstrates legacy IRIS DMC station metadata retrieval
% using the irisdmc package and the Java IRIS-WS library.
%
% IMPORTANT (EarthScope Aug 2024):
%   • This code relies on the legacy IRIS Java Web Services library.
%   • MATLAB R2023a and later are NOT supported due to JVM changes.
%   • Supported MATLAB versions: R2022b and earlier ONLY.
%
% This file is retained for historical reproducibility of earlier GISMO
% workflows and is NOT part of the modern supported API.
%
% For modern station metadata access use:
%   • ObsPy (Python)
%   • FDSN Station REST services

% CREATE WAVEFORMS
% These waveforms are empty but contain network_station_channel info
stas = {'CKN' 'CGL' 'CRP' 'CRP' 'CRP' 'CRP' 'SPU' 'CKL' 'CKT' 'BGL' 'NCG' 'JUNK'};
chanTags = ChannelTag.array('AV', stas,'','EHZ'); 
for n = numel(chanTags) : -1 : 1
   w(n) = set(waveform,'channelinfo',chanTags(n));
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



