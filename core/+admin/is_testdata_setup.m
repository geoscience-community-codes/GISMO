function result = is_testdata_setup()
%ADMIN.IS_TESTDATA_SETUP  Verify that TESTDATA is correctly configured.
%
% Returns true if:
%   • global TESTDATA exists
%   • points to a folder
%   • folder name ends with 'testdata'
%   • folder is readable on disk

    result = false;

    % Access global
    global TESTDATA

    if isempty(TESTDATA)
        return
    end

    if ~ischar(TESTDATA) && ~isstring(TESTDATA)
        return
    end

    TESTDATA = char(TESTDATA);

    % Must exist on disk
    if ~isfolder(TESTDATA)
        return
    end

    % Must end in ".../testdata"
    [~, folderName] = fileparts(TESTDATA);
    if ~strcmpi(folderName, 'testdata')
        return
    end

    % Optional: check for expected subfolders
    required = {'miniseed','sac','seisan'};
    for k = 1:numel(required)
        if ~isfolder(fullfile(TESTDATA, required{k}))
            warning('TESTDATA is missing subfolder: %s', required{k});
        end
    end

    result = true;
end