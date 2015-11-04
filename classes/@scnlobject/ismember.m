function [results, loc] = ismember(A,B)
   %ISMEMBER for scnlobjects
   % TRUE for each waveform that matches any scnl in the anythingelse array.
   %
   % see also ISMEMBER
   %
   % WILDCARD is not implemented
   %
   % since we are looking for scnlA in scnlB, then scnlB may have wildcards.
   % the wildcard is a field value of '*' (only).  These haven't been
   % thoroughly tested.
   
   wildcard = '*';
   if isempty(A) || isempty(B)
      results = [];
      loc = [];
      return
   end
   
   assert(isa(A,'scnlobject'),class(A))
   tagA = toTag(A);
   tagB = toTag(B); 
   [results, loc] = ismember(tagA, tagB);
   return
   
   results = false(size(A));
   loc = zeros(size(A));
   for i=1:numel(B)
      theseA = A;
      if strcmpi(B(i).station,wildcard)
         theseA = set(theseA,'station',wildcard);
      end
      if strcmpi(B(i).channel,wildcard)
         theseA = set(theseA,'channel',wildcard);
      end
      if strcmpi(B(i).network,wildcard)
         theseA = set(theseA,'network',wildcard);
      end
      if strcmpi(B(i).location,wildcard)
         theseA = set(theseA,'location',wildcard);
      end
      [resultstmp, loctmp] = ismember(getSearchString(theseA),getSearchString(B));
      results = results | resultstmp;
      loc(loc==0) = loctmp(loc==0);
   end
end
function t = toTag(scnls)
   
   switch class(scnls)
      case 'scnlobject'
         t = [scnls.tag];
      case 'ChannelTag'
         t = [scnls];
      otherwise
         %try to convert it?
         t = ChannelTag(scnls);
   end
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
end
