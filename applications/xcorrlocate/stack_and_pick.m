function [muck] = stack_and_pick(network)
%STACK_AND_PICK takes the output waveforms from network_subset and stacks
%them and allows for a pick to be made on the stack which is applied to
%each of the waveforms.
%       Input Arguments:
%           network: struct array - output from network_subset
%       Output:
%           muck: TBD, possibly a struct of waveform objects with the times
%           as one of array dimensions

    % get the station and channel info from the network struct
    sta = fieldnames(network);
    chan = fieldnames(network.(sta{1}));
    
    for i = 1:numel(sta)
        for j = 1:numel(chan)
            
            w = load_waveforms(network.(sta{i}).(chan{j})(:,1),'cellarray');
            w = clip_waveforms(w);
            c = correlation(w,get(w,'start'));
            c = stack(c); % don't need to align with adjusttrig because of clip_waveforms
            w = waveform(c);
            
            disp('Can only zoom on waveform once so include P and S in zoom')
            plot(w(end));
            
            % switch-case for the P-Arrival pick
            reply = input('Is there a P-Arrival?(y/n): ','s');
            
            switch reply
                case 'y'
                    
                    % allow to zoom on the waveform
                    waitforbuttonpress;
                    waitforbuttonpress;
                    
                    disp('Waiting for a P-arrival pick...')
                    p_pick = ginput(1);
                    p_pick = p_pick(1); % don't care about y-value
                    
                case 'n'
                    disp('Exiting pick')
                otherwise
                    disp('Must use a lowercase y or n')
            end
            
            % switch-case for the S-Arrival pick
            reply = input('Is there an S-Arival?(y/n): ','s');
            
            switch reply
                case 'y'
                    
                    disp('Waiting for an S-Arrival pick...')
                    s_pick = ginput(1);
                    s_pick = s_pick(1); % don't care about y-value
                    
                case 'n'
                    disp('Exiting pick')
                otherwise
                    disp('Must use a lowercase y or n')
            
            end
            
            % pick time is start time + the pick time since the waveforms
            % are clipped, don't need to worry about the lag
            
            for k = 1:numel(w)-1
                
                
            end
            
        end
    end
    
  


end