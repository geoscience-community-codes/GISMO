function stuff = get(scnl, prop_name);
%GET for the scnl object
%  result = get(scnlobject, property), where PROPERTY is one of the
%  following:  
%    STATION, CHANNEL, LOCATION, NETWORK, NSCL_STRING
%
% If the results of a single SCNL are requested, then a string is returned.
% Otherwise, a cell of values will be returned.


prop_name = lower(prop_name);

switch prop_name
    
    case{'station','channel','network','location'}
        stuff = {scnl.(prop_name)};
    case{'nscl_string'}
        for n = 1:numel(scnl)
            stuff(n) = {[ scnl(n).network '_' scnl(n).station '_' scnl(n).channel '_' scnl(n).location ]};
        end
    otherwise
        error('SCNL:UnrecognizedProperty',...
            'Unrecognized property name : %s',  upper(prop_name));
end

%if a single scnl, then return the string representation, else return a
%cell of strings.
if numel(stuff) == 1
    stuff = stuff{1};
else
    stuff = reshape(stuff,size(scnl));
end;
