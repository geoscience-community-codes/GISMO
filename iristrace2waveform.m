function w=iristrace2waveform(ts)
    if ~exist('ts','var')
        ts = irisFetch.Traces('X3','MBM2','*','*','2016-02-23 22:30:00','2016-02-23 23:30:00','includepz');
    end
    w = [];
    response = [];
    
    for c=1:length(ts)
        ctag = ChannelTag(ts(c).network, ts(c).station, ts(c).location, ts(c).channel);
        starttime = ts(c).startTime;
        data = ts(c).data;
        samplerate = ts(c).sampleRate;
        sensitivityUnits = ts(c).sensitivityUnits;
%         if strcmp(sensitivityUnits, 'M/S')
%             sensitivityUnits = 'nm / sec';
%             data = data * 1e9;
%         end
        w0 = waveform(ctag, samplerate, starttime, data, sensitivityUnits);
        
        if ~isempty(ts(c).sacpz)
            % frequencies = [...]
            %response = pz2response(ts(c), frequencies);
            y = data;
            calib = ts(c).sacpz.constant;
            if abs(calib) > 0
                y = y * calib;
            end

            if calib~=0
                w0 = addfield(w0,'calib', calib);
                w0 = addfield(w0, 'calibration_applied', 'NO');
                w0 = set(w0, 'units', ts(c).sacpz.units);
            end
        end

        w = [w w0];

    end
end

function response = pz2response(obj, frequencies)
    % INITIALIZE THE OUTPUT ARGUMENT
    response.scnl = scnlobject(obj.station,obj.channel,obj.network,obj.location);
    response.time = obj.startTime;
    response.frequencies = reshape(frequencies,numel(frequencies),1);
    response.values = [];
    response.calib = obj.sacpz.constant;
    response.units = obj.sacpz.units;
    response.sampleRate = obj.samplerate;
    response.source = 'FUNCTION: RESPONSE_GET_FROM_POLEZERO';
    response.status = [];
    
    
    Z = obj.sacpz.zeros;
    P = obj.sacpz.poles;

    % Pole/zeros can be normalized with the following if not already normalized:
    normalization = 1/abs(polyval(poly(Z),2*pi*1j)/polyval(poly(P),2*pi*1j));


    % CALCULATE COMPLEX RESPONSE AT SPECIFIED FREQUENCIES USING
    % LAPLACE TRANSFORM FUNCTION freqs
    ws = (2*pi) .* frequencies;
    response.values = freqs(normalization*poly(Z),poly(P),ws);
end