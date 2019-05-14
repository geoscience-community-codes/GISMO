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
        
        
        function obj = pick(obj)
            % makes pick on stack and applies the pick to each waveform in
            % the multiplet object
            
            comp = obj.ctag.channel(3); % letter denoting channel (Z,E,N)
            w = obj.stack;
            stack = w(end);
            data_stack = get(stack,'data'); % define outside loop
            
            disp('Zoom towards pick area on the waveform')
            plot(stack);
            
            switch comp
                case 'Z'
                    
                    reply = input('Is there a P-Arrival?(y/n): ','s');
                    
                    switch reply
                        case 'y'
                            
                            disp('Waiting for P-arrival pick...');
                            p_pick = ginput(1);
                            p_pick = p_pick(1)/86400; % datenum value
                            
                            iphase = input('Phase Remark?(IP/EP) ', 's');
                            
                            for i = 1:numel(w)
                                
                                data = get(w(i),'data');
                                [corr,lag] = xcorr(data,data_stack,'coeff'); % stack defined outside loop
                                [~,ind] = max(corr); % get maxcorr and it's index
                                mcorr_samp = lag(ind); % maxcorr lag in samples
                                fs = get(w(i),'freq'); % sampling frequency
                                mcorr_lagtime = mcorr_samp/fs; % maxcorr lag in seconds
                                lag_time = mcorr_lagtime/86400; % maxcorr lag in days
                                start_time = get(w(i),'start'); % start_time in datenum (days)
                                
                                % arrival times in datenum format
                                p_arrival = start_time + lag_time + p_pick;
                                
                                % build arrival object
                                sta = {obj.ctag.station};
                                chan = {obj.ctag.channel};
                                a(i) = Arrival(sta,chan,p_arrival,{iphase});
                                a(i).waveforms = w(i);
                                
                            end
                            
                        case 'n'
                            
                            disp('Exiting pick...')
                            
                        otherwise
                            error("Must be lowercase 'y' or 'n'")
                    end
                    
                case {'E','N'}
                    
                    reply = input('Is there a S-Arrival?(y/n): ','s');
                    
                    switch reply
                        case 'y'
                            
                            disp('Waiting for S-arrival pick...');
                            s_pick = ginput(1);
                            s_pick = s_pick(1)/86400; % datenum value
                            
                            iphase = input('Phase Remark?(IS/ES) ', 's');
                            
                            for i = 1:numel(w)
                                
                                data = get(w(i),'data');
                                [corr,lag] = xcorr(data,data_stack,'coeff'); % stack defined outside loop
                                [~,ind] = max(corr); % get maxcorr and it's index
                                mcorr_samp = lag(ind); % maxcorr lag in samples
                                fs = get(w(i),'freq'); % sampling frequency
                                mcorr_lagtime = mcorr_samp/fs; % maxcorr lag in seconds
                                lag_time = mcorr_lagtime/86400; % maxcorr lag in days
                                start_time = get(w(i),'start'); % start_time in datenum (days)
                                
                                % arrival times in datenum format
                                s_arrival = start_time + lag_time + s_pick;
                                
                                % build arrival object
                                sta = {obj.ctag.station};
                                chan = {obj.ctag.channel};
                                a(i) = Arrival(sta,chan,s_arrival,{iphase});
                                a(i).waveforms = w(i);
                                
                            end
                            
                        case 'n'
                            
                            disp('Exiting pick...')
                            
                        otherwise
                            error("Must be lowercase 'y' or 'n'")
                    end

                otherwise
                    error("Component must be a 'Z','E',or 'N'")
            end
            
            obj.arrivals = a
            
        end
        
    end
end
    
   