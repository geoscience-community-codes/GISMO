function startup_GISMO(gismopath)
% STARTUP_GISMO  Initialize GISMO environment safely and reproducibly.
%
% Adds core, contributed, applications, libraries, tests, training,
% and Java dependencies to the MATLAB path.
%
% Package directories (+pkg) are handled correctly by adding ONLY their
% parent folders, per MATLAB package rules.
%
% Author: Michael West (original), Glenn Thompson (2012+)
% Rewrite & modernization: Glenn Thompson (2025)

%% ------------------------------------------------------------------------
% Resolve GISMO root path
if ~exist('gismopath', 'var') || isempty(gismopath)
    gismofile = which('startup_GISMO');
    if isempty(gismofile)
        error('startup_GISMO.m not found on MATLAB path.');
    end
    gismopath = fileparts(gismofile);
end

fprintf('\n--- Initializing GISMO from: %s ---\n', gismopath);

%% ------------------------------------------------------------------------
% Add CORE
addDir(fullfile(gismopath, 'core'));

%% ------------------------------------------------------------------------
% Add CONTRIBUTED (package-safe)
addContributedSafe(gismopath, 'contributed');

%% ------------------------------------------------------------------------
% Add CONTRIBUTED_ANTELOPE (only if Antelope present)
if exist('dbopen','file') == 2 && exist('trload_css','file') == 2
    addContributedSafe(gismopath, 'contributed_antelope');
else
    disp('Antelope not detected — skipping contributed_antelope');
end

%% ------------------------------------------------------------------------
% Add UAF_INTERNAL
addContributedSafe(gismopath, 'uaf_internal');

%% ------------------------------------------------------------------------
% Add APPLICATIONS (recursive)
addDir(genpath(fullfile(gismopath,'applications')));

%% ------------------------------------------------------------------------
% Add GISMO LIBRARY
addDir(fullfile(gismopath, 'libgismo'));

%% ------------------------------------------------------------------------
% Add TESTS
addDir(fullfile(gismopath, 'tests'));

%% ------------------------------------------------------------------------
% Add TRAINING
addDir(fullfile(gismopath, 'training'));

%% ------------------------------------------------------------------------
% Add JAVA JAR Dependencies
jarDir = fullfile(gismopath, 'contributed', 'jar_files');
jarFiles = {
    'swarm.jar'
    'wwsclient-1.3.7.jar'
    'pensive-1.7.1.jar'
    'IRIS-WS-2.20.1.jar'
};

for i = 1:numel(jarFiles)
    jf = fullfile(jarDir, jarFiles{i});
    if exist(jf,'file')
        try
            javaaddpath(jf);
            disp(['Java added: ' jf]);
        catch ME
            warning('Failed to add Java path: %s\n%s', jf, ME.message);
        end
    else
        warning('Missing JAR: %s', jf);
    end
end

%% ------------------------------------------------------------------------
% Final Diagnostics
fprintf('--- GISMO startup complete ---\n\n');

end

%% ========================================================================
%% Helper Functions
%% ========================================================================

function addContributedSafe(gismopath, contribDir)
% Add only valid non-package subdirectories AND the parent directory itself.
% MATLAB automatically resolves +package folders from the parent.

root = fullfile(gismopath, contribDir);

if ~exist(root,'dir')
    warning('Missing directory: %s', root);
    return
end

% Always add the parent directory (critical for +packages)
addDir(root);

dirlist = dir(root);
dirlist = removeHiddenFiles(dirlist);

for n = 1:numel(dirlist)
    subdir = dirlist(n).name;
    newpath = fullfile(root, subdir);

    if ~isfolder(newpath)
        continue
    end

    % Do NOT add inside +package directories
    if subdir(1) == '+'
        fprintf('Package detected: %s (parent already on path)\n', subdir);
        continue
    end

    addDir(newpath);
end
end

%% ------------------------------------------------------------------------

function addDir(p)
if isempty(p) || ~ischar(p)
    return
end
if exist(p,'dir')
    addpath(p);
    disp(['Adding path: ' p]);
end
end

%% ------------------------------------------------------------------------

function directoryList = removeHiddenFiles(directoryList)
startsWithPeriod = strncmp('.', {directoryList.name}, 1);
directoryList = directoryList(~startsWithPeriod);
end
