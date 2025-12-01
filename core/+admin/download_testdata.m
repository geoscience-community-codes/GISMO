function download_testdata()
%DOWNLOAD_TESTDATA Download and initialize GISMO test data directory
%
% This function:
%   • Uses global TESTDATA if already defined
%   • Otherwise defaults to <GISMO root>/testdata
%   • Allows user to override via folder selection GUI
%   • Downloads and unzips testdata.zip if directory is empty
%   • Sets global TESTDATA for future sessions
%
% Intended location:
%   GISMO/core/+admin/download_testdata.m
%
% Glenn Thompson / Refactored 2025

% ------------------------------------------------------------
global TESTDATA

TESTDATA_URL = ...
    'http://geoscience-community-codes.github.io/GISMO/testdata/testdata.zip';

fprintf('\n--- GISMO Test Data Setup ---\n');

% ------------------------------------------------------------
% 1) Determine default testdata directory
% ------------------------------------------------------------

if ~isempty(TESTDATA) && isfolder(TESTDATA)
    testdata_dir = TESTDATA;
    fprintf('Using existing global TESTDATA:\n  %s\n', testdata_dir);
else
    % Derive GISMO root from this file location
    thisfile = mfilename('fullpath');
    gismo_core = fileparts(fileparts(thisfile));   % .../core/+admin -> core
    gismo_root = fileparts(gismo_core);             % core -> GISMO root

    testdata_dir = fullfile(gismo_root, 'testdata');

    fprintf('Default testdata directory:\n  %s\n', testdata_dir);

    % Ask user if they want to change it
    choice = questdlg( ...
        sprintf('Use this directory for GISMO test data?\n\n%s', testdata_dir), ...
        'GISMO Test Data Location', ...
        'Use Default', 'Choose Different Location', 'Use Default');

    if strcmp(choice, 'Choose Different Location')
        testdata_dir = uigetdir(pwd, 'Select GISMO test data directory');
        if isequal(testdata_dir, 0)
            error('TESTDATA directory selection cancelled by user.');
        end
    end
end

% Ensure directory exists
if ~exist(testdata_dir, 'dir')
    mkdir(testdata_dir);
end

% ------------------------------------------------------------
% 2) Check if directory is empty
% ------------------------------------------------------------

contents = dir(testdata_dir);
contents = contents(~ismember({contents.name}, {'.','..'}));

if ~isempty(contents)
    fprintf('Test data already exists in:\n  %s\n', testdata_dir);
    TESTDATA = testdata_dir;
    return
end

% ------------------------------------------------------------
% 3) Download test data
% ------------------------------------------------------------

fprintf('Downloading GISMO test data...\n');
zipfile = fullfile(testdata_dir, 'testdata.zip');

try
    websave(zipfile, TESTDATA_URL);
catch ME
    error('Failed to download test data:\n%s', ME.message);
end

% ------------------------------------------------------------
% 4) Unzip
% ------------------------------------------------------------

fprintf('Unzipping test data...\n');

try
    unzip(zipfile, testdata_dir);
    delete(zipfile);
catch ME
    error('Failed to unzip test data:\n%s', ME.message);
end

% ------------------------------------------------------------
% 5) Set global TESTDATA
% ------------------------------------------------------------

TESTDATA = testdata_dir;

fprintf('GISMO test data installed successfully at:\n  %s\n', TESTDATA);
fprintf('Global TESTDATA variable initialized.\n');

end
