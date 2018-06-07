% Working out the functions for multiplet correlatons

LIST='M-2012-05-11-edit2.dat';
WORKING_DIR='~/Desktop/Multiplets';
mkdir(WORKING_DIR);
CORRTHRESH = 0.6;

cd(WORKING_DIR);

% [f] = subset_compare(LIST, CORRTHRESH)
% 
% s = stack_waveforms(LIST, 'TBTN')

% a = pick_times(LIST, 'TBTN')

q = build_arrival(LIST, 'TBTN')




%cd('~/src/GISMO/applications/xcorrlocate')

%% write arrivals to CSS3.0 database
% % must have antelope to create the database
dbpath = './dbpicks';
arrivals.write('antelope', dbpath)

%% write all variables to MAT file
save('arrival_test.mat')



function [arrivals] = build_arrival(LIST, STATION)
% Function for creating an arrival table to import into Antelope


a = pick_times(LIST, STATION);
arrivals = {};
for count = 1:numel(a)
     atime(count) = a{count};
end
N=numel(a);
arrivals = Arrival(repmat({STATION},N,1), repmat({'BHZ'},N,1), atime, repmat({'P'},N,1));


end

function [w_stack] = stack_waveforms(LIST, STATION)
% Function to make a stack from the list of waveforms and return the
% waveform object that contains the stack. 

CORRTHRESH = 0.6;
f = subset_compare(LIST, CORRTHRESH);

N = station_replace(f, 'TBTN', STATION, 1)

w = load_waveforms(N, 0);

c = correlation(w, get(w,'start'));
c2 = xcorr(c);
c3 = adjusttrig(c2, 'median');
c4 = stack(c3);
w_stack = waveform(c4);

plot(w_stack)

end

function [arrival_times] = pick_times(LIST, STATION)
% Function for stacking the waveform subset and making an arrival pick on
% the stack that is applied to each subordinate waveform in the object. 

CORRTHRESH = 0.6;
f = subset_compare(LIST, CORRTHRESH);

N = station_replace(f, 'TBTN', STATION, 1);

w = load_waveforms(N, 0);

c = correlation(w, get(w,'start'));
c2 = xcorr(c);
c3 = adjusttrig(c2, 'median');
c4 = stack(c3);
w2 = waveform(c4);

arrival_times = cell(numel(N),1)
plot(w2(end));
waitforbuttonpress;
waitforbuttonpress;
q = ginput(1);
q = q(1);
pick = datenum(0,0,0,0,0,q);

for count=1:numel(N)
    data = get(w2, 'data');
    [corr, lag] = xcorr(data{count}, data{end}, 'coeff');
    [maxcorr, I] = max(corr);
    lagsamp = lag(I);
    freq = get(w2(count), 'freq');
    lagtime = lagsamp/freq;
    lag_time = datenum(0,0,0,0,0,lagtime);
    start_time = get(w2(count), 'start');
    arrival_times{count} = start_time + lag_time + pick;
end

end

function [final_subset] = subset_compare(LIST, CORRTHRESH)
% Function to cross-reference each subset that is made from
% correlation_distribution() and keeps the waveforms that appear on all
% four stations.

[~, s1, ~] = correlation_distribution(LIST, CORRTHRESH, 'TBTN');
[~, s2, ~] = correlation_distribution(LIST, CORRTHRESH, 'TBMR');
[~, s3, ~] = correlation_distribution(LIST, CORRTHRESH, 'TBHY');
[~, s4, ~] = correlation_distribution(LIST, CORRTHRESH, 'TBHS');

s2 = station_replace(s2, 'TBMR', 'TBTN', 1);
s3 = station_replace(s3, 'TBHY', 'TBTN', 1);
s4 = station_replace(s4, 'TBHS', 'TBTN', 1);

final_subset = cell(1:1);
count = 1;
count2 = 1;
for count = 1:numel(s4)
    if any(strcmp(s2, s4{count})) && any(strcmp(s3, s4{count}))
        final_subset(count2) = s4(count);
        count2 = count2 + 1;
    else
        continue
    end
    count = count + 1;
end

final_subset = transpose(final_subset);

end

function [corr, subset_list, percentile_6] = correlation_distribution(LIST, CORRTHRESH, STATION)
% Function to correlate waveforms and return distribution of correlation
% coefficients. To be used in pre-processing to determine appropriate
% correlation threshold for families. 

w = load_waveforms(LIST, 1)
w = transpose(w)

NEW_LIST = station_replace(w, 'TBTN', STATION, 0); % pick which station to correlate and make distribution

