function obj = as_channeltag(obj)
   switch(class(obj))
      case 'ChannelTag' %good. do nothing.
      case 'scnlobject'
         obj = get(obj, 'channeltag');
      otherwise
         obj = ChannelTag(obj); %attempt natural conversion
         % should be able to handle 'N.S.L.C'
   end
end