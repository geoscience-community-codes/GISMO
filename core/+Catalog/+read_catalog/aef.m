function self = aef(varargin)     
    % READ_CATALOG.AEF
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these deleted were
    %         maliciously deleted in June 2003. A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.
    %
    %  
  
    debug.printfunctionstack('>')

    % Process input arguments
    p = inputParser;
    p.addParamValue('dbpath', '', @isstr);
    p.addParamValue('startTime', 0, @isnumeric);  
    p.addParamValue('endTime', now, @isnumeric);
    p.addParamValue('minimumMagnitude', [], @isnumeric);
    p.addParamValue('subclass', '*', @ischar);
    p.addParamValue('minimumDepth', [], @isnumeric);
    p.addParamValue('maximumDepth', [], @isnumeric);
    p.parse(varargin{:});
    
    fields = fieldnames(p.Results);
    for i=1:length(fields)
        field=fields{i};
        % val = eval(sprintf('p.Results.%s;',field));
        val = p.Results.(field);
        eval(sprintf('%s = val;',field));
    end
    if ~exist(dbpath, 'dir')
        fprintf('Directory %s not found. Perhaps you need to generate from S files?\n',dbpath);
        return;
    end
    snum=startTime;
    enum=endTime;
    lnum=snum;

    % loop over all years and months selected
    while (  lnum <= enum ),
        [yyyy, mm] = datevec(lnum);

        % concatenate catalogs
        Object0 = import_aef_file(dbpath,yyyy,mm,snum,enum);%,p.Results.RUNMODE);
        if exist('self', 'var')
            %self = self + Object0;
            %self = combine(self, Object0);
            self = add(self, Object0);
        else
            self = Object0;
        end
        clear Object0;
        
        % ready for following month
        lnum=datenum(yyyy,mm+1,1);
    end

    self.mag(self.mag<-3)=NaN;

    if ~isempty(self.otime)

        % cut data according to threshold mag
        if ~isempty(minimumMagnitude)
            disp('Applying minimum magnitude filter')
            m = find(self.mag > minimumMagnitude);
            fprintf('Accepting %d events out of %d\n',length(m),length(self.otime));
            self.event_list = self.event_list(m);
        end    
    end
    
    debug.printfunctionstack('<')
end

%% ---------------------------------------------------
      
function self = import_aef_file(dirpath, yyyy, mm, snum, enum, RUNMODE)
% readEvents.import_aef_file Read an individual aef_file. Used only by
% readEvents.load_aef
    %   Wrapper for loading dat files generated from Seisan S-FILES (REA) databases.
    %   DAT file name is like YYYYMM.dat
    %   DAT file format is like:
    %   
    %   YYYY MM DD HH MM SS c  MagE
    %
    %   where YYYY MM DD HH MM SS is time in UTC
    %         c is subclass
    %              r = rockfall
    %              e = lp-rockfall
    %              l = long period (lp)
    %              h = hybrid
    %              t = volcano-tectonic
    %              R = regional
    %              u = unknown
    %         MagE is equivalent magnitude, based on energy
    %         produced by the program ampengfft. These values come
    %         from magnitude database that formed part of a
    %         real-time alarm system, but these were deleted in June 2003.
    %
    %         A magnitude was
    %         computed for each event, assuming a location at sea
    %         level beneath the dome. Regardless of type. This was
    %         particularly helpful for understanding trends in
    %         cumulative energy for different types from week to
    %         week or month to month, and for real-time alarm
    %         messages about pyroclastic flow signals where an
    %         indication of event size was very important.

    debug.printfunctionstack('>')
    
    self = [];
    fprintf('\nAPPEND SEISAN %4d-%02d\n',yyyy,mm)
    datfile = fullfile(dirpath,sprintf('%4d%02d.dat',yyyy,mm));
    if exist(datfile,'file') 
        disp(['loading ',datfile]);
        [yr,mn,dd,hh,mi,ss,etype0,mag0] = textread(datfile,'%d %d %d %d %d %d %s %f');
        dnum = datenum(yr,mn,dd,hh,mi,ss)';
        mag = mag0';
        self = Catalog(dnum, [], [], [], mag, {}, etype0); 
    else
        disp([datfile,' not found']);
    end
    
    debug.printfunctionstack('<')

end
