function varargout = legend(wave, varargin)
   %legend creates a legend for a waveform graph
   %  legend(wave) attempts to automatically create a legend based upon
   %  unique values within the waveforms.  in order, the legend will
   %  preferentially use station, channel, start time.
   %
   %  legend(wave, field1, [field2, [..., fieldn]]) will create a legend,
   %  using the fieldnames.
   %
   %  h = legend(...) returns the handle for the created legend.  this handle
   %  can be used to later modify the legend entry (such as setting the
   %  location, etc.)
   %
   %  Note: for additional control, use matlab's legend function by passing it
   %  cells & strings instead of a waveform.
   %    (hint:useful functions include waveform/get, strcat, sprintf, num2str)
   %
   %  see also legend
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   if nargin == 1
      % automatically determine the legend
      total_waves = numel(wave);
      cha_tags = get(wave,'channeltag');
      ncha_tags = numel(unique(cha_tags));
      if ncha_tags == 1
         % all cha_tags represent the same station
         items = get(wave,'start_str');
      else
         uniquestations = unique(get(cha_tags,'station'));
         stationsareunique = numel(uniquestations) == total_waves;
         issinglestation = isscalar(uniquestations);
         
         uniquechannels = unique(get(cha_tags,'channel'));
         channelsareunique = numel(uniquechannels) == total_waves;
         issinglechannel = isscalar(uniquechannels);
         
         if stationsareunique
            if issinglechannel
               items = get(cha_tags,'station');
            else
               items = strcat(get(cha_tags,'station'),':',get(cha_tags,'channel'));
            end
         elseif issinglestation
            if issinglechannel
               items = get(wave,'start_str');
            elseif channelsareunique
               items = get(cha_tags,'channel');
            else
               % 1 station, mixed channels
               items = strcat(get(cha_tags,'channel'),': ',get(wave,'start_str'));
            end
         else %mixed stations
            if issinglechannel
               items = strcat(get(cha_tags,'station'),': ',get(wave,'start_str'));
            else
               items = strcat(get(cha_tags,'station'),':',get(cha_tags,'channel'));
            end
         end
         
      end
      
      
      
   else
      %let the provided fieldnames determine the legend.
      items = get(wave,varargin{1});
      items = anything2textCell(items);
      
      for n=2:nargin-1
         nextitems = get(wave,varargin{n});
         items = strcat(items,':',anything2textCell(nextitems));
      end
   end
   
   h = legend(items);
   if nargout == 1
      varargout = {h};
   end
end
function stuff = anything2textCell(stuff)
   
   if isnumeric(stuff)
      stuff=num2str(stuff);
   elseif iscell(stuff)
      if isnumeric(stuff{1})
         for n=1 : numel(stuff)
            stuff(n) = {num2str(stuff{n})};
         end
      end
   end
end