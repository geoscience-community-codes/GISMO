%% Main function to generate tests
% TEST script modified after Carl Tape's post here:
% https://code.google.com/p/gismotools/source/detail?r=397
% Modified by Glenn Thompson to break down into testable sections
% Testing waveform via trload_css, which breaks for unknown reasons
function tests = trloadcss_test()
    % warning on
    % coredir=fileparts(fileparts(which('Catalog')));
    % addpath(fullfile(coredir, 'dev'));
    tests = functiontests(localfunctions);
end

% %% Test Functions

function testFunctionOne(testCase)
%% example 1 - station COLA is okay
    fprintf('\nTest 1\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    sta = 'COLA';
    w=waveform(ds, scnlobject(sta,chan), startTime, endTime)
end

function testFunctionTwo(testCase)
%% example 2 - station COR is a problem
    fprintf('\nTest 2\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    sta = {'COLA';'COR'};
    w=waveform(ds, scnlobject(sta,chan), startTime, endTime)
end



function testFunctionThree(testCase)
%% example 5 BEAAR station DH1 is a problem)
    startTime = '2000/07/31 22:44:38';
    endTime = '2000/07/31 23:59:38';
    sta = {'BYR';'CAR';'DH1'};
    chan = 'BHZ_01';
    dbpath = '/home/admin/databases/BEAAR/wf/beaar';
    ds = datasource('antelope',dbpath);
    w=waveform(ds, scnlobject(sta,chan), startTime, endTime)
end

function testFunctionFour(testCase)
%% example 5 BEAAR station DH1 is a problem)
    startTime = '2000/07/31 22:44:38';
    endTime = '2000/07/31 23:59:38';
    sta = '*';
    chan = 'BHZ_01';
    dbpath = '/home/admin/databases/BEAAR/wf/beaar';
    ds = datasource('antelope',dbpath);
    w=waveform(ds, scnlobject(sta,chan), startTime, endTime)
end
 
function testFunctionSix(testCase)
%% example 6 - station AKT is a problem
    startTime = datenum(2011,11,16,16,29,0);
    endTime = startTime + 1/100;
    sta = '*';
    chan = 'HHZ*';
    scnl = scnlobject(sta,chan,'','');
    ds = datasource('uaf_continuous');
    w = waveform(ds,scnl,startTime,endTime)
end

function testFunctionSeven(testCase)
%% example 7 - test over a day boundary
    startTime = '2009/03/21 23:00:00';
    endTime = '2009/03/22 01:00:00';
    sta = {'REF';'RSO'};
    chan = 'EHZ';
    scnl = scnlobject(sta,chan,'','');
    ds = datasource('uaf_continuous');
    w = waveform(ds,scnl,startTime,endTime)
end

function testFunctionEight(testCase)
%% example 7 - test multiple start/endtimes
    startTimes = ['2009/03/21 23:00:00';'2009/03/22 01:00:00'];
    endTimes = ['2009/03/21 23:05:00';'2009/03/22 01:05:00'];
    sta = {'REF';'RSO'};
    chan = 'EHZ';
    scnl = scnlobject(sta,chan,'','');
    ds = datasource('uaf_continuous');
    w = waveform(ds,scnl,startTimes,endTimes)
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
    % set a new path, for example
end

function teardownOnce(testCase)  % do not change function name
    % change back to original path, for example
end

%% Optional fresh fixtures  
function setup(testCase)  % do not change function name
    % open a figure, for example
    disp('***********************************')
    close all
end

function teardown(testCase)  % do not change function name
    % close figure, for example
    close all
end

function [ds,chan,startTime,endTime]=setdatasource1()
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
end

function tryAllSources(ds, sta, chan, startTime, endTime)
    scnl = scnlobject(sta, chan);
    disp('Trying waveform')
    w = tryWaveform(ds, scnl, startTime, endTime)
    disp('**************')
%     disp('Trying waveform_wrapper')
%     w = tryWaveformWrapper(ds, scnl, startTime, endTime)
%     disp('**************')
%     disp('Trying SeismicTrace')    
%     tr = trySeismicTrace(ds, scnl, startTime, endTime)
%     disp('**************')
%     disp('Trying antelope2waveform')
%     dbpath=get(ds,'location');
%     w = antelope.antelope2waveform(dbpath, sta, chan, startTime, endTime)
end


