%% Main function to generate tests
% TEST script modified after Carl Tape's post here:
% https://code.google.com/p/gismotools/source/detail?r=397
% Modified by Glenn Thompson to break down into testable sections
% Testing waveform via trload_css, which breaks for unknown reasons
function tests = trloadcss_test()
tests = functiontests(localfunctions);
end

%% Test Functions
function testFunctionOne(testCase)
%% example 1 - station COLA is okay
    fprintf('\nTest 1\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    scnl = scnlobject('COLA',chan,'','');
    w = waveform(ds,scnl,startTime,endTime)
    fprintf('\nEnd of Test 1\n\n\n\n');
    %%
end

function testFunctionTwo(testCase)
%% example 2 - station COR is a problem
    fprintf('\nTest 2\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    scnl = scnlobject({'COLA';'COR'},chan,'','');
    w = waveform(ds,scnl,startTime,endTime)
    fprintf('\nEnd of Test 2\n\n\n\n');
    %%
end

function testFunctionThree(testCase)
%% example 3 - COLA with new classes
    fprintf('\nTest 3\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    ctag = ChannelTag('','COLA','',chan);
    T=SeismicTrace.retrieve(ds,ctag,startTime,endTime)
    fprintf('\nEnd of Test 3\n\n\n\n');
    %%
end

function testFunctionFour(testCase)
%% example 4 - station COR with new classes
    fprintf('\nTest 4\n');
    startTime = datenum(2009,2,15,19,33,20);
    endTime = datenum(2009,2,15,19,40,0);
    ds = datasource('uaf_continuous');
    chan='BHZ*';
    ctag(1) = ChannelTag('','COLA','',chan);
    ctag(2) = ChannelTag('','COR','',chan);
    T=SeismicTrace.retrieve(ds,ctag,startTime,endTime)
    fprintf('\nEnd of Test 4\n\n\n\n');
    %%
end

% 
function testFunctionFive(testCase)
%% example 5 BEAAR station DH1 is a problem)
    startTime = '2000/07/31 22:44:38';
    endTime = '2000/07/31 23:59:38';
    scnl = scnlobject('*','BHZ_01','','');
    db = '/home/admin/databases/BEAAR/wf/beaar';
    ds = datasource('antelope',db);
    w = waveform(ds,scnl,startTime,endTime)
%%    
end
% 
function testFunctionSix(testCase)
%% example 6 - station AKT is a problem
    startTime = datenum(2011,11,16,16,29,0);
    endTime = startTime + 1/100;
    sta = '*';
    chan = 'HHZ*';
    scnl = scnlobject(sta,chan,'','');
    ds = datasource('uaf_continuous');
    w = waveform(ds,scnl,startTime,endTime)
%%
end

function testFunctionSeven(testCase)
%% example 7 - station AKT is a problem
    startTime = datenum(2011,11,16,16,29,0);
    endTime = startTime + 1/100;
    sta = '*';
    chan = 'HHZ*';
    scnl = scnlobject(sta,chan,'','');
    ctag = ChannelTag('',sta,'',chan);
    ds = datasource('uaf_continuous');
    w = waveform_wrapper(ds, scnl, startTime, endTime)
%%
end

function testFunctionEight(testCase)
%% example 5 BEAAR station DH1 is a problem)
    startTime = '2000/07/31 22:44:38';
    endTime = '2000/07/31 23:59:38';
    scnl = scnlobject('*','BHZ_01','','');
    db = '/home/admin/databases/BEAAR/wf/beaar';
    ds = datasource('antelope',db);
    w = waveform_wrapper(ds,scnl,startTime,endTime)
%%    
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

