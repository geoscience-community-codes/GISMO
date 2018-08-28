function w= rsam2waveform(s)
    w = [];
    for c=1:numel(s)
        if numel(s(c).data) > 0
            wc = waveform(s(c).ChannelTag, 1.0/s(c).sampling_interval, s(c).snum, s(c).data, s(c).units);
        else
            wc = waveform(s(c).ChannelTag, 1.0/s(c).sampling_interval, 0, [], s(c).units);
        end
        w = [w wc];
    end
end