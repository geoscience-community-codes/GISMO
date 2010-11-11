function TC = rotate(TC,varargin)

%Rotate component orientations
% TC = ROTATE(TC,BEARING) Rotates the horizontal components of a threecomp
% object so that the first horizontal component (N, R or 1) points in the
% direction given by BEARING. If the rotation is to north/east or
% radial/transverse then the horizontral channel names will be renamed to
% ??N/??E or ??R/??T accordingly. If the rotation is to an arbitrary
% direction, the channels will be renamed to ??2/??1.
%
% TC = ROTATE(TC) is shorthand for ROTATE(TC,-BACKAZIMUTH). This common
% usage rotates horizontal traces to the radial and transverse directions,
% where radial is inline (and away) from the source. The transverse
% direction points +90 from the radial. For example,for a wave arriving
% from due south, there is no rotation and N+ becomes R+, while E+ becomes
% T+. This useage requires that the backAzimuth property be set.


% TODO: DISALLOW NO BACKAZIMUTH AND NO ARGUMENT


% CHECK ARGUMENTS AND GET FINAL BEARING
if length(varargin)>=1  % bearing provided by user
    bearing = varargin{1};
    if ~isa(bearing,'double') 
       error('Threecomp:rotate:badArgumentType','Rotation angle must be a number'); 
    end
    if bearing<-360 || bearing>720
       error('Threecomp:rotate:badArgumentValue','Rotation angle must be between 0 and 360'); 
    end
else
    bearing = NaN * zeros(size(TC));
    for n = 1:numel(TC)
        if ~isempty(TC(n).backAzimuth)
            bearing(n) = TC(n).backAzimuth+180;
        end
        bearing = reshape(bearing,size(TC));
        bearing = mod(bearing,360);
    end
end


% COMPUTE ROTATION ANGLES
orientation = get(TC,'ORIENTATION');
for n = 1:length(TC)
   if isempty(orientation) 
       error('ThreeComp:rotate:noOrientations','Component orientations must be provided');
   end
end
rotAngle = mod(bearing-orientation(:,3),360);




% APPLY ROTATION
for n = 1:length(TC)
    data = double(TC(n).traces(2:3))';
    rotMatrix = [cosd(rotAngle(n)) sind(rotAngle(n)) ; -sind(rotAngle(n)) cosd(rotAngle(n))];
    Dout = rotMatrix * data;
    TC(n).traces(2) = set(TC(n).traces(2),'DATA',Dout(1,:));
    TC(n).traces(3) = set(TC(n).traces(3),'DATA',Dout(2,:));
    newOrientation = TC(n).orientation;
    newOrientation([3 5]) = mod(newOrientation([3 5])+rotAngle(n),360);
    TC(n).orientation = newOrientation;
end



% ADJUST CHANNEL NAMES
for n = 1:length(TC)
    channels = get(TC(n),'CHANNEL');
    chan2 = channels{1}(2);
    chan2 = chan2{1};
    chan3 = channels{1}(3);
    chan3 = chan3{1};
    if abs(TC(n).orientation(3)-0)<0.5
        chan2(3) = 'N';
        chan3(3) = 'E';
    elseif abs(mod((TC(n).orientation(3)+180),360)-TC(n).backAzimuth)<0.5
        chan2(3) = 'R';
        chan3(3) = 'T';
    else
        chan2(3) = '2';
        chan3(3) = '1';
    end
    TC(n).traces(2) = set(TC(n).traces(2),'CHANNEL',chan2);
    TC(n).traces(3) = set(TC(n).traces(3),'CHANNEL',chan3);
end

