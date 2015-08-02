function b = loadobj(a)
%LOADOBJ used when loading datasources, and accounts for version changes
% to datasource

if isa(a,'datasource')
  b = a;
else %a is an old version
  switch a.type
    case {'winston'}
      b = datasource(a.type,a.server_name,a.port_number);
    otherwise
  b = datasource(a.type,a.file_string,a.file_args{:});
  end
end