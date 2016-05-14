function [fMc] = calc_McMaxCurvature(mag);
    %CALC_MCMAXCURVATURE
    % [fMc] = calc_McMaxCurvature(mag);
    % Determine the magnitude of completeness at the point of 
    %   maximum curvature of the frequency magnitude distribution
    %
    % Input parameter:
    %   mag             Earthquake catalog
    %
    % Output parameter:
    %   fMc             Magnitude of completeness, NaN if not computable
    %
    % Danijel Schorlemmer
    % November 7, 2001
    % Modified by Glenn Thompson 2014/06/14

    try
        % Get maximum and minimum magnitudes of the catalog
        fMaxMagnitude = max(mag);
        fMinMagnitude = min(mag);
        if fMinMagnitude > 0
            fMinMagnitude = 0;
        end;

        % Number of magnitudes units
        % Glenn Thompson added ceil() 2014-06-25 due to Matlab warning
        nNumberMagnitudes = ceil(fMaxMagnitude*10) + 1;

        % Create a histogram over magnitudes
        vHist = zeros(1, nNumberMagnitudes);
        [vHist, vMagBins] = hist(mag, (fMinMagnitude:0.1:fMaxMagnitude));

        % Get the points with highest number of events -> maximum curvature
        fMc = vMagBins(max(find(vHist == max(vHist))));
        if isempty(fMc)
            fMc = NaN;
        end;
    catch
        fMc = NaN;
    end
end
