%% RSAM Cookbook
% GISMO can read and plot RSAM data from BOB binary files. GISMO can also
% create RSAM data from waveform objects and save RSAM data to BOB binary
% files, or to text files.

%% Create an RSAM object by hand
t = [0:60:1440]/1440;
y = randn(size(t)) + rand(size(t));
s = rsam(t, y);

%% Load an RSAM binary file:

% For one station we can use an explicit path
dp = 'INETER_DATA/RSAM/MOMN2015.DAT';

% But if we want to load several files, we can use a file pattern
dp = 'INETER_DATA/RSAM/SSSSYYYY.DAT'; %SSSS means station, YYYY means year
s = rsam.read_bob_file('file', dp, 'snum', datenum(2015,1,1), ...
      'enum', datenum(2015,2,1), 'sta', 'MOMN', 'units', 'Counts')



