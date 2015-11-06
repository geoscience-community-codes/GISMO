function dbcreate(filepath,schema)
%DBCREATE Create an Antelope database descriptor file
% DBCREATE(FILEPATH) create a database descriptor file at path given 
% by FILEPATH, with the default SCHEMA CSS3.0.
%
% DBCREATE(FILEPATH, SCHEMA) use a different schema.

if ~exist('schema','var')
    schema='css3.0';
end
fid = fopen(filepath, 'w');
fprintf(fid,'#\n');
fprintf(fid,'schema %s\n',schema);
fclose(fid);
end
