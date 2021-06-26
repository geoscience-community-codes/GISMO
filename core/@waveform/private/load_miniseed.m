function w = load_miniseed(request, functiontouse)
%LOAD_MINISEED loads a waveform from MINISEED files
% combineWaves isn't currently used!

% Glenn Thompson 2016/05/25 based on load_sac
% request.combineWaves is ignored
% to use rdmseed, pass request datasource/thisSource as 'rdmseed',
% otherwise 'readmseedfast' is used.
    if ~exist('functiontouse','var')
        functiontouse = 'rdmseed';
    end

    if isstruct(request)
        [thisSource, chanInfo, startTime, endTime, ~] = unpackDataRequest(request);
        filenamelist={};

        % Work out which files we need
        % Modified by GT on 20181120 to handle multiple chantags
        for i=1:numel(chanInfo)
            thisfilename = getfilename(thisSource,chanInfo(i),startTime);
            found=false;
            listlength = numel(filenamelist);
            for c=1:listlength
                if strcmp(thisfilename,filenamelist{c})
                    found=true;
                end
            end
            if ~found
                filenamelist{listlength+1} = thisfilename;
                listlength=listlength+1;
            end
        end
        wfiles = [];
        % GT 20181120
        % we now have filenamelist which is a cell array of cell arrays (1
        % per chantag, but possibly more than 1 file per chantag is the
        % request crosses file boundaries

        % Load waveforms from all these files
        % Modified by GT 20181120 to loop over filenamelist and
        % filenamelist{c}
        for c=1:numel(filenamelist)
            for cc=1:numel(filenamelist{c})
                wtmp = [];
                wtmp = mseedfilename2waveform(functiontouse, filenamelist{c}{cc}, startTime, endTime);
                if ~isempty(wtmp)
                    wtmp = reshape(wtmp, [1 numel(wtmp)]);
                    wfiles = [wfiles wtmp];
                end
            end
        end

        if ~isempty(wfiles)
            w = combine(wfiles);
            w = extract(w, 'time', startTime, endTime);

            % Pad GT added 20181120
            w = pad(w, startTime, endTime, 0);
        else
            w=[];
        end

    else
        %request should be a filename
        thisFilename = request;
        if exist(thisFilename, 'file')
            w = mseedfilename2waveform(functiontouse, thisFilename);
        else
            w = waveform();
            warning(sprintf('%s: File %s does not exist',mfilename,thisFilename));
        end
    end

    w = combine(w);

end

%%
function w = mseedfilename2waveform(functiontouse, thisfilename, snum, enum)
    debug.print_debug(5,'Trying to load %s',thisfilename);
    if exist(thisfilename)
        debug.print_debug(5,'%s: Found %s',mfilename,thisfilename);
        
        if strfind(lower(functiontouse), 'fast')  
            debug.print_debug(1,'%s: Using %s',mfilename,'readmseedfast');
            s = ReadMSEEDFast(thisfilename); % written by Martin Mityska
            for c=1:numel(s)
                debug.print_debug(10, sprintf('Got segment %d of %d', c, numel(s)) );
                w(c) = waveform(ChannelTag(s(c).network, s(c).station, s(c).location, s(c).channel), ...
                    s(c).sampleRate, epoch2datenum(s(c).startTime), s(c).data);
            end
        else  
            debug.print_debug(1,'%s: Using %s',mfilename,'rdmseed');
            s = rdmseed(thisfilename); % written by Francois Beuducel
            for c=1:numel(s)
                debug.print_debug(10,sprintf('Got segment %d of %d', c, numel(s) ) );
                w(c) = waveform(ChannelTag(s(c).NetworkCode, s(c).StationIdentifierCode, s(c).LocationIdentifier, s(c).ChannelIdentifier), ...
                    s(c).SampleRate, s(c).RecordStartTimeMATLAB, s(c).d);
            end
        end
    else
        debug.print_debug(1,'%s: Not found %s',mfilename,thisfilename);
        w=[];
    end
end
