function [self,errorflag] = divide(self1, self2)
%RSAM/DIVIDE Divide one RSAM object by another
self1
self2
	self = self1;
	errorflag = false;
    format long
    i=find(isnan(self.dnum))
    ii=find(isnan(self2.dnum))
	if self.dnum(1) == self2.dnum(1)
		if self1.dnum(end) == self2.dnum(end)
			% zeros & NaN values not handled yet
			self.data = self.data ./ self2.data;
			if ~strcmp(self.sta, self2.sta)
				self.sta = '';
			end
			if ~strcmp(self.chan, self2.chan)
				self.chan = '';
			end
        else
            warning('end is different')
			errorflag = true;
		end
    else
        warning('start is different')
		errorflag = true;
    end
end
