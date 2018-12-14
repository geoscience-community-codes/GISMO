%% Define calibration information
infraBSU = 46; % microV/Pa for 0.5" infraBSU
trillium = 750; % V/(m/s) for Trillium = 750 uV/(um/s)
centaurnormal = 0.4; % count/microV at 40 V FS
centaurhighgain = 16; % count/microV at 1 V FS

calibCentaurTrillium = 1/trillium * 1000 * 1/centaurnormal; % 3.33 nm/s/count (1000 is um/s to nm/s)
calibInfraBSUTrilliumHigh = 1/infraBSU * 1/centaurhighgain; % 0.0014 Pa/count
calibInfraBSUTrilliumLow = 1/infraBSU * 1/centaurnormal; % 0.0543 Pa/count
for count=1:numel(ChannelTagList)
    chan = ChannelTagList(count).channel;
    if chan(2)=='H'
        calibObjects(count) = Calibration(ChannelTagList(count), ...
            calibCentaurTrillium, 'nm / sec');
    elseif chan(2)=='D'
        calibObjects(count) = Calibration(ChannelTagList(count), ...
            calibInfraBSUTrilliumHigh, 'Pa');
    end
end