function self = remove_calibs(self)    
     for c=1:numel(self)
    % run twice since there may be two pulses per day
            self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
            self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
     end
end