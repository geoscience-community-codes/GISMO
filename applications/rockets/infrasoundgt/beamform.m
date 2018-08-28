function [bestbackaz, bestspeed,distanceDiff,speedMatrix] = beamform(easting, northing, meanSecsDiff);
% tmp=easting(2);
% easting(2)=easting(3);
% easting(3)=tmp;
% tmp=northing(2);
% northing(2)=northing(3);
% northing(3)=tmp;
%BEAMFORM compute back azimuth of source from travel time differences
%between each component. Plane waves are assumed (i.e. source at infinite
%distance).
%
%   sourcebackaz = beamform(easting, northing, meanSecsDiff)
%   
%       Inputs:
%           easting, northing - GPS coordinates of array components
%           meanSecsDiff - an array of size N*N where N = number of array
%                          components. Each element represents mean travel
%                          time difference between the array elements
%                          represented by that row and column
%
%       Outputs:
%           sourcebackaz - back azimuth of the source
%
%
    bestbackaz = NaN;
    bestspeed = NaN;

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

    backaz = 1:360;
    unit_vector_easting = -sin(deg2rad(backaz));
    unit_vector_northing = -cos(deg2rad(backaz));

    for row=1:N
        for column=1:N
            eastingDiff(row, column) = easting(row) - easting(column);
            northingDiff(row, column) = northing(row) - northing(column);
        end
    end

    for thisaz = backaz
        for row=1:N
            for column=1:N      
                distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(thisaz) unit_vector_northing(thisaz)] );
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
        meanspeed(thisaz) = mean(a);
        stdspeed(thisaz) = std(a);
       
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
    [~,bestbackaz] = min(abs(fractional_error));
    bestspeed = meanspeed(bestbackaz);
    
    fprintf('Source is at back azimuth %.1f and wave travels at speed of %.1fm/s\n',bestbackaz,bestspeed);
    for row=1:N
        for column=1:N      
            distanceDiff(row, column) = dot( [eastingDiff(row, column)  northingDiff(row, column)], [unit_vector_easting(bestbackaz) unit_vector_northing(bestbackaz)] );
        end
    end
    speedMatrix = distanceDiff ./ meanSecsDiff;
end

