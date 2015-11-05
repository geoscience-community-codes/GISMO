function ddir = demo_path()
%DEMO_PATH Return path to demo directory
    dirname = fileparts(which('startup_GISMO'));
    ddir = fullfile(dirname,'classes','+Catalog','+demo');
end