CONDITION = 0; % correlation straight from a list that has a fullfile path

w2 = load_waveforms(NEW_LIST, CONDITION);
w2_clipped = clip_waveforms(w2);
[subset_list, corr] = correlate_waveforms(w2_clipped, CORRTHRESH);

corr = round(corr, 2);
bins = 0.0:0.1:1.0;
[N, EDGES] = histcounts(corr, bins);
percentile_6 = (N(7)+N(8)+N(9)+N(10))/sum(N);

% histfit(corr, 15, 'normal')

end

function [new_subset] = station_replace(SUBSET, STRING, REPLACEMENT, TYPE)
% Function to replace the portion in the filename that tells which station
% an event is recorded on. 


if TYPE == 0 % waveform object 
    h = get(SUBSET, 'history');
    q = numel(h)
    if q == 4
        error('Check to see how many waveforms are in the object')
    else
        new_subset = cell(numel(h),1);
        count = 1;
        for count = 1:numel(h)
            hh = h{count,1}{2,1};
            hh_rep = strrep(hh,'Loaded SAC file: ', '');
            hh_rep2 = strrep(hh_rep, STRING, REPLACEMENT)
            new_subset{count} = hh_rep2;
            count = count + 1;
        end
    end
elseif TYPE == 1 % cell array 
    new_subset = cell(1,1);
    count = 1;
    count2 = 1;
    for count = 1:numel(SUBSET)
        sub = strrep(SUBSET{count}, STRING, REPLACEMENT);
        if exist(sub, 'file')
            new_subset{count2, 1} = sub;
            count2 = count2 + 1;
        else
            continue
        end
        count = count + 1;
    end
else
    warning('something''s up')
end
end

function [clipped_waveforms] = clip_waveforms(WAVEFORM_OBJECT)
% Extract a portion of the waveform for the correlation. This is used in
% conjuction with correlate_waveform() to analyze the same sample as
% PEAKMATCH. Can add inputs to clip the waveform around the peak differently, see loop

w_extracted = extract(WAVEFORM_OBJECT, 'INDEX', 250, 2000) % 5 to 40 sec 

data = get(w_extracted, 'data');
count = 1;
for count = 1:numel(data);
    [m, I] = max(data{count});
    f = get(w_extracted(count), 'freq');
    start = int32(I - (f*4)); % T_BEFORE_PEAK = 4 s
    finish = int32(I + (f*8)); % T_AFTER_PEAK = 8 s
    clipped_waveforms(count) = extract(w_extracted(count), 'INDEX', start, finish);
end

end

function [waveform_object] = load_waveforms(LIST, CONDITION)
% Function for loading waveforms from a file that contains a list of
% waveforms or from an already existing list/cell array of waveforms.
% Returns a waveform object that holds all waveforms in the file.


if CONDITION == 1 % open file and load waveforms 
     fid = fopen(LIST, 'r');
     count = 1;
     while 1
         tline = fgetl(fid);
         if ~ischar(tline), break, end;
         fname = tline;
         d = fname(1:4);
         full = fullfile(d,fname);
         waveform_object(count) = waveform(full, 'sac');
         count = count + 1;
     end
elseif CONDITION == 0 % list/array of waveforms
    count = 1;
    for count = 1:numel(LIST)
        waveform_object(count) = waveform(LIST{count}, 'sac');
        count = count + 1;
    end
else
    error('CONDITION must be 0 or 1, 0 for a fullfile list and 1 to generate the fullfile list')
    
end

end

function [subset_list, corr_m] = correlate_waveforms(WAVEFORM_OBJECT, CORRTHRESH)
% Function to correlate waveforms in a waveform object and keep the
% waveforms that correlate above the given threshold to the master waveform

% create correlation object of the waveforms to do the correlation
c = correlation(WAVEFORM_OBJECT, get(WAVEFORM_OBJECT, 'start'));
c2 = xcorr(c);
corr = get(c2, 'CORR');
corr_m = corr(:,1);
lag = get(c2, 'LAG');

% create object with correlation coefficient above CORRTHRESH
keep = find(corr(:,1) > CORRTHRESH);
c3 = subset(c2, keep);
w3 = waveform(c3);

% Extract the waveform files that correlate above the threshold
h = get(w3, 'history');
q = numel(h);
if q == 4
    error('There is only one waveform in the waveform object!');
else
    subset_list = cell(numel(h), 1)
    count = 1
    for count = 1:numel(h)
        h1 = h{count,1}{2,1};
        h11 = strrep(h1,'Loaded SAC file: ', '');
        subset_list{count} = h11;
        count = count + 1;
    end
end
end


