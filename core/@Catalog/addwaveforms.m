function cobj = addwaveforms(cobj, varargin)
% CATALOG.ADDWAVEFORMS Add waveform objects corresponding to each event in 
% a Catalog object. This populates the waveforms property in a Catalog
% object, using the ontime and offtime properties. For example, if the 
% Catalog object variable is cobj, then cobj.ontime should be set to the
% start times of the events, and cobj.offtime should be set to the end times
% of the events. If you do not explicitly set these, they will probably be
% set to NaN, so addwaveforms() will fail.
% 
% cobj2 = cobj.addwaveforms(w_continuous) will extract event waveform objects from a
% continuous waveform object, w_continuous. Each event is defined by its ontime and
% offtime, which are recorded in cobj.
%
% cobj2 = cobj.addwaveforms(w_continuous, pretriggerSecs, posttriggerSecs)
% will prepend each waveform by pretriggerSecs Seconds before the 
% corresponding ontime. And append the corresponding offtime by posttriggerSecs.
%
% cobj2 = cobj.addwaveforms(ds, ctag, pretriggerSecs, posttriggerSecs) will create event waveform objects from
% datasource, ChannelTag.array. 
%
% Tip: if the ontime and offtime for each event in your Catalog object are
% set to NaN, you can set them like this:
%     cobj.ontime = cobj.otime;
%     cobj.offtime = cobj.otime + 60/86400;
% This would give each event a 60 second timewindow, starting at the origin
% time for that event. Then run this addwaveforms method.

% Glenn Thompson: Last edited 2019/05/08

    disp(sprintf('Adding waveforms for each of %d events in Catalog',cobj.numberOfEvents))
    w_events = {};
    pretriggerSecs = 0;
    posttriggerSecs = 0;
    if all(isnan(cobj.ontime)) || all(isnan(cobj.offtime))
        cobj.ontime = cobj.otime;
        cobj.offtime = cobj.otime;
        disp('Your ontime and offtime values for each event in your Catalog object are set to NaN')
        disp('Setting these to origin time')
    end
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

        