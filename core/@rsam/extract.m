function s=extract(self, snum, enum)
    s = self;
    i = find(self.dnum>=snum & self.dnum <= enum);
    s.dnum = self.dnum(i);
    s.data = self.data(i);
    s.snum = snum;
    s.enum = enum;
end