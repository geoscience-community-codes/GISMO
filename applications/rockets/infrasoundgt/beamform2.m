function [bestbackaz, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff, fixbackaz, fixspeed);
%BEAMFORM2D compute back azimuth of source from travel time differences
%between each component. Plane waves are assumed (i.e. source at infinite
%distance). 2D assumes flat topography, does not search over a vertical
%incident angle.
%
%   [bestbackaz, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff)
%       For each possible back azimuth, compute the distances between array 
%       components resolved in that direction.
%       Based on differential travel times (meanSecsDiff), compute
%       speedMatrix. Take average and stdev of speedMatrix, and compute
%       fractional deviation.
%       Choose the best back azimuth (bestbackaz) as the back azimuth for which the fractional
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
%           bestbackaz - back azimuth of the source that best fits inputs
%           bestspeed - pressure wave speed across array that best fits inputs 
%   
%   [bestbackaz, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff,fixbackaz)
%           fixbackaz - fix the back azimuth to this value
%           Only iterate from fixbackaz-1 to fixbackaz+1, rather than from
%           0.1 to 360.
%
%
%   [bestbackaz, bestspeed,distanceDiff,speedMatrix] = beamform2d(easting, northing, meanSecsDiff,0,fixspeed)
%           fixspeed - return the back azimuth that best fits this speed.

    bestbackaz = NaN;
    bestspeed = NaN;
    disp('goit here')

    % First we use travel time ratios to find back azimuthal angle of the beam
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
        clear fixbackaz
        warning('You can only set fixbackaz or fixspeed, not both. Ignoring fixbackaz')
    end

    if exist('fixbackaz', 'var')
        backaz = fixbackaz - 1.0: 0.1: fixbackaz + 1.0;
    else
        backaz = 0.1:0.1:360;
    end
    unit_vector_easting = -sin(deg2rad(backaz));
    unit_vector_northing = -cos(deg2rad(backaz));

    for row=1:N
        for column=1:N
            eastingDiff(row, column) = easting(row) - easting(column);
            northingDiff(row, column) = northing(row) - northing(column);
        end
    end
    eastingDiff
    northingDiff
    meanSecsDiff

    %for thisaz = backaz
    for c=1:length(backaz)
        thisaz = backaz(c);
        for row=1:N
            for column=1:N      
                distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(c) unit_vector_northing(c)] );
            end
        end
        speedMatrix = distanceDiff ./ meanSecsDiff;
        a =[];
        for row=1:N
            for column=1:N      
                if row~=column
                    a = [a speedMatrix(row, column)];
                end
            end
        end
        %meanspeed(thisaz) = mean(a);
        %stdspeed(thisaz) = std(a);
        meanspeed(c) = mean(a);
        stdspeed(c) = std(a);
       
    end
    fractional_error = stdspeed ./ meanspeed;
    figure
    subplot(2,1,1),bar(backaz, meanspeed);
    xlabel('Back azimuth (degrees)')
    ylabel('Sound speed (m/s)');
    subplot(2,1,2),semilogy(backaz, abs(fractional_error));
    xlabel('Back azimuth (degrees)')
    ylabel('Sound speed fractional error');   
    
    
    % return variables
    fractional_error(meanspeed<0) = Inf; % eliminate -ve speeds as solutions
    if exist('fixspeed','var')
        [~,index] = min(abs(meanspeed-fixspeed));
        fractional_error(index) = 0; % force this speed to be used
    end
    [~,bestindex] = min(abs(fractional_error));
    bestbackaz = backaz(bestindex);
    bestspeed = meanspeed(bestindex);
    
    fprintf('Source is at back azimuth %.1f and wave travels at speed of %.1fm/s\n',bestbackaz,bestspeed);
    for row=1:N
        for column=1:N      
            %distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestbackaz) unit_vector_northing(bestbackaz)] );
            distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestindex) unit_vector_northing(bestindex)] );
        end
    end
    speedMatrix = distanceDiff ./ meanSecsDiff;
end

