%% Main function to generate tests
function tests = waveform_antelope_test()
tests = functiontests(localfunctions);
end

%% Test Functions
function testFunctionOne(testCase)
%%
    gismodir = fileparts(which('startup_GISMO'));
    demodbpath = fullfile(gismodir, 'tests', 'test_data', 'demodb');
    scnl = scnlobject('RSO','EHZ')
    ctag = ChannelTag('.RSO..EHZ')
    ds = datasource('antelope',demodbpath)
    flist=antelope.listMiniseedFiles(ds,ctag,datenum(2009,3,20),datenum(2009,3,20,1,0,0))
    if sum(flist.exists)>0
        w=waveform(ds,ctag,datenum(2009,3,20),datenum(2009,3,20,1,0,0))
    else
        disp('No waveform files found')
    end
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
