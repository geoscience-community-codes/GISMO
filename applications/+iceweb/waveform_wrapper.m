function w = waveform_wrapper(ds, ChannelTagList, snum, enum);
%WAVEFORM_WRAPPER adds some extra wrapping around a waveform call

%   Glenn Thompson

    %debug.print_debug(1, sprintf('%s %s: Getting waveforms from %s to %s',mfilename, datestr(now), datestr(snum), datestr(enum) ) );
    try
        w = waveform(ds, ChannelTagList, snum, enum);     
    catch
        w = [];
        for c=1:numel(ChannelTagList)
            %try
                wchan = waveform(ds, ChannelTagList(c), snum, enum);
                w = [w wchan];
            %catch
            %    debug.print_debug(1, sprintf('%s %s: Loading waveform data for %s %s failed',mfilename, datestr(now), datestr(snum), ChannelTagList(c).string()) )
            %end
        end
    end
    fclose('all'); % ensure that we didn't leave any files open

    if isempty(w)
        debug.print_debug(1, 'No waveform data returned - here are the waveform() parameters:');
        save failedwaveformcall.mat ds ChannelTagList snum enum
        debug.printfunctionstack('<');
        return
    else
        w = combine(w);
    end
end
