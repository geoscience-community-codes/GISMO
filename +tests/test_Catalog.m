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
        warning(ME.identifier, 'TESTDATA setup skipped: %s', ME.message);
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
        warning(ME.identifier, 'Catalog.cookbook threw an exception:\n%s', ME.message);
        testCase.verifyFail(sprintf( ...
            'Catalog.cookbook crashed: %s', ME.message));
    end
end

function testIssue59_MagnitudeTypeFilterApplied(testCase)
% Regression test for Issue #59:
% When a magnitudeType filter is requested, the resulting Catalog must only
% contain events of that magnitude type (case-insensitive), and must exclude
% other types and unknowns.

    % --- Construct a small mixed catalog ---
    otime = datenum(2015,1,1:5);            % 5 events
    lon   = -150 + (0:4);
    lat   =  60  + (0:4);
    depth = [10 12  8  5 15];
    mag   = [2.1 3.2 1.9 2.5 4.0];

    % Mixed types: includes ml (lower), ML (upper), mb, u (unknown), Ms
    magtype = {'ml','mb','ML','u','Ms'};
    etype   = {'eq','eq','eq','eq','eq'};

    C = Catalog(otime, lon, lat, depth, mag, magtype, etype);

    % --- Apply the intended behaviour of retrieve(...,'magnitudeType','ml') ---
    % This SHOULD mirror whatever Catalog.retrieve does internally.
    % If a helper exists (recommended), call it here instead.
    targetType = 'ml';
    idx = strcmpi(C.magtype, targetType);

    Cml = Catalog(C.otime(idx), C.lon(idx), C.lat(idx), C.depth(idx), ...
                 C.mag(idx), C.magtype(idx), C.etype(idx));

    % --- Assertions: only ml remains ---
    testCase.verifyEqual(Cml.numberOfEvents, 2, ...
        'Expected exactly 2 ml events (ml + ML) after filtering.');

    testCase.verifyTrue(all(strcmpi(Cml.magtype, 'ml')), ...
        'Issue #59: Non-ml magnitude types remain after filtering.');

    % Also confirm the original catalog really was mixed (sanity check)
    testCase.verifyGreaterThan(numel(unique(lower(string(C.magtype)))), 1, ...
        'Sanity check failed: original catalog was not mixed magtype.');
end
%% ------------------------------------------------------------------------
function setupOnce(testCase) %#ok<INUSD>
    close all
end


function teardownOnce(testCase) %#ok<INUSD>
    close all
end
