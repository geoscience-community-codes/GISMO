function [w_replaced] = station_replace(W, STA, CHAN)
%STATION_REPLACE reads each waveform in a waveform object and replaces the
%station and channel tags. 
%       Input Arguments:
%           W: waveform object or cell array
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


    switch class(W)
        case 'waveform'
            
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
        case 'cell'
            for i = 1:numel(W)
                s = W{i}(end-11:end-8);
                c = W{i}(end-6:end-4);
                tmp = strrep(W{i},s,STA);
                w_replaced{i,1} = strrep(tmp,c,CHAN);
                clear tmp
            end
        otherwise
            error('%s is not a valid option, use waveform_object or cellarray',TYPE)
    end
end
