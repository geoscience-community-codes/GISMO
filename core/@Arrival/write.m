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
            %write(catalogObject.table, outpath);
            write(arrivalObject.table, outpath);
        case 'seisan'
            create_sfiles(arrivalObject, outpath)
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

function create_sfiles(arrivalObject, outpath)
% SCAFFOLD: a draft function to save arrivals to a Seisan S-file
% Normally this would happen at the Catalog level. We would associate
% arrivals and waveforms with each event in a Catalog
% but if we first autoreg the WAV files into a new Seisan database,
% this creates S-files with the following lines:

    % fprintf('2011 1231  817 58.9 L                                                         1');
    % fprintf('ACTION:ARG 18-08-25 16:44 OP:gt   STATUS:               ID:20111231081758     I');
    % fprintf('2011-12-31-081758-TBTN-BHZ.sac                                                6');
    % fprintf('STAT SP IPHASW D HRMM SECON CODA AMPLIT PERI AZIMU VELO AIN AR TRES W  DIS CAZ7');

% and then all we need to is add one line per arrival

% fprintf('TBHY BZ IP       2040 4.428                             106     0.110 4.20 224 ');
% fprintf('TBTN BZ IP       2040 3.653                             109    -0.710 4.23 239 ');

thisA = arrivalObject;
N = numel(thisA.time);

% SCAFFOLD: identify correct S-file and open it for writing as SFILEPTR
mintime = min(thisA.time);
sfiledummy = datestr(mintime,'dd-HH-MM-SS.dummysfile');
SFILEPTR = fopen(fullfile(SFILEPATH,sfiledummy), 'a');

if N>0
    for arrnum = 1:N
        ctag = ChannelTag(thisA.channelinfo{arrnum});
        asta = ctag.station;
        atime = datenum2epoch(thisA.time(arrnum));
        achan = ctag.channel;
        achan = sprintf('%c%c',achan(1),achan(3));
        aiphase = thisA.iphase{arrnum};
        adv = datevec(atime);
        try
            aamp = thisA.amp(arrnum);
            %aper = thisA.per(arrnum);
            %asnr = thisA.snr(arrnum);
        catch
            aamp = -1;
        end
        
        % add arrival row
        fprintf(SFILEPTR, ' '); % 1 is free
        fprintf(SFILEPTR, '%5c', asta); % station is 2-6
        fprintf(SFILEPTR, '%2c', achan); % component is 7-8
        fprintf(SFILEPTR, ' '); % 9 is free
        fprintf(SFILEPTR, 'I'); % quality indicator 'I' or 'E' is 10
        fprintf(SFILEPTR, '%4c', aiphase); % phase ID is 11-14
        fprintf(SFILEPTR, ' '); % weighting is 15
        fprintf(SFILEPTR, ' '); % free or flag A for automatic pick
        fprintf(SFILEPTR, ' '); % first motion is 17
        fprintf(SFILEPTR, ' '); % 18 is free
        fprintf(SFILEPTR, '%2d', adv(4)); % hour is 19-20
        fprintf(SFILEPTR, '%2d', adv(5)); % minute is 21-22
        fprintf(SFILEPTR, '%6.0f', adv(6)); % second is 23-28
        fprintf(SFILEPTR, ' '); % 29 is free
        fprintf(SFILEPTR, '%4d',0); % duration is 30-33
        fprintf(SFILEPTR, '%7.1f',aamp); % amplitude is 34-40 in nm/s
        fprintf(SFILEPTR, ' '); % 41 is free
        fprintf(SFILEPTR, '    '); % 42-45 is period in s
        fprintf(SFILEPTR, ' '); % 46 is free
        fprintf(SFILEPTR, '     '); % direction of approach, degrees, 47-51
        fprintf(SFILEPTR, ' '); % 52 is free       
        fprintf(SFILEPTR, '    '); % phase velocity km/s, 53-56   
        fprintf(SFILEPTR, '    '); % angle of incidence, 57-60
        fprintf(SFILEPTR, '   '); % azimith residual, 61-63
        fprintf(SFILEPTR, '     '); % travel time residual, 64-68
        fprintf(SFILEPTR, '  '); % weight, 69-70
        fprintf(SFILEPTR, '     '); % travel time residual, 71-75
        fprintf(SFILEPTR, ' '); % 76 is free
        fprintf(SFILEPTR, ' '); % 77-79 azimuth at source
        fprintf(SFILEPTR, '4'); % 80 is either type '4' or blank
        fprintf(SFILEPTR, '\n\n'); % type 4 line is followed by a blank line
    end
end
fclose(SFILEPTR);

end
