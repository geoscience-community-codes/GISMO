function Multipletscorrelation()


clear all
close all
clc
STATIONS = {'TBTN';'TBMR';'TBHY';'TBHS'};
POSTTRIG = 20

%% THIS IS THE ONLY SECTION IN THE SCRIPT THAT NEEDS CHANGED
%SIMPLY CHANGE THE WORKING DIRECTORY AND THE FILENAME TO RUN IT
%NOTE: MUST HAVE THE SAME DATA STRUCTURE AND NAMING SCHEME AS
%MEL'S DATA

MULTIPLETS_TOP_DIR = '~/Desktop/Multiplets';
PEAKMATCH_OUTPUT_FILE = 'M-2012-05-11-edit2.dat';

% Move to the working directory that contains the correct data structure
% for this script, which is...
cd(MULTIPLETS_TOP_DIR);

[stacked_waveform, waveforms_that_went_into_stack] = stackwaveforms(PEAKMATCH_OUTPUT_FILE, POSTTRIG, STATIONS);
stack_onset_time = manually_pick_onset_time(stacked_waveform);
arrivals = find_onset_times(stacked_waveforms); % xcorr
write_arrivals_to_antelope(arrivals, dbname); 

end

function stacked_waveforms = stackwaveforms(PEAKMATCH_OUTPUT_FILE, POSTTRIG, STATIONS)
% % Author: Mitchell Hastings
% % Welcome Weary Seismologists!
% % This is a .m script made to automate the process of creating a subset
% % of waveforms at each station at Telica volcano, Nicaragua. This script
% % can work with any kind of waveform data if you are making subsets of
% % families of waveforms. This script was written for the purpose of a class
% % project for Steve McNutt's Volcano Seismology course. The author is tired
% % and wishes to no longer continue modulating this script, but he may come
% % back to doing so....eventually...
%% NOW HACKED BY GLENN to
% use functions, structures, loops, meaningful variable names
% remove station names hardwired into variable names

% Read in file that has the original list of the Multiplets and all
% member events (this is for station TBTN only, that is all PeakMatch was run for)
fid = fopen(PEAKMATCH_OUTPUT_FILE,'r');

%% TBTN--------------------------------------------------------------------
% loop to read in each line and read the corresponding SAC file into the
% next element of the waveform vector, w
count = 1;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end;
    fname = tline;
    d = fname(1:4);
    full = fullfile(d,fname);
    w(count) = waveform(full, 'sac');
    count = count + 1;
end

% cross-correlate each element of w against every other
c = correlation(w, get(w, 'start'));
c2 = xcorr(c, [1 POSTTRIG]);
corr = get(c2, 'CORR');
lag = get(c2, 'LAG');

% create correlation object with correlation coefficient above 0.7
corrthresh = 0.7;
keep = find(corr(:,1) > corrthresh);
c3 = subset(c2, keep);

% create waveform vector for these 
w3 = waveform(c3);

% Extract the waveform files that correlate above the threshold
h = get(w3, 'history');
subset_list = cell(numel(h), 1);
count = 1;
for count = 1:numel(h)
    h1 = h{count,1}{2,1};
    h11 = strrep(h1,'Loaded SAC file: ', '');
    subset_list{count} = h11;
    count = count + 1;
end

% Use the subset_list to find the waveforms that correlate above the
% threshold on other stations

%% TBMR--------------------------------------------------------------------

% this loop makes a cell array for the subset of events on station TBMR
subMR = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBTN', 'TBMR');
    subMR{count} = sub;
    count = count + 1;
end

% this loop creates a waveform object for the subset on TBMR
count = 1;
for count = 1:numel(subMR)
    w_subMR(count) = waveform(subMR{count}, 'sac');
    count = count + 1;
end

% Now this step is to do the correlation with the subset on TBMR
clear c, c2, corr, lag, keep, c3, w3, h, subset_list, h1, h11

% create correlation object of the waveforms to do the correlation
c = correlation(w_subMR, get(w_subMR, 'start'));
c2 = xcorr(c, [1 POSTTRIG]);
corr = get(c2, 'CORR');
lag = get(c2, 'LAG');

% create object with correlation coefficient above 0.7
corrthresh = 0.7;
keep = find(corr(:,1) > corrthresh);
c3 = subset(c2, keep);
w3 = waveform(c3);

% Extract the waveform files that correlate above the threshold
h = get(w3, 'history');
subset_list = cell(numel(h), 1);
count = 1;
for count = 1:numel(h)
    h1 = h{count,1}{2,1};
    h11 = strrep(h1,'Loaded SAC file: ', '');
    subset_list{count} = h11;
    count = count + 1;
end

