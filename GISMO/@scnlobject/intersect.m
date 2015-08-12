function [ref_A, ref_B] = intersect(scnlA,scnlB)
   
% intersect: Find the intersection between two SCNL objects. Returns only
% the references to intersecting (identical) SCNL.
%  
%  USAGE: [ref_A, ref_B] = intersect(scnlA,scnlB)
%  
%  INPUTS: scnlA - first SCNL object
%          scnlB - second SCNL object
%                           
%  OUTPUTS: ref_A - references to members of first SCNL object
%           ref_B - references to members of second SCNL object

% Text Author: Dane Ketner, Alaska Volcano Observatory
% Author: Celso Reyes
% $Date$
% $Revision$

[ref_A, ref_B] = intersect([scnlA.tag], [scnlB.tag]);
