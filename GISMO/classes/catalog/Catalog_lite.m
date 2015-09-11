classdef Catalog_lite < Catalog_base
%CATALOG_LITE: A fast version of Catalog that does not support deeper
%classes such as EVENT, ORIGIN, MAGNITUDE, ARRIVAL etc.
% 
% Catalog_lite is modelled after the Catalog class, but is far faster to
% use in cases where there are large numbers of events to load
%
%% USAGE
%   cobj = Catalog_lite(lat, lon, depth, time, mag, etype)
%      where each input is a vector of the same size
%
%% EXAMPLE
% %
%   lat = [62.654 62.632 62.656];
%   lon = [-145.321 -145.318 -145.337];
%   depth = [2.4 2.9 3.7];
%   time = [datenum(2001,1,7,16,54,32) datenum(2001,1,7,16,55,35) ...
%   datenum(2001,1,7,17,13,12)];
%   mag = [1.4 1.8 1.5];
%   etype = 'tth';
%   cobj = Catalog_lite(lat, lon, depth, time, mag, etype);
%
%   This is a trivial example with only 3 origins. In general,
%   a Catalog_lite may contain tens of thousands of events. 
%                 
% 
%% See also CATALOG, EVENTRATE, READEVENTS, CATALOG_COOKBOOK
%
% Author: Glenn Thompson (glennthompson1971@gmail.com)
% $Date: $
% $Revision: $  
% 20141121 Glenn Thompson added write method to export to CSS3.0 origin
% table

    properties(GetAccess = 'public', SetAccess = 'public')
        % These cannot be defined in Catalog_base as could not then define
        % getters for them in Catalog
        lat;
        lon;
        depth;
        time;
        mag;
        etype;
    end
    methods
        function obj = Catalog_lite(lat, lon, depth, time, mag, etype, varargin)
            % Parse required, optional and param-value pair arguments,
            % set default values, and add validation conditions
            p = inputParser;
            p.addRequired('lat', @isnumeric);
            p.addRequired('lon', @isnumeric);
            p.addRequired('depth', @isnumeric);
            p.addRequired('time', @isnumeric);
            p.addRequired('mag', @isnumeric);
            p.addRequired('etype', @isstr);
            p.addParamValue('description', '', @isstr);
            p.parse(lat, lon, depth, time, mag, etype, varargin{:});
            fields = fieldnames(p.Results);
            for i=1:length(fields)
                field=fields{i};
                val = p.Results.(field);
                obj = obj.set(field, val);
            end
        end
         
        function cobj = plus(cobj1, cobj2)

            cobj = [];

            if nargin<2
                return
            end
            
            if isempty(cobj1)
                cobj = cobj2;
                return
            end
            
            if isempty(cobj2)
                cobj = cobj1;
                return
            end            

            if isempty(cobj1.time) & isempty(cobj2.time)
                return
            end

            if isempty(cobj1.time)
                cobj = cobj2;  
            elseif isempty(cobj2.time)
                cobj = cobj1;
            else
                cobj = cobj1; 
                props = {'time';'mag';'lat';'lon';'depth';'etype'};
                for i=1:length(props)
                    prop = props{i};
                    cobj.(prop) = [cobj1.(prop) cobj2.(prop)];
                end
            end
        end
        
        function write(cobj, dbpath)
            % Catalog_lite.write Write a Catalog object to an Antelope
            % CSS3.0 origin table
            
            % See if the database already exists
            db = dbopen(dbpath, 'r+');
            db = dblookup_table(db, 'origin')
            for i=1:numel(cobj.time)
                %db.record = i-1;
                db.record = dbaddnull(db);
                orid = dbnextid(db, 'orid');
                evid = dbnextid(db, 'evid');
                dbputv(db, 'orid', orid, 'evid', evid, 'time', datenum2epoch(cobj.time(i)), 'lat', cobj.lat(i), 'lon', cobj.lon(i), 'depth', cobj.depth(i), 'ml', cobj.mag(i));
            end
            dbclose(db)
        end
        
        function w=towaveform(obj)
             w{1,1} = waveform();
             if strcmp(get(obj,'method'), 'load_seisandb')
                % SEISAN FILE
                scnl = scnlobject('*', '*');
                ds = get(obj, 'datasource');
                sfile = get(obj, 'sfile');
                datestr([sfile.dnum])
                for k=1:numel([sfile.dnum])
                    wavfiles = {sfile(k).wavfiles};
                    yyyy = sfile(k).year;
                    mm = sfile(k).month;
                    dnum = sfile(k).dnum;
                    dbpath = get(obj, 'dbpath');
                    dbpath = strrep(dbpath, 'REA', 'WAV');
                    for i=1:numel(wavfiles)
                        wavpath = strtrim(fullfile(dbpath, sprintf('%04d', yyyy), sprintf('%02d', mm), wavfiles{i}));
                        if exist(wavpath, 'file')
                            %disp(sprintf('Loading %s',wavpath));
                            ds = datasource('seisan', wavpath);
                            w{k,i}=waveform(ds, scnl, dnum, dnum+300/86400);
                        else
                           disp(sprintf('Not found: %s',wavpath));
                        end
                    end         
                end
             end
        end
                
                
                
    end

end