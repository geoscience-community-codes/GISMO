%% Define calibration information
infraBSU = 46; % microV/Pa for 0.5" infraBSU
trillium = 750; % V/(m/s) for Trillium = 750 uV/(um/s) = 0.75 uV/(nm/s)
centaurnormal = 0.4; % count/microV at 40 V FS
centaurhighgain = 16; % count/microV at 1 V FS
l22 = 88; % V/(m/s) = 88 uV/(um/s) = 0.088 uV/(nm/s)
rt130x1 = 1000 * 1/2724; % count/micorV at 40 V FS peak-to-pek
rt130x32 = 1000 * 1/85; % count/microV at 40/32 (1.25) V FS peak-to-peak
% http://trl.trimble.com/docushare/dsweb/Get/Document-726584/130S-01%20brochure.pdf

calibCentaurTrillium = 1/trillium * 1000 * 1/centaurnormal; % 3.33 nm/s/count (1000 is um/s to nm/s)
calibInfraBSUTrilliumHigh = 1/infraBSU * 1/centaurhighgain; % 0.0014 Pa/count
calibInfraBSUTrilliumLow = 1/infraBSU * 1/centaurnormal; % 0.0543 Pa/count
calibL22RT130 = 1/l22 * 1000 * 1/rt130x32; % 0.9659 nm/s/count

for count=1:numel(ChannelTagList)
    chan = ChannelTagList(count).channel;
    if chan(1)=='E' % PASSCAL L22/Reftek130
        calibObjects(count) = Calibration(ChannelTagList(count), ...
            calibL22RT130, 'nm / sec');
    elseif chan(2)=='H'
            calibObjects(count) = Calibration(ChannelTagList(count), ...
                calibCentaurTrillium, 'nm / sec');
    elseif chan(2)=='D'
            calibObjects(count) = Calibration(ChannelTagList(count), ...
                calibInfraBSUTrilliumHigh, 'Pa');
    end
end