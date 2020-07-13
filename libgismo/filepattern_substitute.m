function files_=filepattern_substitute(filepattern,ctag,dnum)
% files = filepattern_substitute(filepattern, thisChannelTag)
% Takes a file pattern and returns a structure, which contains filenames,
% start times and end times, and whether that file exists or not.
%
% Valid substitutions:
%   SSSS    - station
%   CCC     - channel
%   SCN     - station-channel-network
%   NSLC    - network.station.location.channel
%   YYYY    - year
%   MM      - month
%   DD      - day
%
% Examples:
% (1) Substitute for ChannelTag and YYYY-MM-DD
%     ctags(1) = ChannelTag('MV','MTB1','00','HHZ');
%     dnum = [datenum(2000,1,1) datenum(2001,1,2)]
%     f = filepattern_substitute('test.NSLC.YYYY-MM-DD.bob',ctags(1),dnum)
%   Returns a structure of 368 files named like 
%   test.MV.MTB1.00.HHZ.2000-01-01.bob to test.MV.MTB1.00.HHZ.2001-01-02.bob
%
% (2) Substitute for year only
%   f = filepattern_substitute('test.NSLC.YYYY.bob',ctags(1),dnum)
%   test.MV.MTB1.00.HHZ.2000.bob and test.MV.MTB1.00.HHZ.2001.bob
%
% (3) Substitute in filepath too
%   f = filepattern_substitute('YYYY/test.NSLC.YYYY.bob',ctags(1),dnum)
%   2000/test.MV.MTB1.00.HHZ.2000.bob and 2001/test.MV.MTB1.00.HHZ.2001.bob
% 
% Glenn Thompson 2018/12/10 Barrow on Soar, UK
    debug.printfunctionstack('>');
    
    file = filepattern;
    file = regexprep(file, 'SSSS', ctag.station); % substitute for station
    file = regexprep(file, 'CCC', ctag.channel);  % substitute for channel
    file = regexprep(file, 'NSLC', ctag.string());   % substitute for NSLC
    file = regexprep(file, 'SCN', ctag.scn());  % substitute for SCN
    snum = min(dnum);
    enum = max(dnum);
    
    % This is the returned list when there are no YYYY, MM or DD
    % substitutions
    files_(1).snum = snum;
    files_(1).enum = enum;
    files_(1).file = file;
    files_(1).found = exist(file,'file');
    
    % Now deal with YYYY, MM, DD
    [syyy sm sd]=datevec(snum);
    [eyyy em ed]=datevec(enum);

    if regexp(file,'DD')
        debug.print_debug(10,'Have to bother with days');
        if ~(   (regexp(file,'YYYY')) & (regexp(file,'MM'))  )
            error('Cannot span multiple days unless YYYY and MM also in file pattern');
        else
            N=1;
            for thisdaynum = floor(snum):floor(enum)
%                 files_(N).snum = max([snum thisdaynum]);
%                 files_(N).enum = min([enum thisdaynum+1-eps]);
                files_(N).snum = thisdaynum;
                files_(N).enum = thisdaynum+1-eps;                
                f = file;
                [yyyy mm dd] = datevec(thisdaynum);
                f = regexprep(f, 'YYYY', sprintf('%04d',yyyy));
                f = regexprep(f, 'MM', sprintf('%02d',mm));
                f = regexprep(f, 'DD', sprintf('%02d',dd));
                files_(N).file = f;  
                files_(N).found = exist(f,'file');
                N=N+1;
            end

        end

    elseif regexp(file,'MM')
        debug.print_debug(10,'Have to bother with months');
        if ~regexp(file,'YYYY')
            error('Cannot span multiple months unless YYYY also in file pattern');
        else
            N=1;
            thisyyyy=syyy;
            thismm=sm;

            for thismonthnum = (syyy*12+sm):(eyyy*12+em)
%                 files_(N).snum = max([snum datenum(0,thismonthnum,1)]);
%                 files_(N).enum = min([enum datenum(0,thismonthnum+1,1)-eps]);
                 files_(N).snum = datenum(0,thismonthnum,1);
                 files_(N).enum = datenum(0,thismonthnum+1,1)-eps;

                f = file;
                [yyyy mm dd] = datevec(datenum(0,thismonthnum,1));
                f = regexprep(f, 'YYYY', sprintf('%04d',yyyy));
                f = regexprep(f, 'MM', sprintf('%02d',mm));
                files_(N).file = f;  
                files_(N).found = exist(f,'file');
                N=N+1;
            end
        end
        
    elseif regexp(file,'YYYY')
        debug.print_debug(10,'Have to bother with years')
        N=1;
        for thisyear = syyy:eyyy
%             files_(N).snum = max([datenum(thisyear,1,1) snum]);
%             files_(N).enum = min([datenum(thisyear+1,1,1)-eps enum]);
             files_(N).snum = datenum(thisyear,1,1);
             files_(N).enum = datenum(thisyear+1,1,1)-eps;
            f = file;
            f = regexprep(f, 'YYYY', sprintf('%04d',thisyear));
            files_(N).file = f;  
            files_(N).found = exist(f,'file');
            N=N+1;
        end
        
    end
    debug.printfunctionstack('<');
end
