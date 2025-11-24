%% Catalog_test.m
% Run with:
%   runtests('Catalog_test')
%
% This test safely executes Catalog.cookbook and verifies that it completes
% without crashing. Because Catalog.cookbook contains many examples that
% depend on external services (IRIS DMC), optional toolboxes, and optional
% demo datasets, we do not require numerical correctness here—only that
% the function executes without fatal errors.

function tests = Catalog_test()
    tests = functiontests(localfunctions);
end

%% ------------------------------------------------------------------------
function setup(testCase)     % Runs before *each* test
    close all
    testCase.TestData.originalDir = pwd;
    % Ensure GISMO is on the path
    gismopath = fileparts(which('startup_GISMO'));
    if ~isempty(gismopath)
        addpath(genpath(gismopath));
    end
end

function teardown(testCase)  % Runs after *each* test
    close all
    cd(testCase.TestData.originalDir);
end

%% ------------------------------------------------------------------------
function test_runCatalogCookbook(testCase)
% This test checks that Catalog.cookbook executes without throwing
% an *unhandled* error. Any issues such as missing toolboxes,
% missing networks, or missing data should trigger warnings—not crashes.

    try
        Catalog.cookbook;
        % If we get here, we consider the test a PASS.
        disp('Catalog.cookbook executed without fatal errors.');
    catch ME
        % Allow test to pass but record the failure as a diagnostic.
        % This avoids CI failures due to unavailable web services.
        warning('Catalog.cookbook raised an exception:\n%s', ME.message);
        testCase.verifyFail(sprintf( ...
            'Catalog.cookbook crashed: %s', ME.message));
    end
end

%% ------------------------------------------------------------------------
function setupOnce(testCase)
    % (Optional) Runs once before all tests
    close all
end

function teardownOnce(testCase)
    % (Optional) Runs once after all tests
    close all
end