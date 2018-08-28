function [backazimuth, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff, fixazimuth, fixspeed)
%BEAMFORM2D compute back azimuthguess of source from travel time differences
%between each component. Plane waves are assumed (i.e. source at infinite
%distance). 2D assumes flat topography, does not search over a vertical
%incident angle.
%
%   [backazimuth, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff)
%       For each possible back azimuthguess, compute the distances between array 
%       components resolved in that direction.
%       Based on differential travel times (meanSecsDiff), compute
%       speedMatrix. Take average and stdev of speedMatrix, and compute
%       fractional deviation.
%       Choose the azimuthguess for which the fractional
%       deviation is least. Return this and the mean speed (bestspeed).
%   
%       Inputs:
%           easting, northing - GPS coordinates of array components
%           meanSecsDiff - an array of size N*N where N = number of array
%                          components. Each element represents mean travel
%                          time difference between the array elements
%                          represented by that row and column
%
%       Outputs:
%           backazimuthguess - back azimuthguess of the source that best fits inputs
%           bestspeed - pressure wave speed across array that best fits inputs 
%   
%   [backazimuth, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff,fixazimuthguess)
%           fixazimuth - fix the back azimuthguess to this value
%           Only iterate from fixazimuth-1 to fixazimuth+1, rather than from
%           0.1 to 360.
%
%
%   [backazimuth, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff,0,fixspeed)
%           fixspeed - return the back azimuthguess that best fits this speed.

    backazimuth = NaN;
    bestspeed = NaN;

    % First we use travel time ratios to find back azimuthguessal angle of the beam
    % this means we do not need to know speed
    N=numel(easting);
    if numel(northing)~=N
        error('length of easting and northing must be same')
    end
    if (size(meanSecsDiff) ~= [N N])
        size(easting)
        size(northing)
        size(meanSecsDiff)
        error('wrong dimensions for meanSecsDiff')
    end    
    
    if exist('fixspeed','var')
        clear fixazimuthguess
        warning('You can only set fixazimuthguess or fixspeed, not both. Ignoring fixazimuthguess')
    end


    if exist('fixazimuthguess', 'var')
        azimuthguess = mod(180 + fixazimuthguess - 1.0: 0.1: fixazimuthguess + 1.0,360);
    else
        azimuthguess = 0.1:0.1:360;
    end
    unit_vector_easting = -sin(deg2rad(azimuthguess));
    unit_vector_northing = -cos(deg2rad(azimuthguess));

    for row=1:N
        for column=1:N
            eastingDiff(row, column) = easting(row) - easting(column);
            northingDiff(row, column) = northing(row) - northing(column);
        end
    end

    %for thisaz = azimuthguess
    for c=1:length(azimuthguess)
        thisaz = azimuthguess(c);
        for row=1:N
            for column=1:N
                distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(c) unit_vector_northing(c)] );
            end
            %distanceDiff
        end

        speedMatrix = distanceDiff ./ meanSecsDiff;
        meanspeed(c) = mean(speedMatrix([2 3 4 6 7 8]));
        stdspeed(c) = std(speedMatrix([2 3 4 6 7 8]));
        if meanspeed(c)<0
            stdspeed(c)=Inf;
        end
       
    end
    fractional_error = stdspeed ./ meanspeed;
%     figure
%     subplot(2,1,1),bar(azimuthguess, meanspeed);
%     xlabel('Back azimuthguess (degrees)')
%     ylabel('Sound speed (m/s)');
%     subplot(2,1,2),semilogy(azimuthguess, abs(fractional_error));
%     xlabel('Back azimuthguess (degrees)')
%     ylabel('Sound speed fractional error');   
    
    
    % return variables
    fractional_error(meanspeed<0) = Inf; % eliminate -ve speeds as solutions
    if exist('fixspeed','var')
        [~,index] = min(abs(meanspeed-fixspeed));
        fractional_error(index) = 0; % force this speed to be used
    end
    %[~,bestindex] = min(abs(fractional_error));
    [~,bestindex] = min(abs(stdspeed));
    backazimuth = mod(180+azimuthguess(bestindex),360);
    bestspeed = meanspeed(bestindex);
    
    
    for row=1:N
        for column=1:N      
            %distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestazimuthguess) unit_vector_northing(bestazimuthguess)] );
            distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestindex) unit_vector_northing(bestindex)] );
        end
    end
    speedMatrix = distanceDiff ./ meanSecsDiff;
end

