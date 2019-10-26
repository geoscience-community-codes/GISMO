function write(detectionObject, outformat, outpath, varargin)
    %DETECTION.WRITE Write a Detection object to disk
    %
    % detectionObject.write('antelope', 'mydb', 'css3.0') writes the
    % detectionObject to a CSS3.0 database called 'mydb' using
    % Antelope. Requires Antelope and Antelope Toolbox. 
    % 
    % Support for other output formats, e.g. Seisan, will be added
    % later.

    % Glenn Thompson, 15 August 2018

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
                    tableNames = {'detection'};
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
                dbdet = dblookup_table(db,'detection');
                
                thisD = detectionObject;
                N = numel(thisD.time);

                if N>0
                    for detnum = 1:N
                        ctag = ChannelTag(thisD.channelinfo{detnum});
                        dsta = ctag.station;
                        dtime = datenum2epoch(thisD.time(detnum));    
                        %darid = dbnextid(dbdet,'arid');
                        dchan = ctag.channel;
                        dstate = thisD.state{detnum};
                        dfilterstring = thisD.filterString{detnum}; 
                        try
                        dsnr = thisD.signal2noise(detnum);
                        catch
                            dsnr = -1;
                        end

                        % add detection row
                        dbdet.record = dbaddnull(dbdet);
                        dbputv(dbdet, 'sta', dsta, ...
                            'chan', dchan, ...                            
                            'time', dtime, ...
                            'state', dstate, ...
                            'filter', dfilterstring, ...
                            'snr', dsnr);                 
                    end
                end
                dbclose(db);
                disp('(Complete)');
            end
        otherwise,
            warning('format not supported yet')
    end % end switch
end % function
