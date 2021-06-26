% Three methods for computing reduced displacement:
%
% 1. Correct RSAM for calibration, geometrical spreading and attenuation
% However, this would really be reduced velocity. So need peakf or meanf to
% quasi-correct from reduced velocity to reduced displacement.
%
% 2. Take a cleaned waveform object. Ideally one either side of it too.
% 30% taper it. Bandpass filter. 30% taper again. Integrate. Throw away 1st and 3rd
% waveform segments. Now we have the displacement seismogram.
%
% 3. The original IceWeb method that did a full instrument correction, and
% then picked the peak from a frequency spectrum.

% Let us test each method
Q = 100; % attenuation
waveType = 'surface';
% wikipedia
crater = Position(-37.5226, 177.1797);
% google earth
crater = Position(-37.521792, 177.184220);
WSRZ = Position(-37.517805, 177.177923);
WIZ = Position(-37.526572, 177.188925);
drconfig.source = crater;
drconfig.station(1).position = WSRZ;
drconfig.station(2).position = WIZ;
for c = 1:numel(drconfig.station)
    drconfig.station(c).ctag = ChannelTagList(c);
    drconfig.station(c).distance = deg2km(distance(drconfig.source.latitude, drconfig.source.longitude, drconfig.station(c).position.latitude, drconfig.station(c).position.longitude)) *1000; % m
end
drconfig