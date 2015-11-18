function [ arrivalsObj ] = retrieve_seisan( fileContents, eventtime )
%RETRIEVE_SEISAN Retrieve arrivals from a Seisan S-file
%   [ arrivalsObj ] = retrieve_seisan( fileread('/path/to/sfile'), eventtime ) 
  
  % Read lines into cell array
    lines = strread(fileContents, '%s', 'delimiter', sprintf('\n'));
    linenum = 1;
    arrivalsFound = false;
    arid = 0;
    [yr, mo, dy] = datevec(eventtime);

    while linenum <= numel(lines),
        tline = fileContents(1+(linenum-1)*82:min([length(fileContents) 80+(linenum-1)*82]));
        linenum = linenum + 1;
        %disp(sprintf('*%s*',tline));
        linelength=length(tline); 
        if ischar(tline) & linelength == 80
            lineend = tline(80);
        else
            continue
        end

        if lineend == '7'
            arrivalsFound = true;
        end
        
        if arrivalsFound
            if lineend == ' '
                sta = strtrim(tline(1:5)); % station
                if ~isempty(sta)
                    chan = strtrim(tline(6:8)); % channel
                    iore = tline(9); % impulsive or emergent
                    iphase = strtrim(tline(10:13)); % phase type
                    weight = str2num(tline(14)); % quality/weight
                    polarity = tline(16); % polarity
                    hr = str2num(tline(18:19)); % hour
                    mi = str2num(tline(20:21)); % minute
                    sec = str2num(tline(22:27)); % second
                    snr = str2num(tline(57:59)); % signal:noise
                    tres = str2num(tline(64:68)); % time residual 
                    w = str2num(tline(69)); % weight for time residual?
                    dis = str2num(tline(71:74)); % distance in km?
                    az = str2num(tline(76:78)); % azimuth from source

                    arid = arid + 1; % a counter for arrivals
                    arrivalid(arid) = arid;
                    ctag{arid} = ChannelTag('', sta, '', chan);
                    time(arid) = datenum( yr, mo, dy, hr, mi, sec);
                    phasetype{arid} = iphase;
                end
            end
        end
    end
    
    % create an Arrival object if we found any arrivals            
    if arid>0
        arrivalObject = Arrival(ctag, time, phasetype, 'arid', arrivalid);
    else
        arrivalObject = struct();
    end
            
end


