function result = is_testdata_setup(autoDownload)
%ADMIN.IS_TESTDATA_SETUP  Verify that TESTDATA is correctly configured.
%
% result = is_testdata_setup()
% result = is_testdata_setup(true)
%
% Returns true if:
%   • global TESTDATA exists
%   • points to a readable folder
%   • contains expected GISMO testdata subfolders
%
% If autoDownload == true and TESTDATA is missing or invalid,
% admin.download_testdata will be called automatically.
%
% Glenn Thompson (refactored 2025)

if nargin < 1
    autoDownload = false;
end

result = false;

% ------------------------------------------------------------
% Access global
% ------------------------------------------------------------
global TESTDATA

if isempty(TESTDATA) || (~ischar(TESTDATA) && ~isstring(TESTDATA))
    if autoDownload
        try
            admin.download_testdata
        catch
            return
        end
    else
        return
    end
end

TESTDATA = char(TESTDATA);

% ------------------------------------------------------------
% Must exist on disk
% ------------------------------------------------------------
if ~isfolder(TESTDATA)
    if autoDownload
        try
            admin.download_testdata
        catch
            return
        end
    else
        return
    end
end

% ------------------------------------------------------------
% Verify required subfolders (not folder name)
% ------------------------------------------------------------
required = {'miniseed','sac','seisan'};
missing = false;

for k = 1:numel(required)
    if ~isfolder(fullfile(TESTDATA, required{k}))
        warning('TESTDATA missing subfolder: %s', required{k});
        missing = true;
    end
end

if missing && autoDownload
    try
        admin.download_testdata
    catch
        return
    end
end

% ------------------------------------------------------------
% Final validation after auto-repair
% ------------------------------------------------------------
if ~isfolder(TESTDATA)
    return
end

for k = 1:numel(required)
    if ~isfolder(fullfile(TESTDATA, required{k}))
        return
    end
end

result = true;

end
