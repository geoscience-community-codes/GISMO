function dbpath = demodb(name)
%DEMODB
% dbpath = demodb('avo')
% dbpath = demodb('rt')
if strcmp(lower(name),'antelope')
    dbpath = '/opt/antelope/data/db/demo/demo';
else
    dirname = fileparts(which('Catalog')); 
    dbpath = fullfile(dirname,'demo','antelope', sprintf('%sdb200903',name));
end
