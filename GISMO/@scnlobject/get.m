function stuff = get(scnl, prop_name)
   %GET for the scnl object
   %  result = get(scnlobject, property), where PROPERTY is one of the
   %  following:
   %    'network', 'station', 'locatin', 'channel'
   %
   % If the results of a single SCNL are requested, then a string is returned.
   % Otherwise, a cell of values will be returned.
   
   lower_prop_name = lower(prop_name);
   if ~strcmp(lower_prop_name,prop_name)
      warning('SCNLOBJECT:get:propertyWarning',...
              'Use lowercase ''%s'' property name for consistency',lower(prop_name));
      prop_name = lower_prop_name;
   end
   
   switch prop_name
      
      case{'station','channel','network','location'}
         thesetags = [scnl.tag];
         stuff = {thesetags.(prop_name)};
      case{'nscl_string'}
         for n = numel(scnl): -1 : 1
            thistag = scnl(n).tag;
            stuff(n) = {[ thistag.network, '_', thistag.station, '_',...
               thistag.channel, '_', thistag.location ]};
         end
      case {'channeltag'}
         stuff = [scnl.tag];
      otherwise
         error('SCNLOBJECT:get:UnrecognizedProperty',...
            'Unrecognized property name : %s',  prop_name);
   end
   
   %if a single scnl, then return the string representation, else return a
   %cell of strings.
   if numel(stuff) == 1
      stuff = stuff{1};
   else
      stuff = reshape(stuff,size(scnl));
   end;
end
