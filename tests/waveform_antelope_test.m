%% Main function to generate tests
function tests = waveform_antelope_test()
    tests = [];
    try 
        if ~admin.antelope_exists()
            disp('ATM not working')
            return
        end
    catch
        disp('Probably could not find admin.antelope_exists()')
    end
    tests = functiontests(localfunctions);
end

%% Test Functions
function w=testFunctionOne(testCase)
%% old style
    global TESTDATA
    w=waveform();
    gismodir = fileparts(which('startup_GISMO'));
    demodbpath = fullfile(TESTDATA, 'css3.0', 'demodb')
    ds = datasource('antelope',demodbpath);
    scnl = scnlobject('RSO','EHZ');
    snum = datenum(2009,3,20);
    enum = datenum(2009,3,20,1,0,0);
    flist=antelope.listMiniseedFiles(ds,scnl,snum,enum)
    %if sum(flist.exists)>0
        w=waveform(ds,scnl,snum,enum);
        w=combine(w);
    %else
        disp('No waveform files found')
    %end
    w
%%
end

function w=testFunctionTwo(testCase)
%% new style
    T=SeismicTrace();
    gismodir = fileparts(which('startup_GISMO'));
    demodbpath = fullfile(gismodir, 'tests', 'test_data', 'demodb');
    ds = datasource('antelope',demodbpath);
    ctag = ChannelTag('.RSO..EHZ');
    flist=antelope.listMiniseedFiles(ds,ctag,datenum(2009,3,20),datenum(2009,3,20,1,0,0));
    if sum(flist.exists)>0
        T=SeismicTrace.retrieve(ds,ctag,datenum(2009,3,20),datenum(2009,3,20,1,0,0));
        T=T.combine();
    else
        disp('No waveform files found')
    end
    T
%%    
end

function w=testFunctionThree(testCase)
%% old style
    w=waveform();
    gismodir = fileparts(which('startup_GISMO'));
    demodbpath = fullfile(gismodir, 'tests', 'test_data', 'demodb');
    ds = datasource('antelope',demodbpath);
    scnl = scnlobject('RSO','EHZ');
    flist=antelope.listMiniseedFiles(ds,scnl,datenum(2009,3,20),datenum(2009,3,20,1,0,0));
    if sum(flist.exists)>0
        w=waveform_wrapper(ds,scnl,datenum(2009,3,20),datenum(2009,3,20,1,0,0));
        w=combine(w);
    else
        disp('No waveform files found')
    end
    w
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
disp('**********************')
end

function teardown(testCase)  % do not change function name
% close figure, for example
close all
end