%% TBHY--------------------------------------------------------------------

% this loop makes a cell array for the subset of events on station TBMR
subHY = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBMR', 'TBHY');
    subHY{count} = sub;
    count = count + 1;
end

% this loop creates a waveform object for the subset on TBMR
count = 1;
for count = 1:numel(subHY)
    w_subHY(count) = waveform(subHY{count}, 'sac');
    count = count + 1;
end

% Now this step is to do the correlation with the subset on TBHY
clear c, c2, corr, lag, keep, c3, w3, h, subset_list, h1, h11

% create correlation object of the waveforms to do the correlation
c = correlation(w_subHY, get(w_subHY, 'start'));
c2 = xcorr(c, [1 POSTTRIG]);
corr = get(c2, 'CORR');
lag = get(c2, 'LAG');

% create object with correlation coefficient above 0.7
corrthresh = 0.7;
keep = find(corr(:,1) > corrthresh);
c3 = subset(c2, keep);
w3 = waveform(c3);

% Extract the waveform files that correlate above the threshold
h = get(w3, 'history');
subset_list = cell(numel(h), 1);
count = 1;
for count = 1:numel(h)
    h1 = h{count,1}{2,1};
    h11 = strrep(h1,'Loaded SAC file: ', '');
    subset_list{count} = h11;
    count = count + 1;
end

%% TBHS--------------------------------------------------------------------

% this loop makes a cell array for the subset of events on station TBMR
subHS = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBHY', 'TBHS');
    subHS{count} = sub;
    count = count + 1;
end

% this loop creates a waveform object for the subset on TBMR
count = 1;
for count = 1:numel(subHS)
    w_subHS(count) = waveform(subHY{count}, 'sac');
    count = count + 1;
end

% Now this step is to do the correlation with the subset on TBHY
clear c, c2, corr, lag, keep, c3, w3, h, subset_list, h1, h11

% create correlation object of the waveforms to do the correlation
c = correlation(w_subHS, get(w_subHS, 'start'));
c2 = xcorr(c, [1 POSTTRIG]);
corr = get(c2, 'CORR');
lag = get(c2, 'LAG');

% create object with correlation coefficient above 0.7
corrthresh = 0.7;
keep = find(corr(:,1) > corrthresh);
c3 = subset(c2, keep);
w3 = waveform(c3);

% Extract the waveform files that correlate above the threshold
h = get(w3, 'history');
subset_list = cell(numel(h), 1);
count = 1;
for count = 1:numel(h)
    h1 = h{count,1}{2,1};
    h11 = strrep(h1,'Loaded SAC file: ', '');
    subset_list{count} = h11;
    count = count + 1;
end

%% CREATE A LIST FOR THE NEW SUBSET FOR EACH STATION

% this loop makes a cell array for the new subset on TBTN
subset_TBTN = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBHY', 'TBTN');
    subset_TBTN{count} = sub;
    count = count + 1;
end

% this loop makes a cell array for the new subset on TBMR
subset_TBMR = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBHY', 'TBMR');
    subset_TBMR{count} = sub;
    count = count + 1;
end

% this loop makes a cell array for the new subset on TBHS
subset_TBHS = cell(numel(subset_list),1);
count = 1;
for count = 1:numel(subset_list)
    sub = strrep(subset_list{count}, 'TBHY', 'TBHS');
    subset_TBHS{count} = sub;
    count = count + 1;
end

% this loop makes a cell array for the new subset on TBHY
subset_TBHY = subset_list;

%% WRITE THE SUBSETS TO .DAT FILES

% Ensure that the previous file being read is closed
% fclose(fid);

% loops to create the .dat files
fid = fopen('Subset-TBTN.dat', 'w');
for row = 1:numel(subset_TBTN)
    fprintf(fid, '%s\n', subset_TBTN{row});
end
fclose(fid);

fid = fopen('Subset-TBMR.dat', 'w');
for row = 1:numel(subset_TBMR)
    fprintf(fid, '%s\n', subset_TBMR{row});
end
fclose(fid);

fid = fopen('Subset-TBHY.dat', 'w');
for row = 1:numel(subset_TBHY)
    fprintf(fid, '%s\n', subset_TBHY{row});
end
fclose(fid);

fid = fopen('Subset-TBHS.dat', 'w');
for row = 1:numel(subset_TBHS)
    fprintf(fid, '%s\n', subset_TBHS{row});
end
fclose(fid);

%% CORRELATIONS AND STACKS WITH THE SUBSET THAT APPEARS ON ALL STATIONS

% load final waveform subset in for generating the stacks

% TBTN
for count = 1:numel(subset_TBTN)
    fname = subset_TBTN{count};
    WTN(count) = waveform(fname, 'sac');
    count = count + 1;
