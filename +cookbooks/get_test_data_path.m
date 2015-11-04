function ddir = test_data_path(name)
%test_data_path Return path to test_data directory
if strcmp(lower(name),'antelope')
    ddir = '/opt/antelope/data/db/demo';
else
    dirname = fileparts(which('startup_GISMO'));
    ddir = fullfile(dirname,'+test','test_data');
end
