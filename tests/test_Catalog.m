%% test_Catalog.m
% Run with:
%   runtests('tests')
%
% This test executes Catalog.cookbook and verifies that it completes
% without crashing. Because the cookbook depends on:
%   • External TESTDATA
%   • Optional Antelope toolbox
%   • Optional Mapping Toolbox
%
% this test:
%   - NEVER fails due to missing external services or toolboxes
%   - ONLY fails if the code itself throws an unhandled error
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

    % Ensure TESTDATA is configured (non-fatal if user cancels)
    try
        admin.is_testdata_setup(true);
    catch ME
        warning('TESTDATA setup skipped: %s', ME.message);
    end
end


function teardown(testCase)
    close all
    cd(testCase.TestData.originalDir);
end


%% ------------------------------------------------------------------------
function test_runCatalogCookbook(testCase)
% Verifies that Catalog.cookbook executes without an unhandled fatal error.
% Warnings are allowed and expected.

    try
        Catalog.cookbook;
        disp('Catalog.cookbook executed without fatal errors.');
    catch ME
        % Hard failure only on unhandled exceptions
        warning('Catalog.cookbook threw an exception:\n%s', ME.message);
        testCase.verifyFail(sprintf( ...
            'Catalog.cookbook crashed: %s', ME.message));
    end
end


%% ------------------------------------------------------------------------
function setupOnce(testCase) %#ok<INUSD>
    close all
end


function teardownOnce(testCase) %#ok<INUSD>
    close all
end
