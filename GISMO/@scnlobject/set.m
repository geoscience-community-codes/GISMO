function scnl = set(scnl, varargin)
%SET - Set properties for scnlobject
%       s = Set(s,prop_name, val, ...)
%       Valid property names:
%       'network', 'station', 'location', 'channel'
%
% VERSION: 2.0 of SCNLobject
% AUTHOR: Celso Reyes
% LASTUPDATE: 

argin_index = 1 : numel(varargin); %Vidx is the index for 'varargin'

while numel(argin_index) >= 2  % for each property
  prop_name = varargin{argin_index(1)};
  val = varargin{argin_index(2)};

  for n = 1 : numel(scnl); %for each scnlobject
    switch lower(prop_name)
      case {'station','location','network','channel'}
        if isa('val','cell') && numel(val) > 1
          val = val{1};
          warning('SCNLOBJECT:tooManyValues','Too many property values, only the first will be used');
        end
        if ~strcmp(prop_name,lower(prop_name))
           warning('SCNLOBJECT:set:propertyWarning',...
              'Use lowercase ''%s'' property name for consistency',lower(prop_name));
        end
        scnl(n).tag.(lower(prop_name)) = val;
      otherwise
    error('SCNLOBJECT:set:UnrecognizedProperty',...
      'Unrecognized property name : %s',  prop_name);
    end; %switch

  end; %each scnl
  argin_index(1:2) = []; % done with those parameters, move to the next ones...
end; %each property
