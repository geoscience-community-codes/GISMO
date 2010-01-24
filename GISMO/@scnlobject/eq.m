function results = eq(mywave, anythingelse)
% unimplemented scnlobject equals.  use ismember instead.
disp(['first object is a ' class(mywave)]);
disp(['second object is a ' class(anythingelse)]);

if isa(anythingelse,'scnlobject')
  disp('doing the scnl thing...')
end
  