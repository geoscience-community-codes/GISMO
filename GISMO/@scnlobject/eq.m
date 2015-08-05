function results = eq(A, B)
   % when using wildcards, use ismember
   switch class(B)
      case 'scnlobject'
         results = [A.tag] == [B.tag];
      case 'channeltag'
         results = [A.tag] == [B];
      otherwise
         error('scnlobject:eq:UnrecognizedComparison',...
            'Don''t know how to compare scnlobject with %s\n',class(B));
   end
end
