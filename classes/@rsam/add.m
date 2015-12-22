function [self,errorflag]=add(rsam_vector)
%RSAM/ADD Add (or stack) multiple RSAM objects
self = rsam_vector(1);
errorflag = false;
for c=2:numel(rsam_vector)
	if self.dnum(1) == rsam_vector(c).dnum(1)
		if self.dnum(end) == rsam_vector(c).dnum(end)
			% NaN values not handled yet
			self.data = self.data + rsam_vector(c).data;
			if ~strcmp(self.sta, rsam_vector(c).sta)
				self.sta = '';
			end
			if ~strcmp(self.chan, rsam_vector(c).chan)
				self.chan = '';
			end
		else
			errorflag = true;
		end
	else
		errorflag = true;
	end
end
