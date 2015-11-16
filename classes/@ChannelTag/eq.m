
      function result = eq(A, B)
         %eq  equal for ChannelTags
         %expect that both parts are ChannelTags
         %
         % wildcards (simple '*' for fields) are automatically matched, so
         % be careful when comparing wildcards!
         %
         % empty fields are treated as intentionally empty.
         %
         % to ignore wildcards altogether, compare the fields individually!
         % 
         % Wildcards must be in a scalar.
         %
         % See also matching
         
         %either A or B is scholar, or they are same size
         %eq is called once for each A (tested Nov16,2015)
         assert(all(size(A)==size(B)) || numel(A)==1 || numel(B)==1,...
            'Size of A and B must be equal, unless either is a scalar');
         
         stamatches = comparefield({A.station}, {B.station});
         chamatches = comparefield({A.channel}, {B.channel});
         locmatches = comparefield({A.location}, {B.location});
         netmatches = comparefield({A.network}, {B.network});
         result = stamatches & chamatches & locmatches & netmatches;
         if numel(A) == 1
            result = reshape(result,size(B));
         else
            result = reshape(result,size(A));
         end
      end

      function matchIdx = comparefield(A,B)
         % any field 
         matchIdx = strcmp(A,B) | strcmp(A,'*') | strcmp(B,'*');
      end
