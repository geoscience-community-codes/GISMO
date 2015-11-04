function w2 = waveform_remove_empty(w);
%WAVEFORM_REMOVE_EMPTY remove empty waveform objects from a vector of waveform objects
%   Note that the opposite function, of expanding empty waveform objects can largely
%   be achieved with waveform/pad

%   Glenn Thompson
    e = 1;
    for c=1:length(w)
            nsamp = get(w(c), 'data_length');
            if nsamp > 1 % 0 means blank waveform object, 1 means corrupt waveform object
                    w2(e) = w(c);
                    e = e + 1;
            end
    end
    if e==1
            w2 = [];
    end
end

