function [results, loc] = ismember(scnlA,scnlB)
%ISMEMBER for scnlobjects
% TRUE for each waveform that matches any scnl in the anythingelse array.
%
% see also ISMEMBER

% since we are looking for scnlA in scnlB, then scnlB may have wildcards.
% the wildcard is a field value of '*' (only).  These haven't been
% thoroughly tested.

wildcard = '*';
if isempty(scnlA) | isempty(scnlB)
  results = [];
  loc = [];
  return
end

%try

%catch
  if ~isa(scnlA,'scnlobject') || ~isa(scnlB,'scnlobject')
    if ~isa(scnlA,'scnlobject'), anythingelse = class(scnlA), end
    if ~isa(scnlB,'scnlobject'), anythingelse = class(scnlB), end
    error('scnlobject:ismemberMismatch',...
      'scnlobject does not know how to determine if it is a member of a %s',...
      anythingelse);
  end
  %rethrow(lasterror);
%end
results = false(size(scnlA));
loc = zeros(size(scnlA));
for i=1:numel(scnlB)
  theseA = scnlA;
  if strcmpi(scnlB(i).station,wildcard)
    theseA = set(theseA,'station',wildcard);
  end
  if strcmpi(scnlB(i).channel,wildcard)
    theseA = set(theseA,'channel',wildcard);
  end
  if strcmpi(scnlB(i).network,wildcard)
    theseA = set(theseA,'network',wildcard);
  end  
  if strcmpi(scnlB(i).location,wildcard)
    theseA = set(theseA,'location',wildcard);
  end
  [resultstmp, loctmp] = ismember(getSearchString(theseA),getSearchString(scnlB));
  results = results | resultstmp;
  loc(loc==0) = loctmp(loc==0);
end  
  
function ss = getSearchString(scnl)
sta = get(scnl,'station'); 
if ~iscell(sta), 
  sta = {sta}; 
end;
sta(strcmpi(sta,'')) = {'*-noStation-*'};
cha = get(scnl,'channel'); 
if ~iscell(cha), cha = {cha}; end;
cha(strcmpi(cha,'')) = {'*-noChannel-*'};
net = get(scnl,'network');
if ~iscell(net), net = {net}; end;
net(strcmpi(net,'') | strcmpi(net,'--')) = {'*-noNetwork-*'};
loc = get(scnl,'location');
if ~iscell(loc), loc = {loc}; end;
loc(strcmpi(loc,'') | strcmpi(loc,'--')) = {'*-noLocation-*'};

ss = strcat(sta,'|',cha,'|', net,'|',loc);