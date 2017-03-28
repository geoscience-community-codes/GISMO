function s=extract(self, snum, enum)
    s = self;
    for c=1:numel(self)
        i = find(self(c).dnum>=snum & self(c).dnum <= enum);
        s(c).dnum = self(c).dnum(i);
        s(c).data = self(c).data(i);
    end
end
