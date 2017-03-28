function self=rsam2energy(self, r)
    % should i detrend first?
    e = energy(self.data, r, get(self.scnl, 'channel'), self.Fs(), self.units);
        self = set(self, 'energy', e);
end