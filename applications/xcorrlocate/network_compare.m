function [all_sta] = network_compare(network)
%SUBSET_COMPARE takes the structured array from the station_subsets()
%function and finds which waveforms appear on all stations/channels.
%       Input Argument(s):
%           network: struct output from station_subsets
%       Output:
%           all_sta: struct array containing the subset of waveforms that
%           appears on all stations with their respective station and
%           channel tag info in the file name for easy loading.


    % get station and channel fieldnames from the structured array
    stations = fieldnames(network);
    channels = fieldnames(network.(stations{1}));
    
    % initialize a minimum value from the structured array
    min = numel(network.(stations{1}).(channels{1}));
    
    % find the station/channel with the least amount of waveforms. That
    % station will be the cap for the comparison
    for i = 1:numel(stations) % loop over stations
        
        for j = 1:numel(channels) % loop over channels
            
            len = numel(network.(stations{i}).(channels{j}));
            
            if len < min
                min = len;
                min_station = i;
                min_channel = j;
            else
                continue
            end
        end
    end
    
    % station with minimum number of waveforms. Use in comparison
    minsta = network.(stations{min_station}).(channels{min_channel});
    
    % remove the station and channel info for comparison across stations
    for i = 1:numel(minsta)
        minsta{i} = minsta{i}(1:end-13);
    end
    
    % compare the waveforms across all stations and channels
    for i = 1:numel(stations) % loop over stations
        
        for j = 1:numel(channels) % loop over channels
            
            if (i ~= min_station && j ~= min_channel)
                % if the channel isn't the one with minimum number of
                % waveforms
                
                % make the jth component on the ith station into a list
                w = network.(stations{i}).(channels{j});
                
                % remove the station and channel tag for comparison
                for k = 1:numel(w)
                    w{k} = w{k}(1:end-13);
                end
                
                
                c = 1;
                for k = 1:numel(minsta)
                    if any(strcmp(w,minsta{k}))
                        tmp{c,1} = minsta{k};
                        c = c + 1;
                    else
                        continue
                    end
                end
                
                % replace minsta with the waveforms that appear on both
                % stations. clear don't just overwrite because lengths
                % don't necessarily have to be the same
                
                clear minsta
                minsta = tmp;
                clear tmp
                
            end % if-else end
        end % channel for loop end
    end % station for loop end
    
    % rebuild the network struct to easily load the waveforms from each
    % station/channel
    
    for i = 1:numel(stations)
        
        for j = 1:numel(channels)
            
            % struct array with the final subset of ubiquitos waveforms
            all_sta.(stations{i}).(channels{j}) = strcat(minsta,'-',stations{i},'-',channels{j},'.sac');
            
        end
    end
    
    
end