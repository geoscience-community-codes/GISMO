%MULTIPLET - the blueprint for a Peakmatch Multiplet Channel object in GISMO
%a Multiplet object is a container for the relevant information for a
%peakmatch multiplet set such as channeltag, filepaths, waveforms, and arrivals,
classdef Multiplet
    
    properties 
       ctag
       filepaths = {}
       waveforms
       arrivals
    end
    
    properties (Dependent)
        numfiles
    end
    
    methods
        function obj = Multiplet(varargin)
            % Constructor for the MultipletChan object
            
            % if no arguments passed
            if nargin == 0
                return
            end
            
            % create parser object
            p = inputParser;
            
            % positional arguments - may change to parameter arguments idk
            p.addOptional('ctag', @ChannelTag)
            p.addOptional('filepaths', {}, @iscell)
            p.addOptional('waveforms', @waveform)
            p.addOptional('arrivals',@Arrival)
            
            p.parse(varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                eval(sprintf('%s = val;',field));
            end
            
            % if no waveform is passed make it an empty waveform object
            if isempty(waveforms)
               waveforms = waveform();
            end
            
            % if no arrival object passed make it an empty Arrival object
            if isempty(arrivals)
               arrivals = Arrival();
            end
            
            % assign properties
            obj.ctag = ctag;
            obj.filepaths = filepaths;
            obj.waveforms = waveforms;
            obj.arrivals = arrivals;
            
        end
        
        function val = get.numfiles(obj)
            for c = 1:numel(obj.ctag)
                val(c) = numel(obj.filepaths);
            end
        end
        
        
        function w = stack(obj)
            % waveforms are stored as the full discrete waveform from
            % peakmatch. clip waveforms to align waveforms to mimic
            % peakmatch correlation
            w = obj.waveforms;
            w = clip_waveforms(w);
            c = correlation(w,get(w,'start'));
            c = xcorr(c);
            c = adjusttrig(c,'median');
            c = stack(c);
            w = waveform(c);
        end
        
        
        function [p_arrivals,s_arrivals] = pick(obj)
            % makes pick on stack and applies the pick to each waveform in
            % the multiplet object
            
            w = obj.stack;
            stack = w(end);
            
            disp('Zoom towards on waveform. Include S in zoom if possible')
            plot(stack);
            
            % switch-case for the P-Arrival pick
            reply = input('Is there a P-Arrival?(y/n): ','s');
            
            switch reply
                case 'y'
                    
                    disp('Waiting for a P-arrival pick...')
                    p_pick = ginput(1);
                    pick(1) = p_pick(1); % don't care about y-value
                    
                    phase{1} = input('Phase Remark? ' ,'s');
                    
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
                    pick(2) = s_pick(1); % don't care about y-value
                    
                    phase{2} = input('Phase Remark? ','s');

                case 'n'
                    disp('Exiting pick')
                otherwise
                    disp('Must use a lowercase y or n')
            
            end
            
            % compute arrival time for each waveform 
            for i = 1:numel(w)
                
                data = get(w,'data');
                [corr,lag] = xcorr(data{i},data{end},'coeff'); % end = stack
                [mcorr,ind] = max(corr); % get maxcorr and it's index
                mcorr_samp = lag(ind); % maxcorr lag in samples
                fs = get(w(i),'freq'); % sampling frequency
                mcorr_lagtime = mcorr_samp/fs; % maxcorr lag in seconds
                lag_time = mcorr_lagtime/86400; % maxcorr lag in days
                start_time = get(w(i),'start'); % start_time in datenum (days)
                
                % arrival times in datenum format
                p_arrivals(i) = start_time + lag_time + pick(1);
                s_arrivals(i) = start_time + lag_time + pick(2);
                
            end
            
            

            
%           % write to arrival object
%             for i = 1:2
%                 sta = {obj.ctag.station()};
%                 chan = {obj.ctag.channel()};
%                 iphase = phase(1);
%                 
%             end


        end
        
    end
end
    
   