function w=rsam2waveform(self)
    w = waveform;
    w = set(w, 'station', self.sta);
    w = set(w, 'channel', self.chan);
    w = set(w, 'units', self.units);
    w = set(w, 'data', self.data);
    w = set(w, 'start', self.snum);
    %w = set(w, 'end', self.enum);
    w = set(w, 'freq', 1/ (86400 * (self.dnum(2) - self.dnum(1))));
    w = addfield(w, 'reduced', self.reduced);
    w = addfield(w, 'measure', self.measure);
end