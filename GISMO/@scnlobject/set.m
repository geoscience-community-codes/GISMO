function scnl = set(scnl, varargin)
%SET - Set properties for scnlobject
%       s = Set(s,prop_name, val, ...)
%       Valid property names:
%       STATION, LOCATION, NETWORK, CHANNEL
%
% VERSION: 1.0 of SCNLobject
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 11/20/2008

Vidx = 1 : numel(varargin); %Vidx is the index for 'varargin'

while numel(Vidx) >= 2  % for each property
  prop_name = varargin{Vidx(1)};
  val = varargin{Vidx(2)};

  for n = 1 : numel(scnl); %for each scnlobject
    switch upper(prop_name)
      case {'STATION','LOCATION','NETWORK','CHANNEL'}
        if isa('val','cell') && numel(val) > 1
          val = val{1};
          warning('SCNL:tooManyValues','Too many property values, only the first will be used');
        end
        scnl(n).(lower(prop_name)) = val;
      otherwise
    error('SCNL:UnrecognizedProperty',...
      'Unrecognized property name : %s',  upper(prop_name));
    end; %switch

  end; %each scnl
  Vidx(1:2) = []; % done with those parameters, move to the next ones...
end; %each property