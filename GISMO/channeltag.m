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
      function chaTag = channeltag(N, S, L, C)
         % construct a channeltag from a string or 4 strings.
         % any of these may be empty ([] or '').
         %
         % chaTag = channeltag('IU', 'ANMO', '00', 'BHZ'); % net, sta, loc, cha
         % chaTag = channeltag('IU.ANMO.00.BHZ');
         %
         % to create multiple channeltags at once, use channeltag.array()
         
         % By removing the ability to create many at once, we ensure it won't
         % be done accidentally.
         %
         % See also: channeltag.array
         
         switch nargin
            case 4
               % inputsThatAreCells = cellfun(@iscell,{N,S,L,C});
               if any(cellfun(@iscell,{N,S,L,C}))
                  error('expected strings but received cells');
               end
               chaTag.network = N; 
               chaTag.station = S; 
               chaTag.location = L; 
               chaTag.channel = C;
            case 1
               if isa(N,'channeltag')
                  chaTag = N;
               else
               [chaTag.network, chaTag.station, ...
                  chaTag.location, chaTag.channel] = ...
                  channeltag.parsechaTag(N);
               end
            case 0
               return
            otherwise
               error ('CHANNELTAG:InvalidNumberOfInputs','Invalid number of arguments');
         end
      end
      
      function [IDX, cha_tags] = matching(cha_tags, N, S, L, C)
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
         
         if nargin == 2 && any(N=='.')
            % query used single string : 'net.sta.loc.cha'
            [N, S, L, C] = channeltag.parsechaTag(N);
         end
         IDX = true(size(cha_tags));
         if ~isempty(N)
            IDX = strcmp({cha_tags.network}, N);
         end
         if exist('S', 'var') && ~isempty(S)
            IDX = IDX & strcmp({cha_tags.station}, S);
         end
         if exist('L', 'var')  && ~isempty(L)
            IDX = IDX & strcmp({cha_tags.location}, L);
         end
         if exist('C', 'var') && ~isempty(C)
            IDX = IDX & strcmp({cha_tags.channel}, C);
         end
         if nargout == 2
            cha_tags = cha_tags(IDX);
         end
      end
      
      function [Y, I] = sort(cha_tags)
         % sort nscls in assending order by net.cha.loc.sta
         [~,I] = sort(cha_tags.fixedlengthstrings(5,5,5,5));
         Y = cha_tags(I);
      end
      
      function result = eq(chaTag, anythingelse)
         % expect that both parts are channeltags
         result = strcmp(chaTag.string,anythingelse.string);
      end%eq
      
      function result = ne(chaTag, anythingelse)
         result = ~strcmp(chaTag.string,anythingelse.string);
      end
      
      function stuff = get(chaTag, prop_name)
         %GET for the chaTag object
         %  result = get(channeltag, property), where PROPERTY is one of the
         %  following:
         %    STATION, CHANNEL, LOCATION, NETWORK, chaTag_STRING
         %
         % If the results of a single chaTag are requested, then a string is returned.
         % Otherwise, a cell of values will be returned.
         
         
         prop_name = lower(prop_name);
         
         switch prop_name
            
            case{'station','channel','network','location'}
               stuff = {chaTag.(prop_name)};
            case {'nscl_string'}
               %stuff = chaTag.string;
               warning('s = get(''nsclstring'') obsolete. Use s = chaTag.string(). notice the order switch.');
               stuff=strcat({obj.network},'_',{obj.station},'_',{obj.channel},'_',{obj.location});
            otherwise
               error('CHANNELTAG:UnrecognizedProperty',...
                  'Unrecognized property name : %s',  upper(prop_name));
         end
         
         %if a single chaTag, then return the string representation, else return a
         %cell of strings.
         if numel(stuff) == 1
            stuff = stuff{1};
         end
      end%get
      
      function chaTag = set(chaTag, varargin)
         %SET - Set properties for channeltag
         %       s = Set(s,prop_name, val, ...)
         %       Valid property names:
         %       STATION, LOCATION, NETWORK, CHANNEL
         
         Vidx = 1 : numel(varargin); %Vidx is the index for 'varargin'
         
         while numel(Vidx) >= 2  % for each property
            prop_name = varargin{Vidx(1)};
            val = varargin{Vidx(2)};
            switch upper(prop_name)
               case {'STATION','LOCATION','NETWORK','CHANNEL'}
                  if iscell(val) && numel(val) > 1
                     val = val{1};
                     warning('CHANNELTAG:tooManyValues','Too many property values, only the first will be used');
                  end
                  [chaTag.(lower(prop_name))]=deal(val);
               otherwise
                  error('CHANNELTAG:UnrecognizedProperty',...
                     'Unrecognized property name : %s',  upper(prop_name));
            end; %switch
            
            Vidx(1:2) = []; % done with those parameters, move to the next ones...
         end; %each property
      end
      
      function s = fixedlengthstrings(cha_tags, netLen, staLen, locLen, chaLen)
         strformat = sprintf('%%-%ds.%%-%ds.%%-%ds.%%-%ds',netLen,staLen,locLen,chaLen);
         for n = numel(cha_tags) : -1 : 1
            chaTag = cha_tags(n);
            s(n) = {sprintf(strformat,chaTag.network,chaTag.station,chaTag.location,chaTag.channel)};
         end
      end
      
      function s = string(chaTag, delim, option)
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
         if numel(chaTag) == 1
            s = getDelimitedString(chaTag);
         else
            if exist('option','var') && strcmpi(option,'nocell')
               s = '';
               for n=1 : numel(chaTag)
                  tmp = getDelimitedString(chaTag(n));
                  s(n,1:numel(tmp)) = tmp;
               end
            else
               s = cell(size(chaTag));
               for n=1 : numel(chaTag)
                  s(n) = {getDelimitedString(chaTag(n))};
               end
            end
         end
         
         function s = getDelimitedString(chaTag)
            s = [chaTag.network, delim, chaTag.station, delim,...
                     chaTag.location, delim, chaTag.channel];
         end
      end
      
      function res = validate(chaTag)
         % make sure channeltag roughly conforms to SEED
         nslc_is_char = [ischar(chaTag.network), ischar(chaTag.channel),...
             ischar(chaTag.station), ischar(chaTag.location)];
         nslc_valid_length = [numel(chaTag.network) == 2,...
            numel(chaTag.station) <= 5 && numel(chaTag.station) > 0, ...
            numel(chaTag.location) == 2, ...
            numel(chaTag.channel) == 3];
         res = all(nslc_is_char & nslc_valid_length);
      end
            
   end%methods
   
   methods(Static)
      function  [N, S, L, C] = parsechaTag(chaTagtextrep)
         % parsechaTag parses a period-delimeted string
         % [N, S, L, C] = channeltag.parsechaTag('net.sta.loc.cha')
               delims = find(chaTagtextrep == '.');
        
               if numel(delims) ~= 3
                  error('CHANNELTAG:parsechaTag:UnexpectedParam',...
                     'Expected ''NET.STA.LOC.CHA'' (using 3 "." delimeters)');
               end
               
               N = chaTagtextrep(1 : delims(1)-1);
               S = chaTagtextrep(delims(1)+1 : delims(2)-1);
               L = chaTagtextrep(delims(2)+1 : delims(3)-1);
               C = chaTagtextrep(delims(3)+1 : end);
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
                  error('CHANNELTAG:array:UnknownInput','expected cell of strings or a char array');
               end
            case 4
               % expect 1xN char OR arbitrary-sized CELL of 1xN char
               % if multiple cells, then they should all be same size
               N = varargin{1}; S = varargin{2}; L = varargin{3}; C = varargin{4};
               inputsThatAreCells = cellfun(@iscell,varargin);
               if any(inputsThatAreCells)
                  %make a cell array of N.S.L.C
                  A = strcat(N,'.',S,'.',L,'.',C);
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
         
         
         % 
      end %test
         
         
   end %static methods
end %classdef

