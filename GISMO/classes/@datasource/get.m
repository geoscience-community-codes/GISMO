function val = get(ds, propertyname)
switch lower (propertyname)
  case 'server'
    val=  ds.server_name;
  case 'port'
    val = ds.port_number;
  case 'type'
    val = ds.type;
  case 'interpreter'
    val = ds.interpreter;
  otherwise
    warning('Datasource:unknownProperty','%s is not a known property name', propertyname);
    val = [];
end