function [w_replaced] = station_replace(W, STA, CHAN)
%STATION_REPLACE reads each waveform in a waveform object and replaces the
%station and channel tags. 
%       Input Arguments:
%           W: waveform object
%           STA: station name string (will replace whatever station is
%           currently loaded)
%           CHAN: channel name string (will replace whatever channel is
%           currently loaded)
%       Output/Example:
%           w_replaced: cell array of the file paths to the replaced
%           waveforms.
%               w = load_waveforms('/path/to/file.dat',1);
%               w_replaced = station_replace(w,'TBMR','BHN');
%           This will return the cell array "w_replaced" which can be used
%           with load_waveforms to load in the replaced waveforms.
%               w = load_waveforms(w_replaced,0);

    % read the station and channel information from the waveform object
    % they should all be the same so just read the first one outside the
    % loop
    station = get(W(1),'ChannelTag');
    channel = station.channel; % channel string
    station = station.station; % station string
    
    % initialize the cell array for storing the file paths to new waveforms
    w_replaced = cell(numel(W),1);
    
    for i=1:numel(W)
       % loop for reading the filepath to each waveform in w
       history = get(W(i),'history'); % get info on the waveform
       filepath = strrep(history{2,1},'Loaded SAC file: ',''); % filepath string
       filepath = strrep(filepath,station,STA); % replace station
       filepath = strrep(filepath,channel,CHAN); % replace channel
       w_replaced{i,1} = filepath;
    end
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%% OLD STATION REPLACE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     if TYPE == 0 % waveform object 
%         h = get(SUBSET, 'history');
%         q = numel(h)
%         if q == 4
%             error('Check to see how many waveforms are in the object')
%         else
%             new_subset = cell(q,1);
%             count = 1;
%             for count = 1:numel(h)
%                 hh = h{count,1}{2,1};
%                 hh_rep = strrep(hh,'Loaded SAC file: ', '');
%                 filepath = strrep(hh_rep, STRING, REPLACEMENT);
%                 new_subset{count} = filepath;
%                 count = count + 1;
%             end
%         end
%     elseif TYPE == 1 % cell array 
%         new_subset = cell(1,1);
%         count = 1;
%         count2 = 1;
%         for count = 1:numel(SUBSET)
%             sub = strrep(SUBSET{count}, STRING, REPLACEMENT);
%             if exist(sub, 'file')
%                 new_subset{count2, 1} = sub;
%                 count2 = count2 + 1;
%             else
%                 continue
%             end
%             count = count + 1;
%         end
%     else
%         warning('something''s up')
%     end
end
