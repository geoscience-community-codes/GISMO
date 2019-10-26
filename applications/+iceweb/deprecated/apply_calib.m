function w = apply_calib(w, sites)
    % ADD RESPONSE FROM SUBNETS TO WAVEFORM OBJECTS
    
    % get a cell array like {'MV.MBRY..BHZ';'MV.MBLG..SHZ'; ...} from
    % sites.channeltag
    for c=1:numel(sites)
        chantagcell{c} = sprintf('.%s..%s',sites(c).channeltag.station, sites(c).channeltag.channel);
    end
    
    for c=1:numel(w)
        % get the ChannelTag for this waveform
        wchantag = string(get(w(c),'channeltag'));
        j = strmatch(wchantag, chantagcell); % this is the index of the matching ChannelTag in sites
        if length(j)==1
            calib = sites(j).calib;
            addfield(w(c), 'calib', calib);
            calibunits = sites(j).units;
            if strcmp(get(w(c),'Units'), 'Counts') | strcmp(get(w(c),'Units'), 'null')
                fprintf('%s: Applying calib of %d for %s\n',mfilename, calib, wchantag);
                if (calib ~= 0)
%                     if strcmp(calibunits{1}, 'Pa')
%                         calibunits = {'mPa'};
%                         calib = calib * 1000;
%                     end
                    w(c) = w(c) * calib;
                    w(c) = set(w(c), 'units', calibunits{1});
                    %w(c) = set(w(c), 'units', 'nm / sec');
                end
                %fprintf('%s: Max corrected amplitude for %s.%s = %e nm/s\n',mfilename: thissta, thischan, rawmax);
            end
        end
    end
end
