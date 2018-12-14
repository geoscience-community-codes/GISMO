function w = apply_calib(w, calibObjects)
    % ADD RESPONSE FROM SUBNETS TO WAVEFORM OBJECTS
    
    % get a cell array like {'MV.MBRY..BHZ';'MV.MBLG..SHZ'; ...} from
    % calibObjects.channeltag
    for c=1:numel(calibObjects)
        chantagcell{c} = sprintf('.%s..%s',calibObjects(c).nslc.station, calibObjects(c).nslc.channel);
    end
    
    for c=1:numel(w)
        % get the ChannelTag for this waveform
        wchantag = get(w(c),'channeltag');
        wstachan = sprintf('.%s..%s',wchantag.station, wchantag.channel);
        j = strmatch(wstachan, chantagcell); % this is the index of the matching ChannelTag in calibObjects
        if length(j)==1
            calib = calibObjects(j).calib;
            addfield(w(c), 'calib', calib);
            calibunits = cellstr(calibObjects(j).units);
            if strcmp(get(w(c),'Units'), 'Counts') | strcmp(get(w(c),'Units'), 'null')
                debug.print_debug(1,'%s: Applying calib of %d %s for %s\n',mfilename, calib, calibunits, wchantag);
                if (calib ~= 0)
                    if strcmp(calibunits{1}, 'Pa') % not sure about this - 
                        % probably needed if use same dbRange for seismic
                        % and infrasound
                        calibunits = {'mPa'};
                        calib = calib * 1000;
                    end

                    w(c) = w(c) * calib;
                    w(c) = set(w(c), 'units', calibunits{1});
                end
                %fprintf('%s: Max corrected amplitude for %s.%s = %e nm/s\n',mfilename: thissta, thischan, rawmax);
            end
        end
    end
end
