function w = load_miniseed(request)
%LOAD_MINISEED loads a waveform from MINISEED files
% combineWaves isn't currently used!

% Glenn Thompson 2016/05/25 based on load_sac
% request.combineWaves is ignored

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
            %wtmp = mseedfilename2waveform(thisfilename{1}, startTime, endTime);
            wtmp = mseedfilename2waveform(filenamelist{c}{cc}, startTime, endTime);
            if ~isempty(wtmp)
                wtmp = reshape(wtmp, [1 numel(wtmp)]);
                wfiles = [wfiles wtmp];
            end
        end
    end
    
    if ~isempty(wfiles)
        w = combine(wfiles);
%         if debug.get_debug()>1
%             disp('Combined')
%             w % disp diagnostic info - has combine flipped things?
%         end        
        % Extract based on time
        %if ~isnan(get(w,'start'))
        w = extract(w, 'time', startTime, endTime);
%         if debug.get_debug()>1
%             disp('Extracted')
%             w % disp diagnostic info - has combine flipped things?
%             stop
%         end


        % Pad GT added 20181120
        w = pad(w, startTime, endTime, 0);
    else
        w=[];
    end

    % Extract based on ChannelTag
    %w = matchChannelTag(w);
        
else
    %request should be a filename
    thisFilename = request;
    if exist(thisFilename, 'file')
        w = mseedfilename2waveform(thisFilename);
    else
        w = waveform();
        warning(sprintf('%s: File %s does not exist',mfilename,thisFilename));
    end
end
end

%%
function w = mseedfilename2waveform(thisfilename, snum, enum)
    debug.print_debug(1,'Trying to load %s',thisfilename);
    if exist(thisfilename)
        debug.print_debug(1,'%s: Found %s',mfilename,thisfilename);
        disp('Calling ReadMSEEDFast')
        s = ReadMSEEDFast(thisfilename); % written by Martin Mityska
         for c=1:numel(s)
            w(c) = waveform(ChannelTag(s(c).network, s(c).station, s(c).location, s(c).channel), ...
                s(c).sampleRate, epoch2datenum(s(c).startTime), s(c).data);
         end
    else
        debug.print_debug(1,'%s: Not found %s',mfilename,thisfilename);
        w=[];
    end
end
