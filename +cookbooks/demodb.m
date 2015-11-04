function dbpath = demodb(name)
%DEMODB
% dbpath = demodb('avo')
% dbpath = demodb('rt')
if strcmp(lower(name),'antelope')
    dbpath = '/opt/antelope/data/db/demo/demo';
else
    dirname = get_test_data_path();
    dbpath = fullfile(dirname,'css3.0', sprintf('%sdb200903',name));
end
