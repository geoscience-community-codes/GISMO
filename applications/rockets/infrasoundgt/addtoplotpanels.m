%     THIS CODE IS FOR PLOTTING METRICS ON WAVEFORM
%     THIS COULD BE ABSORBED INTO PLOT PANELS
%     for arrivalnum=1:numel(arrivalobj.amp)
%         fprintf('.');
%         thisA = arrivalobj.subset(arrivalnum);
%         thisW = detrend(fillgaps(w(arrivalnum),'interp')); % make sure there is no trend or offset
% 
%         % plot waveform for arrival
%         fh=plot_panels(thisW, false, thisA);
%         ah=get(fh,'Children');
%         set(fh, 'Position', [0 0 1600 1000]);
%         hold on
%         plot(maxSecs, misc_fields.maxAmp(arrivalnum), 'g*');
%         plot(minSecs, misc_fields.minAmp(arrivalnum), 'r*');
%         teststr = sprintf('maxTime = %s, minTime = %s, timeDiff = %.3f s\namp = %.2e, maxAmp = %.2e, minAmp = %.2e\n rms = %.2e, energy = %.2e',  ...
%             datestr(maxTime,'HH:MM:SS.FFF'), ...
%             datestr(minTime,'HH:MM:SS.FFF'), ...
%             86400*(maxTime-minTime), ...
%             amp, ...
%             maxAmp, ...
%             minAmp, ...
%             stdev, ...
%             energy);
%         text(0.1, 0.1, teststr, 'units', 'normalized')
%         dummy=input('Any key to continue');
%         close
% 
%     end