function write(arrivalObject, outformat, outpath, varargin)
    %ARRIVAL.WRITE Write an Arrival object to disk
    %
    % arrivalObject.write('antelope', 'mydb', 'css3.0') writes the
    % arrivalObject to a CSS3.0 database called 'mydb' using
    % Antelope. Requires Antelope and Antelope Toolbox. Support for
    % aefsam0.1 schema will be added later.
    % 
    % Support for other output formats, e.g. Seisan, will be added
    % later.

    % Glenn Thompson, 4 February 2015

    switch outformat
        case {'text';'csv';'xls'} % help table.write for more info
            write(catalogObject.table, outpath);

        case 'antelope'


            if admin.antelope_exists

                dbpath = outpath;

                % create new db
                if ~exist('schema','var')
                    schema='css3.0';
                end
                antelope.dbcreate(dbpath, schema);

                % remove the following tables if they exist and mode is
                % "overwrite"
                if nargin==4 & strcmp(varargin{1},'overwrite')
                    tableNames = {'arrival'};
                    for tablenum = 1 : numel(tableNames)
                        thisTable = sprintf('%s.%s',dbpath,tableNames{tablenum});
                        if exist(thisTable, 'file')
                            if nargin>=4
                                if strcmp(varargin{1},'overwrite')
                                    fprintf('Overwrite mode: Removing %s\n',thisTable);
                                    delete(thisTable);
                                else
                                    % for 'append' mode, nothing to do
                                    fprintf('Append mode: You will append to %s\n',thisTable);
                                end
                            else
                                % nothing specified, so force user to
                                % choose, as we never want to mess up
                                % existing tables or delete them without
                                % user input
                                choice = input(sprintf('delete %s (y/n)',thisTable),'s');
                                if lower(choice(1)=='y')
                                    fprintf('Overwrite mode: Removing %s\n',thisTable);
                                    delete(thisTable);
                                end
                            end
                        end
                    end
                end
%                 system(sprintf('touch %s.event',dbpath));
%                 system(sprintf('touch %s.origin',dbpath));
                

                disp('Writing new rows...');

                % open db
                db = dbopen(dbpath, 'r+');
                dbar = dblookup_table(db,'arrival');
                
                thisA = arrivalObject;
                N = numel(thisA.time);

                if N>0
                    for arrnum = 1:N
                        ctag = ChannelTag(thisA.channelinfo{arrnum});
                        asta = ctag.station;
                        atime = datenum2epoch(thisA.time(arrnum));    
                        aarid = dbnextid(dbar,'arid');
                        achan = ctag.channel;
                        aiphase = thisA.iphase{arrnum}; 
                        try
                        aamp = thisA.amp(arrnum);
                        %aper = thisA.per(arrnum);
                        %asnr = thisA.snr(arrnum);
                        catch
                            aamp = -1;
                        end

                        % add arrival row
                        dbar.record = dbaddnull(dbar);
                        dbputv(dbar, 'sta', asta, ...
                            'time', atime, ...
                            'arid', aarid, ...
                            'chan', achan, ...
                            'iphase', aiphase, ...
                            'amp', aamp);
                            %'per', aper, ...
                            %'snr', asnr, ...                  
                    end
                end
                dbclose(db);
                disp('(Complete)');
            end
        otherwise,
            warning('format not supported yet')
    end % end switch
end % function
