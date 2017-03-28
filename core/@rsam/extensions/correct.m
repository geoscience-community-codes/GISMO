function self = correct(self)    
     ref = 0.707; % note that median, rms and std all give same value on x=sin(0:pi/1000:2*pi)
     for c=1:numel(self)
        if strcmp(self(c).measure, 'max')
            self(c).data = self(c).data * ref;
        end
        if strcmp(self(c).measure, '68')
            self(c).data = self(c).data/0.8761 * ref;
        end
        if strcmp(self(c).measure, 'mean')
            self(c).data = self(c).data/0.6363 * ref;
        end 
     end
end