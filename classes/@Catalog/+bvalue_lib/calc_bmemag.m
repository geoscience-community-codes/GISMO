function [fMeanMag, fBValue, fStdDev, fAValue] = ...
        calc_bmemag(mag, fBinning)
    %CALC_BMEMAG Calculate Maximum Likelihood b-value
    % [fMeanMag, fBValue, fStdDev, fAValue] = ...
    %                   calc_bmemag(mag, fBinning)
    % Calculates the mean magnitute, the b-value based
    % on the maximum likelihood estimation, the a-value and the
    % standard deviation of the b-value
    %
    % Input parameters:
    %   mag             Vector of magnitudes
    %   fBinning        Bin size in magnitude (default 0.1)
    %
    % Output parameters:
    %   fMeanMag        Mean magnitude
    %   fBValue         b-value
    %   fStdDev         Standard deviation of b-value
    %   fAValue         a-value

    % Copyright (C) 2003 by Danijel Schorlemmer
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program; if not, write to the
    % Free Software Foundation, Inc.,
    % 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
    %
    % Modified by Glenn Thompson 2014/06/14

    % Set the default value if not passed to the function
    if ~exist('fBinning')
        fBinning = 0.1;
    end

    % Calculate the minimum and mean magnitude, length of catalog
    nLen = length(mag);
    fMinMag = min(mag);
    fMeanMag = mean(mag);
    % Calculate the b-value (maximum likelihood)
    fBValue = (1/(fMeanMag-(fMinMag-(fBinning/2))))*log10(exp(1));
    % Calculate the standard deviation
    fStdDev = (sum((mag-fMeanMag).^2))/(nLen*(nLen-1));
    fStdDev = 2.30 * sqrt(fStdDev) * fBValue^2;
    % Calculate the a-value
    fAValue = log10(nLen) + fBValue * fMinMag;
end