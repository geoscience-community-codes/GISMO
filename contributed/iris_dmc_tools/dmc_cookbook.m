function dmc_cookbook
%% DMC COOKBOOK (LEGACY)
%
% This cookbook demonstrates legacy IRIS DMC access using irisFetch.m
% and the Java IRIS-WS library.
%
% IMPORTANT (EarthScope Aug 2024):
%   irisFetch and IRIS-WS DO NOT WORK on MATLAB R2023a or newer.
%   This cookbook is supported ONLY on MATLAB R2022b and earlier.
%
% For modern FDSN access, use:
%   - ObsPy (Python)
%   - Direct FDSN REST APIs
%
% This file is retained for reproducibility of legacy GISMO workflows.


% CREATE WAVEFORMS
% These waveforms are empty but contain network_station_channel info
stas = {'CKN' 'CGL' 'CRP' 'CRP' 'CRP' 'CRP' 'SPU' 'CKL' 'CKT' 'BGL' 'NCG' 'JUNK'};

chanTags = ChannelTag.array('AV',stas,'--','EHZ');
for n = numel(chantags) : -1 : 1;
   w(n) = set(waveform,'channelinfo',chanTags(n));
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



