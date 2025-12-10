function G = guard(testCase, capability)
%TESTS.GUARD  Centralized capability guard for GISMO tests
%
%   G = guard(testCase, CAPABILITY)
%
% CAPABILITY options:
%   'basic'      - always passes (default)
%   'signal'     - requires Signal Processing Toolbox
%   'stats'      - requires Statistics Toolbox
%   'mapping'    - requires Mapping Toolbox
%   'iris'       - requires irisFetch + Java + internet + MATLAB <= 2022
%   'antelope'   - requires Antelope MATLAB toolbox
%
% The test is skipped (assumeTrue) if the capability is unavailable.

if nargin < 2 || isempty(capability)
    capability = 'basic';
end

% ---------------------------------------------------------------------
% Detect environment (single authoritative source)
G = admin.gismo_guard();

% ---------------------------------------------------------------------
switch lower(capability)

    case 'basic'
        return

    case 'signal'
        testCase.assumeTrue( ...
            G.Toolboxes.SignalProcessing, ...
            'Skipping: Signal Processing Toolbox not available.');

    case 'stats'
        testCase.assumeTrue( ...
            G.Toolboxes.Statistics, ...
            'Skipping: Statistics Toolbox not available.');

    case 'mapping'
        testCase.assumeTrue( ...
            G.Toolboxes.Mapping, ...
            'Skipping: Mapping Toolbox not available.');

    case 'iris'
        testCase.assumeTrue( ...
            G.MATLAB.Year <= 2022, ...
            'Skipping: irisFetch unsupported on MATLAB R2023a+.');
        testCase.assumeTrue( ...
            G.IRIS.irisFetchAvailable, ...
            'Skipping: irisFetch.m not on MATLAB path.');
        testCase.assumeTrue( ...
            G.IRIS.javaAvailable, ...
            'Skipping: IRIS Java classes not available.');
        testCase.assumeTrue( ...
            G.Internet, ...
            'Skipping: no internet connection.');

    case 'antelope'
        testCase.assumeTrue( ...
            G.Antelope.exists, ...
            'Skipping: Antelope MATLAB toolbox not installed.');

    otherwise
        error('tests.guard:UnknownCapability', ...
            'Unknown guard capability: %s', capability);
end
end