end

CTN = correlation(WTN, get(WTN, 'start'));
CTN2 = xcorr(CTN, [1 POSTTRIG]);
corr = get(CTN2, 'CORR'); % just to check correlation coefficients
CTN3 = adjusttrig(CTN2, 'median');

% plot(CTN3);

CTN4 = stack(CTN3);
% plot(CTN4);
WTN4 = waveform(CTN4);
plot(WTN4(end)); % stacked waveform
% plot(WTN4(1)); % master waveform
plot_panels(WTN4, 'alignWaveform', 1)

% TBMR
clear fname;
for count = 1:numel(subset_TBMR)
    fname = subset_TBMR{count};
    WMR(count) = waveform(fname, 'sac');
    count = count + 1;
end

CMR = correlation(WMR, get(WMR, 'start'));
CMR2 = xcorr(CMR, [1 POSTTRIG]);
corr = get(CMR2, 'CORR'); % just to check correlation coefficients
CMR3 = adjusttrig(CMR2, 'median');

% plot(CMR3);

CMR4 = stack(CMR3);
% plot(CMR4);
WMR4 = waveform(CMR4);
plot(WMR4(end)); % stacked waveform
%plot(WMR4(1)); % master waveform
plot_panels(WMR4, 'alignWaveform', 1)
% TBHY
clear fname
for count = 1:numel(subset_TBHY)
    fname = subset_TBHY{count};
    WHY(count) = waveform(fname, 'sac');
    count = count + 1;
end

CHY = correlation(WHY, get(WHY, 'start'));
CHY2 = xcorr(CHY, [1 POSTTRIG]);
corr = get(CHY2, 'CORR'); % just to check correlation coefficients
CHY3 = adjusttrig(CHY2, 'median');

% plot(CHY3);

CHY4 = stack(CHY3);
% plot(CHY4);
WHY4 = waveform(CHY4);
plot(WHY4(end)); % stacked waveform
%plot(WHY4(1)); % master waveform
plot_panels(WHY4, 'alignWaveform', 1)

% TBHS
clear fname
for count = 1:numel(subset_TBHS)
    fname = subset_TBHS{count};
    WHS(count) = waveform(fname, 'sac');
    count = count + 1;
end

CHS = correlation(WHS, get(WHS, 'start'));
CHS2 = xcorr(CHS, [1 POSTTRIG]);
corr = get(CHS2, 'CORR'); % just to check correlation coefficients
CHS3 = adjusttrig(CHS2, 'median');

% plot(CHS3);

CHS4 = stack(CHS3);
% plot(CHS4);
WHS4 = waveform(CHS4);
plot(WHS4(end)); % stacked waveform
% plot(WHS4(1)); % master waveform
plot_panels(WHS4, 'alignWaveform', 1)

end

function stack_onset_time = manually_pick_onset_time(stacked_waveform);
    plot(stacked_waveform)
    [t,y]=ginput(1);
    close
    stack_onset_time = get(stacked_waveform,'start') + t/86400;
end

function arrivalobj = find_onset_times(stacked_waveforms); % xcorr
% Maths to use for computing arrival time:
%   where:
%       wEvent is a real event
%       lagSeconds is xcorr(wstack, wEvent)
%       onsetDelaySeconds is how far into stack we pick the arrival onset
%       arrivalDatenum = wEventDateNum + (lagSeconds + onsetDelaySeconds)/SECONDS_PER_DAY
%
% This test example shows that xcorr(a,b) where b is a delayed by 1 sample produces a lag of -1
end

function write_arrivals_to_antelope(arrivals, dbname); 
% build a Catalog object
end



function ignore_these_notes
%% STUFF ADDED BY GLENN
% Maths to use for computing arrival time:
%   where:
%       wEvent is a real event
%       lagSeconds is xcorr(wstack, wEvent)
%       onsetDelaySeconds is how far into stack we pick the arrival onset
%       arrivalDatenum = wEventDateNum + (lagSeconds + onsetDelaySeconds)/SECONDS_PER_DAY
%
% This test example shows that xcorr(a,b) where b is a delayed by 1 sample produces a lag of -1
%
%     b = randn(1,10) + [0 0 0 0 0 10 0 0 0 0];
%     a = randn(1,10) + [0 0 0 0 10 0 0 0 0 0];
%     [acor,lag] = xcorr(a,b);
%     plot(lag,acor)
%
% then we create Arrival objects, add them into Catalog object
%
% write Catalog object to Antelope database
%
% Linux script Antelope relocate or dbgenloc or dblocsat to locate events using those Arrivals time
% Also drive db2kml to plot in Google Earth (or GMT)

end



