function obj = as_channeltag(obj)
   switch(class(obj))
      case 'channeltag' %good. do nothing.
      case 'scnlobject'
         obj = get(obj, 'channeltag');
      otherwise
         obj = channeltag(obj); %attempt natural conversion
         % should be able to handle 'N.S.L.C'
   end
end