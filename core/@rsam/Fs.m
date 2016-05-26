function fs = Fs(self)
    l = length(self.dnum);
    s = self.dnum(2:l) - self.dnum(1:l-1);
    fs = 1.0/(median(s)*86400);
end