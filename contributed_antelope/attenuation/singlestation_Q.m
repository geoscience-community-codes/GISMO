function QFrankel = singlestation_Q(file,ls, us)
%   Loads in the .mat file created by 'station_arrival_spectralratio.m',
%   and a back-azimuth range (ls-lower back azimuth, us-upper back
%   azimuth). Subset .mat file by back azimuth range, and plots the
%   spectral ratio versus travel time. Then calculates a linear regression
%   and estimates the Q-value based on the method of Arthur Frankel, "The Effects of Attenuation and
%   Site Response on the Spectra of Microearthquakes in the Northeastern
%   Caribbean", BSSA, 72, 4, 1379-1402 (1982). 
%   Created by Heather McFarlin, Jan 2023
%   Forthe complete history of this script please see companion script
%   'station_arrival_spectralratio.m'

%   Example:
%       file = 'station_arrival_spectralraio.mat';
%       ls = 150;
%       us = 210;
%       singlestation_Q(file, ls, us)
%%
%   Read in data from station_arrival_spectralratio.m and make it usable   
    load(file);
%   Subset .mat file by back azimuth range
    found = find(seaz>ls & seaz<us);
    A1 = A1(found)
    A1_noise = A1_noise(found);
    A2 = A2(found);
    A2_noise = A2_noise(found);
    t = t(found);
    y = y(found);
%   Set the frequencies used in statin_arrival_spectralratio.m
    f1 = 20;
    f2 = 5;
%   Create Qvalue plot
    figure;
    plot(t, y, 'o');
    ylabel('ln(A_1/A_2)')
    xlabel('travel time (s)')
%   For the linear regression
    [p, S, mu] = polyfit(t,y,1);
%   get the current axis handle--in this case it is the x-axis limits
    xlim=get(gca,'XLim');
%   For the linear regression and std dev. 
    [yline, delta] = polyval(p, xlim, S, mu); 
    hold on;
%   Plots the linear regression of the ln(amp(20Hz)/amp(5Hz)) vs time
    plot(xlim, yline)
%   calculates the mean of the error
    d_mean = mean(delta) 
    slope = (yline(2) - yline(1)) / (xlim(2) - xlim(1))
    q = - pi * (f1 - f2) / slope;
    error = -pi * (f1-f2)/(slope+2*d_mean)
    hold on
%   Plot the 2 sigma standard deviation
    %plot(xlim,yline+2*delta,'m--',xlim,yline-2*delta,'m--') % turned off
    %for now
%   Print the error to the command line
    delta
%   Norm of the residuals, printed to the command line
    nr = S.normr   
    title(sprintf('Q_{F} = %.0f +/- %6.3f \nNorm of Residuals = %6.3f ', q, abs(error), nr));
end 

