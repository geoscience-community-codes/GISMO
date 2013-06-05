function match = compare_sst(sst_1,sst_2)
%
%COMPARE_SST: This is a work in progress
%
%USAGE: results = compare_sst(sst_1,sst_2)
%
%INPUTS: sst_1, sst_2
%
%OUTPUTS: match
%
% See also ADD_SST, CHK_T, COMPARE_SST, DELETE_SST, EXTRACT_SST, IS_SST,  
%          ISTEQUAL, MERGE_SST, SEARCH_SST, SORT_SST, NAN2SST, SSD2SST,  
%          SST2NAN, SST2SSD, SST2VAL, SST2WFA, WFA2SST
%
% Author: Dane Ketner, Alaska Volcano Observatory
% $Date$
% $Revision$

l1 = size(sst_1,1);
l2 = size(sst_2,1);

n1 = 1;
n2 = 1;

ce1 = sst_1(n1,:);
ce2 = sst_2(n2,:);

done = 0;
match = [];

% Short Hand: A __ B
% NL - A is Left of B w/ No Overlap    A----A  B----B
% NR - A is Right of B w/ No Overlap   B----B  A----A
% OL - A Overlaps B From Left Side     A--B------A--B
% OR - A Overlaps B From Right Side    B--A------B--A
% OI - A Overlaps & is Inside of B     B--A------A--B
% OO - A Overlaps & is Outside of B    A--B------B--A

while done == 0
   if ce1(2) <= ce2(1)
      % ce1 NL ce2
      n1 = n1+1;
   elseif ce1(1) >= ce2(2)
      % ce1 NR ce2
      n2 = n2+1;
   elseif ce1(1) < ce2(1) && ce1(2) > ce2(1) && ce1(2) < ce2(2)
      % ce1 OL ce2
      d1 = ce1(2)-ce1(1);
      d2 = ce2(2)-ce2(1);
      od = ce1(2)-ce2(1);
      match = [match; n1 n2 d1 d2 od];
      n1 = n1 + 1;
   elseif ce1(1) > ce2(1) && ce1(1) < ce2(2) && ce1(2) > ce2(2)
      % ce1 OR ce2
      d1 = ce1(2)-ce1(1);
      d2 = ce2(2)-ce2(1);
      od = ce2(2)-ce1(1);
      match = [match; n1 n2 d1 d2 od];
      n2 = n2 + 1;
   elseif ce1(1) >= ce2(1) && ce1(2) <= ce2(2)
      % ce1 OI ce2
      d1 = ce1(2)-ce1(1);
      d2 = ce2(2)-ce2(1);
      od = d1;
      match = [match; n1 n2 d1 d2 od];
      n1 = n1 + 1;
   elseif (ce1(1) < ce2(1) && ce1(2) >= ce2(2))||...
          (ce1(1) <= ce2(1) && ce1(2) > ce2(2))
      % ce1 OO ce2
      d1 = ce1(2)-ce1(1);
      d2 = ce2(2)-ce2(1);
      od = d2;
      match = [match; n1 n2 d1 d2 od];
      n2 = n2 + 1;
   end
   if n1 <= l1, ce1 = sst_1(n1,:); else done = 1; end
   if n2 <= l2, ce2 = sst_2(n2,:); else done = 1; end
end

match(:,3:5) = match(:,3:5)*24*60*60;
d1_tot = sum(match(:,3));
d2_tot = sum(match(:,4));
od_tot = sum(match(:,5));
 
      
      
