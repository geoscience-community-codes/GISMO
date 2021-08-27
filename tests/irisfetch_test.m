% irisfetch_test
% Just a script to test if GISMO/waveform can retrieve data from IRIS DMC
% webservices. This wraps iris_fetch.m. If GISMO fails to retrieve data,
% iris_fetch is tested directly to see if the problem is with waveform or
% with iris_fetch. 
% Glenn Thompson 2019/12/14
close all, clc, clear all

%% input parameters
net = 'AV';
sta = 'REF';
loc = '*';
chan = 'EHZ';
startTime = '2009-03-22 06:30:00';
endTime = '2009-03-22 10:30:00';

%% GISMO waveform
ds = datasource('irisdmcws');
chantags = ChannelTag(net, sta, loc, chan);
try
    w = waveform(ds, chantags, startTime, endTime);
    w = w * get(w,'calib');
    figure
    plot(w)
    disp('GISMO/waveform can get data from IRIS DMC web services')
catch
    disp('no waveform data from IRIS DMC web services')
    disp('will now check if iris_fetch works')
    %% iris_fetch
    try
        traces = irisFetch.Traces(net, sta, loc, chan, startTime, endTime);
        figure
        plot(traces.data);
        disp('iris_fetch succeeded. Problem must be with waveform.')
    catch
        disp('iris_fetch failed. Problem must be with iris_fetch');
    end
end
disp(sprintf('%s done',mfilename));

