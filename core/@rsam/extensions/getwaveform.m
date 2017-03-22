function w=getwaveform(self, datapath)
% rsam.getwaveform() Get the waveform corresponding to the RSAM data
%   w = rsamobject.getwaveform() will attempt to get the waveform
%       data corresponding to a rsam object. Three locations are
%       tried:
%           1. MVO Seisan data
%           2. MVO Antelope data
%           3. AVO/AEIC data
%   Alternatively, the user may optionally provide a datasource object
    if isempty(self.sta)
        self.sta = '*';
    end
    if isempty(self.chan)
        self.chan = '*';
    end           
    scnl = scnlobject(self.sta, self.chan)
    w = load_seisan_waveforms(datapath, min(self.dnum), max(self.dnum), scnl);
end  