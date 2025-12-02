function W = load_cookbook_data
%LOAD_COOKBOOK_DATA Load sample data used in MASTERCORR.COOKBOOK
%
% This version loads the canonical TESTDATA dataset:
%   TESTDATA/matfiles/mastercorr.mat
%
% Required variable inside file: W (waveform object)

% Locate GISMO root
gismopath = fileparts(which('startup_GISMO'));
TESTDATA  = fullfile(gismopath, 'testdata');

if ~exist(TESTDATA, 'dir')
    error('mastercorr:NoTESTDATA', ...
        'GISMO TESTDATA directory not found.');
end

matfile = fullfile(TESTDATA, 'matfiles', 'mastercorr.mat');

if ~exist(matfile, 'file')
    error('mastercorr:MissingDataFile', ...
        'Required file not found: %s', matfile);
end

S = load(matfile);

% Robust variable extraction
if isfield(S,'W')
    W = S.W;
elseif isfield(S,'w')
    W = S.w;
else
    error('mastercorr:InvalidDataFile', ...
        'mastercorr.mat must contain a variable named W.');
end

% Final sanity check
if ~isa(W,'waveform')
    error('mastercorr:InvalidDataType', ...
        'Loaded variable W is not a waveform object.');
end

end
