function cobj = addwaveforms(cobj, w_continuous)
% Catalog.addwaveforms Add waveform objects corresponding to ontimes and
% offtimes in a Catalog object.
% 
% cobj2 = cobj.addwaveforms(w_continuous) will extract event waveform objects from a
% continuous waveform object, w_continuous. Each event is defined by its ontime and
% offtime, which are recorded in cobj.

    w_temp = extract(w_continuous, 'time', cobj.ontime, cobj.offtime);
    for count = 1:length(cobj.ontime)
        w_events{count} = w_temp(:,count);
    end
    cobj.waveforms = w_events;
end

        