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
       case {'location','dbpath'} % GT added this 20160512
           switch ds.type
               case {'winston'}
                   val = [ds.server_name,':',ds.port_number]
                    case {'file','sac','antelope','seisan','obspy'}
                        val = getfilename(ds,[],[]);
%                         for n=1:numel(filelist)
%                             disp(sprintf('  location: %s',filelist{n}));
%                         end

           end
       otherwise
          
         warning('Datasource:unknownProperty','%s is not a known property name', propertyname);
         val = [];
         ds.location
   end
end