function allw=antelope2waveform(dbpath, chantag, starttime, endtime)
%ANTELOPE2WAVEFORM Load waveform objects from Antelope database
% W=ANTELOPE2WAVEFORM(DBPATH, CHANTAG, STARTTIME, ENDTIME) will
% load a vector of waveform objects from an Antelope database containing a
% wfdisc table. The database given by DBPATH is subsetted for the given
% CHANTAG. The database is also subsetted from STARTTIME to ENDTIME which
% must be in epoch format, not MATLAB datenum. The returned waveform
% objects are NaN-padded from STARTTIME to ENDTIME.
% Internally ANTELOPE2WAVEFORM uses trload_css and trextract_data.
% trload_css often fails in bulk request mode, e.g. if there is a problem
% with the Miniseed file pointed to by one wfdisc row. So ANTELOPE2WAVEFORM
% will automatically failover to get one waveform object at a time.
%
% To do:
%    currently if you request a set of stations like 'AKT|CRAP|VIB' where
%    there are no records for CRAP in the time range, only 2 waveform
%    objects returned, not 3. It all depends on the dbsubset, so also a set
%    of stations like 'AKT|AKT|AKT' will return just 1 waveform object. It
%    would be convenient if empty waveforms (NaN-padded?) were returned for
%    missing stations. Same logic for channels. 
%
% Note that seg faults seem so far to be related to opening too many
% databases and running out of memory to load more. I think I now have the
% right combination of dbfree and dbclose to avoid this.
%
%
% Glenn Thompson, 2015/11/13


    % set return variables blank in case we exit early
    allw = [];
    w = [];

    % open the database, subset
    dbpath
    db = dbopen( dbpath,'r' );
    db = dblookup_table( db,'wfdisc' );
    
    % if just have N channeltags should return N waveforms in same order
    % difficulty is when have wildcards, as those can match multiple
    % stations and multiple channels. Remember can be like sta='R*',
    % chan='EH*'. Can even be sta = {'R*'; 'S*'}. Could open database, get a unique set of stations and
    % channels and then match against requests. 
    % COuld have logic like:
    stalist = {chantag.station};
    chanlist = {chantag.channel};
    expr = ' ';
    for c=1:numel(stalist)
        stalist{c}
        chanlist{c}
        if c==1
            expr = sprintf('(sta=~/%s/ && chan=~/%s/)', stalist{c}, chanlist{c});
        else
            expr = expr + sprintf('(sta=~/%s/ && chan=~/%s/)', stalist{c}, chanlist{c});
        end
        if c<numel(stalist);
            expr = expr + ' || ';
        end
    end
    
    % should really add network and location to this logic
    % then we could open database, find the unique sta-chan for matching rows
    % and then attempt to return one waveform object for each request
    
    db = dbsubset(db, expr);
    dbnrecs(db)
    db = dbsubset(db, sprintf('time <= %f && endtime >= %f',endtime,starttime));
    
    % return if no rows
    if dbnrecs(db)==0
        return
    end
    fprintf('Got %d matching records\n',dbnrecs(db));
    [wfid,sta,chan,st,et]=dbgetv(db, 'wfid','sta','chan','time', 'endtime');
    sta = cellstr(sta);
    chan = cellstr(chan);
    if debug.get_debug()>1
        for c=1:numel(sta)
            fprintf('%12d %s %s %f %f\n',wfid(c), sta{c}, chan{c}, st(c), et(c));
        end
    end
    
    % Does the input include wildcards?
    wildcards = false;
    for c=1:numel(stalist)
        if strfind(stalist{c},'*') 
            wildcards = true;
        end
        if strfind(chanlist{c},'*') 
            wildcards = true;
        end
    end  
    
    % Create the list of channeltags to return
    if wildcards 
        chantag_out = ChannelTag.array('',sta,'',chan);
        chantagstr = chantag_out.string();
        chantag_out = ChannelTag.array(unique(chantagstr));
    else
        chantag_out = chantag;
    end

    % if starttime and endtime blank, get from min/max times in wfdisc table
    if isempty(starttime) & isempty(endtime)
        starttime = min(st);
        endtime = max(et);
    end
    
    % create trace table & close database
    try
        fprintf('Bulk mode')
        tr = trload_css(db, starttime, endtime);
        w = trace2waveform(tr);
        % sometimes this fails with error like:
            % Warning: some failure reading and interpreting the data for AKT:HHZ at 11/16/2011 (320) 15:44:27.706
            %  
            % Error using trload_css
            % trload_css failed
    catch % here we try to loop over each row in db. just setting db.record = c in insufficient as it seems
        % whenever trload_css is given a dbpointer it reads whole view, not
        % just the record specified. so instead we subset view with the
        % wfid for each record in turn, and pass this new view to
        % trload_css.
        % However, now we get segmentation faults because too many
        % databases are open. Yet closing them just results in 
        fprintf(' - failed\n\nTrying single mode\n');
        w = [];
        for c=1:dbnrecs(db)
            db.record = c-1;
            wfid=dbgetv(db, 'wfid');
            db2 = dbsubset(db, sprintf('wfid==%d',wfid));
            fprintf('Got %d matching records\n',dbnrecs(db2));
            [wfid, sta, chan, st, et]=dbgetv(db2, 'wfid','sta','chan','time', 'endtime');
            fprintf('%12d %s %s %f %f\n',wfid, sta, chan, st, et);
            try
                tr = trload_css(db2, starttime, endtime);
                w = [w; trace2waveform(tr)];
                trdestroy( tr );
            catch ME
                if strcmp(ME.identifier, 'MATLAB:unassignedOutputs')
                    % no trace table returned by trload_css
                    w = [w; waveform(ChannelTag('',sta,'',chan), NaN, epoch2datenum(starttime), [], '')];
                else
                    rethrow(ME)
                end
            end
            try
                dbfree(db2)
            catch ME
                ME.identifier
                rethrow ME
            end     
        end
        
    end
    dbclose( db );
    w = combine(w);
    
    
    % now check we have one waveform object per request sta-chan combo
    allw = waveform(chantag_out(1), 0, epoch2datenum(starttime), [], '');
    for c=2:numel(chantag_out)
        allw = [allw; waveform(chantag_out(c), 0, epoch2datenum(starttime), [], '')];
    end
    
    for c=1:numel(w)
        sta = get(w(c),'station');
        chan = get(w(c),'channel');
        for cc=1:numel(chantag_out)
            if strcmp(sta, chantag_out(cc).station) & strcmp(chan, chantag_out(cc).channel)
                allw(cc) = w(c);
            end
        end
    end
    allw=pad(allw,epoch2datenum(starttime), epoch2datenum(endtime), NaN);
    
end

function w = trace2waveform(tr)
    % create empty waveform variables
    wt = repmat(waveform(),dbnrecs(tr),1);

    % load data and metadata from trace table into waveform objects
    for cc=1:dbnrecs(tr)
        tr.record = cc-1;
        trapply_calib(tr);
        s = tr2struct(tr);
        %[trsta, trchan, trtime, trendtime, trnsamp, trsamprate, trinstype, trcalib, trcalper, trresponse, trdatatype, trsegtype] = dbgetv(tr, 'sta', 'chan', 'time', 'endtime', 'nsamp', 'samprate','instype','calib','calper','response','datatype','segtype');
        trdata = trextract_data( tr );
        trunits = '';
        wt(cc) = waveform(ChannelTag('',s.sta,'',s.chan), s.samprate, epoch2datenum(s.time), trdata, trunits);
    end
    w = combine(wt); % combine waveforms based on ChannelTag (I think)
    clear wt
end
