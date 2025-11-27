function varargout = legend(T, varargin)
   %legend   Create a legend for the graph of a trace.
   %  legend(traces) attempts to automatically create a legend based upon
   %  unique values within the traces.  in order, the legend will
   %  preferentially use station, channel, start time.
   %
   %  legend(traces, field1, [field2, [..., fieldn]]) will create a legend,
   %  using the fieldnames.
   %
   %  h = legend(...) returns the handle for the created legend.  this handle
   %  can be used to later modify the legend entry (such as setting the
   %  location, etc.)
   %
   %  For additional control, use matlab's legend function by passing it
   %  cells & strings instead of a trace.
   %    (hint:useful functions include  strcat, sprintf, num2str)
   %
   %  See also plot, legend
   
   if nargin == 1
      % automatically determine the legend
      total_waves = numel(T);
      cha_tags = [T.channelinfo];
      ncha_tags = numel(unique(cha_tags));
      if ncha_tags == 1
         % all cha_tags represent the same station
         items = T.start;
      else
         uniquestations = unique({cha_tags.station});
         stationsareunique = numel(uniquestations) == total_waves;
         issinglestation = isscalar(uniquestations);
         
         uniquechannels = unique({cha_tags.channel});
         channelsareunique = numel(uniquechannels) == total_waves;
         issinglechannel = isscalar(uniquechannels);
         
         if stationsareunique
            if issinglechannel
               items = {cha_tags.station};
            else
               items = strcat({cha_tags.station},':',{cha_tags.channel});
            end
         elseif issinglestation
            if issinglechannel
               items = T.start;
            elseif channelsareunique
               items = {cha_tags.channel};
            else
               % 1 station, mixed channels
               items = strcat({cha_tags.channel},': ',T.start);
            end
         else %mixed stations
            if issinglechannel
               items = strcat({cha_tags.station},': ',T.start);
            else
               items = strcat({cha_tags.station},':', {cha_tags.channel});
            end
         end
      end
      
   else
      %let the provided fieldnames determine the legend.
      items = T.(varargin{1});
      items = anything2textCell(items);
      
      for n = 2:nargin-1
         nextitems = T.(varargin{n});
         items = strcat(items,':',anything2textCell(nextitems));
      end
   end
   
   h = legend(items);
   if nargout == 1
      varargout = {h};
   end
   
   function stuff = anything2textCell(stuff)
      %convert anything to a text cell
      if isnumeric(stuff)
         stuff=num2str(stuff);
      elseif iscell(stuff)
         if isnumeric(stuff{1})
            for m=1 : numel(stuff)
               stuff(m) = {num2str(stuff{m})};
            end
         end
      end
   end
end
