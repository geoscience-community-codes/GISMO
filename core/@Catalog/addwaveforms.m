function cobj = addwaveforms(cobj, varargin)
% Catalog.addwaveforms Add waveform objects corresponding to ontimes and
% offtimes in a Catalog object.
% 
% cobj2 = cobj.addwaveforms(w_continuous) will extract event waveform objects from a
% continuous waveform object, w_continuous. Each event is defined by its ontime and
% offtime, which are recorded in cobj.
%
% cobj2 = cobj.addwaveforms(w_continuous, pretriggerSecs, posttriggerSecs)
% will prepend each waveform by pretriggerSecs Seconds. And append by
% posttriggerSecs.
%
% cobj2 = cobj.addwaveforms(ds, ctag, pretriggerSecs, posttriggerSecs) will create event waveform objects from
% datasource, ChannelTag.array. Each event is defined by its ontime and
% offtime, which are recorded in cobj.
% 
    disp(sprintf('Adding waveforms for each of %d events in Catalog',cobj.numberOfEvents))
    w_events = {};
    pretriggerSecs = 0;
    posttriggerSecs = 0;
    if nargin>1
            
            if isa(varargin{1},'waveform')
                
                if nargin>2
                    pretriggerSecs = varargin{2};
                    posttriggerSecs = varargin{3};
                end
                w_cont = clean(varargin{1});
                %w_temp = extract(w_cont, 'time', cobj.ontime, cobj.offtime);
                for count = 1:cobj.numberOfEvents
                    fprintf('.');
                    w_temp = extract(w_cont, 'time', cobj.ontime(count)-pretriggerSecs/86400, cobj.offtime(count)+posttriggerSecs/86400);
                    %w_events{count} = w_temp(:,count);
                    w_events{count} = w_temp;
                    
                    if mod(count,30) == 0
                        fprintf('\nDone %d out of %d\n',count, cobj.numberOfEvents);
                    end                    
                end
                
            end

            if isa(varargin{1},'datasource')
                if nargin>2
                    pretriggerSecs = varargin{3};
                    postriggerSecs = varargin{4};
                end
                for count = 1:cobj.numberOfEvents
                    fprintf('.');
                    thisw  = waveform(varargin{1}, varargin{2}, cobj.ontime(count)-pretriggerSecs/86400, cobj.offtime(count)+posttriggerSecs/86400); 
                    w_events{count} = clean(thisw);
                    if mod(count,30) == 0
                        fprintf('\nDone %d out of %d\n',count, cobj.numberOfEvents);
                    end
                end
            end
    end
    cobj.waveforms = w_events;
    fprintf('\n(Complete)\n');
end

        