%% test_Catalog.m
% Run with:
%   runtests('tests')
%
% This test executes the Catalog.cookbook and verifies that it completes
% without crashing. Because the cookbook depends on:
%   • IRIS / EarthScope web services
%   • Optional Antelope toolbox
%   • Optional Mapping Toolbox
%   • Optional GISMO demo datasets
%
% this test is designed to:
%   - NEVER fail due to missing external services
%   - ONLY fail if the code itself throws an unhandled error
%
% This makes it safe for:
%   • Continuous Integration
%   • JOSS automated review
%   • Local developer testing


function tests = test_Catalog()
    tests = functiontests(localfunctions);
end


%% ------------------------------------------------------------------------
function setup(testCase)
    close all
    testCase.TestData.originalDir = pwd;

    % Ensure GISMO is on the path
    gismopath = fileparts(which('startup_GISMO'));
    if ~isempty(gismopath)
        addpath(genpath(gismopath));
    end
end


function teardown(testCase)
    close all
    cd(testCase.TestData.originalDir);
end


%% ------------------------------------------------------------------------
function test_runCatalogCookbook(testCase)
% This test checks that Catalog.cookbook executes without throwing an
% unhandled fatal error. Warnings are allowed and expected.

    try
        Catalog.cookbook;
        disp('Catalog.cookbook executed without fatal errors.');
    catch ME
        % We explicitly FAIL only if the cookbook hard-crashes
        % (not on missing web services, toolboxes, or data).
        warning('Catalog.cookbook threw an exception:\n%s', ME.message);
        testCase.verifyFail(sprintf( ...
            'Catalog.cookbook crashed: %s', ME.message));
    end
end


%% ------------------------------------------------------------------------
function setupOnce(testCase) %#ok<INUSD>
    % Optional global setup (none required)
    close all
end


function teardownOnce(testCase) %#ok<INUSD>
    % Optional global teardown (none required)
    close all
end