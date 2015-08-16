classdef channeltag
   %channeltag Summary of this class goes here
   % channeltag is the class that holds the network, station, location, and channel for a seismic trace
   %
   % This rewrite is designed to be better SEED compatible
   %
   %  chaTag = channeltag('NW.STA.LO.CHA'); % create from text
   %  chaTag = channeltag(network, station, location, channel);
   %  chaTag = channeltag(); %default, blank nscl
   %
   %  To initialize multiple channeltags at once, use channeltag.array:
   %
   %  Example using cells of stationID strings
   %    x = channeltag.array({'NW.STA.LO.CHA','NW.STA.LO.CHA'[,...]});
   %
   %  Example using individual parts
   %    cha_tags = channeltag.array({'IU','ANMO','00',{'BHZ','BH1','BH2'});
   %
   %  note, an array of cha_tags may be created by including cell arrays of
   %  choices. However, all cells that contain multiple strings must be the
   %  same size and shape.
   %
   %  OK: x = channeltag.array('IU',{'ANMO','ANTO},'00',{'BHE','BH1'}
   %        results in IU.ANMO.00.BHE & IU.ANTO.00.BH1
   %
   %  NOTOK: x = channeltag.array('IU',{'ANMO','ANTO},'00',{'BHE';'BH1'}
   %        error because stations (1x2) not same size as channels (2x1)
   %
   %
   %  NOTE: WILDCARDS,  NOT IMPLEMENTED as of 2015-07-31!!!!!
   
   %{
   %  ----------- WILDCARDS --------------------- 
   %  channeltag is merely a storage unit for net-sta-chan-loc information. It
   %  is blind to wildcards. However, when used as an argument in WAVEFORM,
   %  wildcards in the channeltag take on meaning that depends somewhat on the
   %  DATASOURCE type. In most cases, * wildcards are understood without
   %  issue. Note that '*' differs from ''. The latter excludes this term from
   %  the search altogether. Station and channel cannot be excluded from the
   %  search.
   %
   %  channeltag('R*','BHZ','XE','') match all stations begining with R
   %  channeltag('MCK','*','XE','')  match all channels for MCK
   %  channeltag('R*','*','XE','')   all R* stations. All channels
   %
   %  The uses above have been tested against Antelope data sources. Note that
   %  in Antelope it would be more common to use the literal wildcards 'R.*'
   %  or '.*'. When waveform interprets channeltags, it considers these use
   %  the same.
   %
   % EXAMPLE:
   %   s={'ANMO','ANTO'} , n='IU' , L='00' , c={'BHZ,BHE'}
   %   chaTag=channeltag(s,c,n,L); %  returns a 1x2 channeltag:
   %    chaTag(1) contains ANMO, IU, 00, BHZ
   %    chaTag(2) contains ANTO, IU, 00, BHE
   %}
   
   % Programming notes:
   %   This is intended as a stand-alone class. It should know nothing about
   %   any other waveform class.
   
   % Backwards compatibility notes:
   %   The old SCNLOBJECT class will use this behind the scenes. Hopefully
   %   it will be easier to convert code when SNCLOBJECT is producing the
   %   appropriate warning messages.
   
   properties
      network  = '';
      station  = '';
      location = '';
      channel  = '';
   end
   
   properties (Constant=true)
      ENFORCE_SEED_COMPLIANCE = getpref('gismo','seed_compliant',false); % currently unused
   end
   
   properties (Access=protected)
      % bulkIsValid = @(x) ischar(x)|| (iscell(x) && all(cellfun(@ischar,x)) );
   end
   
   methods
      function obj = channeltag(varargin)
         % construct a channeltag from a string or 4 strings.
         % chaTag = channeltag('IU', 'ANMO', '00', 'BHZ'); % net, sta, loc, cha
         % chaTag = channeltag('IU.ANMO.00.BHZ');
         %
         % any of these may be empty ([] or '').
         % to create multiple channeltags at once, use channeltag.array()
         %
         % See also: channeltag.array
         
         % By removing the ability to create many at once, we ensure it won't
         % be done accidentally.
         
         switch nargin
            case 4
               % inputsThatAreCells = cellfun(@iscell,{N,S,L,C});
               % if any(cellfun(@iscell,{N,S,L,C}))
               if any(cellfun(@iscell,varargin))
                  error('channeltag:InvalidConversion',...
                     ['expected strings but received cells.\n', ...
                     'To create multiple channeltags, use channeltag.array()']);
               end
               varargin = strtrim(varargin);
               [obj.network, obj.station, obj.location, obj.channel] = deal(varargin{:});
            case 1
               inObj = varargin{1};
               switch class(inObj)
                  case 'channeltag'
                     obj = inObj;
                  case {'char','struct'}
                     if size(inObj,1) == 1
                     [obj.network, obj.station, obj.location, obj.channel] = ...
                        channeltag.parse(inObj);
                     else
                        error('channeltag:InvalidConversion',...
                           'To create multiple channeltags, use channeltag.array()');
                     end
                        
                  case 'cell'
                     if numel(inObj) == 1
                        [obj.network, obj.station, obj.location, obj.channel] = ...
                           channeltag.parse(inObj{1});
                     else
                        error('channeltag:InvalidConversion',...
                           'To create multiple channeltags, use channeltag.array()');
                     end
                  otherwise
                     error ('channeltag:InvalidConversion','Invalid number of arguments');
               end
               
            case 0
               return
            otherwise
               error ('channeltag:InvalidConversion','Invalid number of arguments');
         end
      end
      
      function [IDX, objs] = matching(objs, N, S, L, C)
         % matching does field-by-field comparison
         %
         % idx = cha_tags.matching(Net, Sta, Loc, Cha);
         % idx = cha_tags.matching('net.sta.loc.cha');
         % returns an index vector the same size as cha_tags
         % [idx, matched] = cha_tags.matching(...)
         %   additionally returns the actual matching cha_tags
         %
         % so, cha_tags(matches) will return the actual values
         % use [] or '' as wildcard
         %  either:
         %    cha_tags.matching('IU','ANMO',[],'BHZ')   or
         %    cha_tags.matching('IU.ANMO..BHZ') 
         % will match BOTH
         %   'IU.ANMO.00.BHZ' and 'IU.ANMO.01.BHZ'
         if nargin == 2
            if (ischar(N) && any(N == '.')) || isa(N,'channeltag')
               % query used single string : 'net.sta.loc.cha'
               [N, S, L, C] = channeltag.parse(N);
            else
               error('CHANNELTAG:matching:UnknownMatchType','don''t know how to match it');
            end
         end
         IDX = true(size(objs));
         if ~isempty(N) && all(N ~= '*')
            IDX = strcmp({objs.network}, N);
         end
         if exist('S', 'var') && ~isempty(S) && all(S ~= '*')
            IDX = IDX & strcmp({objs.station}, S);
         end
         if exist('L', 'var')  && ~isempty(L) && all(L ~= '*')
            IDX = IDX & strcmp({objs.location}, L);
         end
         if exist('C', 'var') && ~isempty(C) && all(C ~= '*')
            IDX = IDX & strcmp({objs.channel}, C);
         end
         if nargout == 2
            objs = objs(IDX);
         end
      end
      
      function [Y, I] = sort(cha_tags)
         % sort nscls in assending order by net.cha.loc.sta
         [~,I] = sort(cha_tags.fixedlengthstrings(5,5,5,5));
         Y = cha_tags(I);
      end
      
      function result = eq(A, B)
         % expect that both parts are channeltags
         result = strcmp(A.string(), B.string());
      end%eq
      
      function result = ne(A, B)
         result = ~strcmp(A.string,B.string);
      end
      
      function val = get(obj, prop)
         %GET for the chaTag object
         %  result = get(channeltag, property), where PROPERTY is one of the
         %  following:
         %    STATION, CHANNEL, LOCATION, NETWORK, chaTag_STRING
         %
         % If the results of a single chaTag are requested, then a string is returned.
         % Otherwise, a cell of values will be returned.
         
         
         prop = lower(prop);
         
         switch prop
            case{'station','channel','network','location'}
               val = {obj.(prop)};
            case {'nscl_string'}
               %stuff = chaTag.string;
               warning('CHANNELTAG:get:obsoleteUsage',...
                  ['get(''nsclstring'') obsolete. Use chaTag.string().\n'...
                  '  notice it will return N.S.L.C instead of N_S_C_L']);
               val=strcat({obj.network},'_',{obj.station},'_',{obj.channel},'_',{obj.location});
            otherwise
               error('CHANNELTAG:get:UnrecognizedProperty',...
                  'Unrecognized property name : %s',  upper(prop));
         end
         
         %if a single chaTag, then return the string representation, else return a
         %cell of strings.
         if numel(val) == 1
            val = val{1};
         else
            val = reshape(val,size(obj));
         end
      end%get
      
      function obj = set(obj, varargin)
         %SET - Set properties for channeltag
         %       s = Set(s,prop_name, val, ...)
         %       Valid property names:
         %       STATION, LOCATION, NETWORK, CHANNEL
         
         idx = [1 2];
         while numel(varargin) > 1 % for each property
            [prop, val] = deal(varargin{idx});
            varargin(idx) = []; % remove the prop and val
            switch upper(prop)
               case {'STATION','LOCATION','NETWORK','CHANNEL'}
                  if iscell(val) && numel(val) > 1
                     val = val{1};
                     warning('channeltag:set:TooManyValues',...
                        'Too many property values, only the first will be used');
                  end
                  [obj.(lower(prop))] = deal(val);
               otherwise
                  error('channeltag:set:UnrecognizedProperty',...
                     'Unrecognized property name : %s',  upper(prop));
            end; %switch
         end; %each property
         if ~isempty(varargin)
            error('channeltag:set:PropertyValueMismatch',...
               'Each property should have a value. [%s] has no matching value', varargin{1});
         end
      end
      
      function s = fixedlengthstrings(objs, netLen, staLen, locLen, chaLen)
         strformat = sprintf('%%-%ds.%%-%ds.%%-%ds.%%-%ds',netLen,staLen,locLen,chaLen);
         for n = numel(objs) : -1 : 1
            chaTag = objs(n);
            s(n) = {sprintf(strformat,chaTag.network,chaTag.station,chaTag.location,chaTag.channel)};
         end
      end
      
      function c = char(obj)
         c = obj.string([],'nocell');
      end
         
      function s = string(obj, delim, option)
         % string returns string representation of the nscltag(s)
         % s = chaTag.string()  will return the string representation 
         %      (1xn char) in the format NET.STA.LOC.CHA
         %
         % s = chaTag.string(DELIM) will use DELIM to separate
         %     fields.
         %     ex.  chaTag.string('-'); will return NET-STA-LOC-CHA
         %
         % If chaTag is an array, then results are returned as a 
         % a cell of strings of same shape as chaTag will be returned.
         %
         % s = chaTag.string(DELIM,'nocell') to overrides functionality
         % to return a padded NxM char array
         % if DELIM is empty, then '.' will be used.
         if ~exist('delim','var') || isempty(delim)
            delim = '.';
         end
         if numel(obj) == 1
            s = getDelimitedString(obj, delim);
         else
            if exist('option','var') && strcmpi(option,'nocell')
               s = '';
               for n=1 : numel(obj)
                  tmp = getDelimitedString(obj(n), delim);
                  s(n,1:numel(tmp)) = tmp;
               end
            else
               s = cell(size(obj));
               for n=1 : numel(obj)
                  s(n) = {getDelimitedString(obj(n), delim)};
               end
            end
         end
         
         function s = getDelimitedString(obj, delim)
            s = [obj.network, delim, obj.station, delim,...
                     obj.location, delim, obj.channel];
         end
      end
      
      function res = validate(obj)
         % make sure channeltag roughly conforms to SEED
         nslc_is_char = [ischar(obj.network), ischar(obj.channel),...
             ischar(obj.station), ischar(obj.location)];
         nslc_valid_length = [numel(obj.network) == 2,...
            numel(obj.station) <= 5 && numel(obj.station) > 0, ...
            numel(obj.location) == 2, ...
            numel(obj.channel) == 3];
         res = all(nslc_is_char & nslc_valid_length);
      end
            
   end%methods
   
   methods(Static)
      function  [N, S, L, C] = parse(val)
         % parse parses a period-delimeted string
         % [N, S, L, C] = channeltag.parse('net.sta.loc.cha')
         if isstruct(val) || isa(val,'channeltag')
            N = val.network;
            S = val.station;
            L = val.location;
            C = val.channel;
         elseif ischar(val)
            % test validity, then split.  in R2015a+ strsplit() could do
            % this. But, this is being designed on R2012a.
            parts =  strsplit(val, '.');
            if numel(parts) ~= 4
               error('channeltag:parse:InvalidFieldCount',...
                  'Expected ''A.B.C.D'' (4 fields), but received %d.', numel(parts));
            end
            if any(val == ' '), 
               parts = strtrim(parts); 
            end
            [N, S, L, C] = deal(parts{:});
         else
            error('channeltag:parse:UnknownClass',...
               'unknown how to parse: %s', class(val));
         end
         
         function  C = strsplit(s, delim)
            % C = strsplit(str, delim) returns cell created from string
            %  ex. C = strsplit('A.B..D','.') -> {'A', 'B', '', 'D'}
            % can (probably) be commented out or removed in r2015a+
            splitpts = find(s == delim);
            starts = [1, splitpts+1];
            ends = [splitpts-1, numel(s)];
            C = cell(1,numel(starts));
            for n = 1:numel(starts)
               C(n) = {s(starts(n):ends(n))};
            end
         end
      end
      
      function cha_tags = array(varargin)
         % chaTag.array creates multiple channeltags from the input.
         % cha_tags = chaTag.array({'NET.STA.LOC.CHA','NET2.STA2..CH2'[,...]})
         % cha_tags = chaTag.array(Net/list, Sta/list, Loc/list, Cha/list)
         switch nargin
            case 0
               % return an empty nscltag array
               cha_tags = channeltag('...');
               cha_tags(:)=[];
            case 1
               % parse a cell array of stations. OR parse an NxM char, where
               % each row is NET.STA.LOC.CHA
               if iscell(varargin{1})
                  for n = numel(varargin{1}) : -1 : 1
                     cha_tags(n) = channeltag(varargin{1}{n});
                  end
                  cha_tags = reshape(cha_tags,size(varargin{1}));
               elseif ischar(varargin{1})
                  char_array = varargin{1};
                  nRows = size(char_array,1);
                  for n = nRows : -1 : 1
                     cha_tags(1,n) = channeltag(strtrim(char_array(n,:)));
                  end
               else
                  error('channeltag:array:UnknownInput','expected cell of strings or a char array');
               end
            case 4
               % expect 1xN char OR arbitrary-sized CELL of 1xN char
               % if multiple cells, then they should all be same size
               inputsThatAreCells = cellfun(@iscell,varargin);
               if any(inputsThatAreCells)
                  %make a cell array of N.S.L.C
                  A = strcat(varargin{1},'.',varargin{2},'.',varargin{3},'.',varargin{4});
               end
               for n = numel(A): -1 : 1
                  cha_tags(n) = channeltag(A{n});
               end
         end
      end
      
      function test()
         % default channeltag
         c = channeltag();
         assert(strcmp(c.network,'') && strcmp(c.station,'')...
            && strcmp(c.location,'') && strcmp(c.channel,''))
         % copy
         c(2) = channeltag();
         assert(c(1) == c(2)) % test eq for an empty channeltag
         % check array creation
         c1 = channeltag();
         c1.network = 'N1'; c1.station = 'S1'; c1.location = 'L1'; c1.channel = 'C1';
         c2 = c1;
         c2.network = 'N2'; c2.station = 'S2'; c2.location = 'L2'; c2.channel = 'C2';
         assert(c2 ~= c1)
         tags_fieldcells = channeltag.array({'N1','N2'},{'S1','S2'},{'L1','L2'},{'C1','C2'});
         tags_textcells = channeltag.array({'N1.S1.L1.C1','N2.S2.L2.C2'});
         tags_textarray = channeltag.array(['N1.S1.L1.C1';'N2.S2.L2.C2']);
         assert(tags_fieldcells(1) == c1)  
         assert(tags_textcells(1) == c1)
         assert(tags_textarray(1) == c1)
         assert(tags_fieldcells(2) == c2)
         assert(tags_textcells(2) == c2)
         assert(tags_textarray(2) == c2)
         
         c = channeltag.array('N',{'S1','S2'},'L',{'C1','C2'});
         assert(numel(c) == 2)
         assert(strcmp(c(2).station,'S2') && strcmp(c(2).channel,'C2')...
            && strcmp([c.network], 'NN') && strcmp([c.location], 'LL'))
         tags = channeltag.array('NW','STA1','00', {'A','B','C','D'});
         tags2 = channeltag.array('NW','STA1','00', {'F','C','A','E'});
         sortedtags = sort(tags2);
         assert(sortedtags(1).channel == 'A' && sortedtags(4).channel == 'F')
         % ismember 
         assert(ismember(channeltag('NW.STA1.00.B'), tags));
         
      end %test
         
         
   end %static methods
end %classdef

