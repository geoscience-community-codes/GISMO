function [self,errorflag]=subtract(self1, self2)
%RSAM/SUBTRACT Subtract one RSAM object from anoterh
	self = self1;
	errorflag = false;
	if self.dnum(1) == self2.dnum(1)
		if self1.dnum(end) == self2.dnum(end)
			% NaN values not handled yet
			self.data = self.data - self2.data;
			if ~strcmp(self.sta, self2.sta)
				self.sta = '';
			end
			if ~strcmp(self.chan, self2.chan)
				self.chan = '';
			end
		else
			errorflag = true;
		end
	else
		errorflag = true;
	end
end
