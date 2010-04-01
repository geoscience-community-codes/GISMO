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
% $Date: 2010-03-12 17:48:49 -0900 (Fri, 12 Mar 2010) $
% $Revision: 227 $

if nargin == 1
    % automatically determine the legend
    total_waves = numel(wave);
    scnls = get(wave,'scnlobject');
    nscnls = numel(unique(scnls));
    if nscnls == 1
        % all scnls represent the same station
        items = get(wave,'start_str');
    else
        uniquestations = unique(get(scnls,'station'));
        stationsareunique = numel(uniquestations) == total_waves;
        issinglestation = isscalar(uniquestations);
        
        uniquechannels = unique(get(scnls,'channel'));        
        channelsareunique = numel(uniquechannels) == total_waves;
        issinglechannel = isscalar(uniquechannels);    
    
    if stationsareunique
        if issinglechannel
            items = get(scnls,'station');
        else
            items = strcat(get(scnls,'station'),':',get(scnls,'channel'));
        end
    elseif issinglestation
        if issinglechannel
            items = get(wave,'start_str');
        elseif channelsareunique
            items = get(scnls,'channel');
        else
            % 1 station, mixed channels
            items = strcat(get(scnls,'channel'),': ',get(wave,'start_str'));
        end
    else %mixed stations
        if issinglechannel
            items = strcat(get(scnls,'station'),': ',get(wave,'start_str'));
        else
            items = strcat(get(scnls,'station'),':',get(scnls,'channel'));
        end        
    end
                
    end
    
            
    
else
    %let the provided fieldnames determine the legend.
    items = get(wave,varargin{1});
    items = anything2textCell(items);
%         if isnumeric(items)
%             items=num2str(items);
%         elseif iscell(items)
%             if isnumeric(items{1})
%                 for n=1 1:numel(items)
%                     items(n) = {num2str(items{n})};
%                 end
%             end
%         end
    for n=2:nargin-1
        nextitems = get(wave,varargin{n});
        items = strcat(items,':',anything2textCell(nextitems));
    end
end

h = legend(items);
if nargout == 1
    varargout = {h};
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
