function w= rsam2waveform(s)
    w = [];
    for c=1:numel(s)
        wc = waveform(s(c).ChannelTag, 1.0/s(c).sampling_interval, s(c).snum, s(c).data, s(c).units);
        w = [w wc];
    end
end