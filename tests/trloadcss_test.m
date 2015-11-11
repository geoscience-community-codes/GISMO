% TEST script modified after Carl Tape's post here:
% https://code.google.com/p/gismotools/source/detail?r=397
% Modified by Glenn Thompson to break down into testable sections
% Testing waveform via trload_css, which breaks for unknown reasons

%% example 1 - station COR is a problem
startTime = 7.338198148159491e+05;
endTime = 7.338198194455787e+05;
chan = 'BHZ*';
datestr(startTime)
% this will work, even though COR is the problem
%scnl = scnlobject({'COLA','COR','KDAK'},chan,'','');
% this will fail when asking for all stations
scnl = scnlobject('*',chan,'','');
ds = datasource('uaf_continuous');
% trload_css error -- this will return nothing
w = waveform(ds,scnl,startTime,endTime); whos w
    
%% Yun's fix (works only with her modified waveform.m and load_antelope_workaround.m)
% this will return 196 stations
%w = waveform(ds,scnl,startTime,endTime,true); whos w

%% example 2 BEAAR station DH1 is a problem)
startTime = '2000/07/31 22:44:38';
endTime = '2000/07/31 23:59:38';
scnl = scnlobject('*','BHZ_01','','');
db = '/home/admin/databases/BEAAR/wf/beaar';
ds = datasource('antelope',db);
% trload_css error -- this will return nothing
w = waveform(ds,scnl,startTime,endTime); whos w

%% Yun's fix (works only with her modified waveform.m and load_antelope_workaround.m)
% this will return 24 stations
%w = waveform(ds,scnl,startTime,endTime,true); whos w

%% example 3 - station AKT is a problem
%startTime = 734823;
startTime = datenum(2011,11,16,16,29,0);
endTime = startTime + 1/100;
sta = '*';
chan = 'HHZ*';
scnl = scnlobject(sta,chan,'','');
ds = datasource('uaf_continuous');
% trload_css error -- this will return nothing
w = waveform(ds,scnl,startTime,endTime); whos w

%% Yun's fix (works only with her modified waveform.m and load_antelope_workaround.m)
% this will return 3 stations
%w = waveform(ds,scnl,startTime,endTime,true);

