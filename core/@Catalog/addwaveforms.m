function cobj = addwaveforms(cobj, varargin)
% Catalog.addwaveforms Add waveform objects corresponding to ontimes and
% offtimes in a Catalog object.
% 
% cobj2 = cobj.addwaveforms(w_continuous) will extract event waveform objects from a
% continuous waveform object, w_continuous. Each event is defined by its ontime and
% offtime, which are recorded in cobj.
%
% cobj2 = cobj.addwaveforms(ds, ctag, pretrigger, posttrigger) will create event waveform objects from
% datasource, ChannelTag.array. Each event is defined by its ontime and
% offtime, which are recorded in cobj.
% 

    w_events = {};
    switch nargin
        case 2
            if isa(varargin{1},'waveform')
                w_temp = extract(varargin{1}, 'time', cobj.ontime, cobj.offtime);
                for count = 1:length(cobj.ontime)
                    w_events{count} = w_temp(:,count);
                end
                
            end
        case 5
            if isa(varargin{1},'datasource')
                for count = 1:length(cobj.ontime)
                    w_events{count} = waveform(varargin{1}, varargin{2}, cobj.ontime(count)-varargin{3}/86400, cobj.offtime(count)+varargin{4}/86400); 
                end
            end
        otherwise
            nargin
    end
    cobj.waveforms = w_events;
end

        