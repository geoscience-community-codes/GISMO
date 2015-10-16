function dbcreate(filepath,schema)
if ~exist('schema','var')
    schema='css3.0';
end
fid = fopen(filepath, 'w');
fprintf(fid,'#\n');
fprintf(fid,'schema %s\n',schema);
fclose(fid);
end