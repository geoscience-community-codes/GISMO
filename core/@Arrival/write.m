function write(self, outformat, outpath, varargin)
%WRITE Export Arrival object to disk

switch lower(outformat)

    case {'text','csv','xls'}
        writetable(self.table, outpath);

    case 'antelope'

        if ~admin.antelope_exists
            error('Antelope toolbox not available');
        end

        db = dbopen(outpath,'r+');
        dbar = dblookup_table(db,'arrival');

        for k = 1:height(self.table)

            ctag = ChannelTag(self.channelinfo{k});
            asta = ctag.station;
            achan = ctag.channel;

            atime = datenum2epoch(self.time(k));
            aarid = dbnextid(dbar,'arid');
            aiphase = self.iphase{k};

            if ~isnan(self.amp(k))
                aamp = self.amp(k);
            else
                aamp = -1;
            end

            dbar.record = dbaddnull(dbar);

            dbputv(dbar, ...
                'sta', asta, ...
                'time', atime, ...
                'arid', aarid, ...
                'chan', achan, ...
                'iphase', aiphase, ...
                'amp', aamp);
        end

        dbclose(db);

    case 'seisan'
        Arrival.create_sfiles(self, outpath);

    otherwise
        error('Unsupported format');
end
end
