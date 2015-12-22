function s=subset(self, snum, enum)
%RSAM/SUBSET Subset an RSAM object between two dates
% rsamobj2 = rsamobj1.subset(datenum1, datenum2)
if enum<snum
	temp=enum;
	enum=snum;
	snum=temp;
end
            for c=1:numel(self)
                s(c) = self(c);
                i = find(self(c).dnum>=snum & self(c).dnum <= enum);
                s(c).dnum = self(c).dnum(i);
                s(c).data = self(c).data(i);
s(c).snum = min(s(c).dnum);
s(c).enum = max(s(c).dnum);
            end
end
