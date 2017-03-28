function result = is_testdata_setup()
% check the TESTDATA variable points to the testdata directory
    global TESTDATA
    result  = false;
    if exist('TESTDATA','var')
        [dirname, dfile] = fileparts(TESTDATA);
        if strcmp(dfile, 'testdata')
            result = true;
        end
    end
end