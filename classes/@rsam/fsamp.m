function fs = fsamp(self)
%RSAM/FSAMP Get sampling frequency of an RSAM object
% fs = rsamobj.fsamp()
	for c=1:length(self)
                l = length(self(c).dnum);
                timediffdays = self(c).dnum(2) - self(c).dnum(1);
                fs(c) = 1.0/(timediffdays*86400);
        end
end
