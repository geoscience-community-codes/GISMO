function [fMc] = calc_Mc(mag, nMethod, fBinning, fMcCorrection)
    %CALC_MC Estimate magnitude of completeness
    % fMc = calc_Mc(mag, nMethod, fBinning, fMcCorrection)
    %    Calculate the magnitude of completeness for a given catalog
    %
    % Input parameters:
    %   mag            A vector of magnitudes
    %   nMethod        Method to determine the magnitude of completeness
    %                  1: Maximum curvature
    %                  2: Fixed Mc = minimum magnitude (Mmin)
    %                  3: Mc90 (90% probability)
    %                  4: Mc95 (95% probability)
    %                  5: Best combination (Mc95 - Mc90 - maximum curvature)
    %
    %   fMcCorrection  Correction term to be added to fMc (default 0)
    %
    % Output parameters:
    %   fMc            Magnitude of completeness
    %
    % Special function
    %   If called without any parameters, calc_Mc returns a string containing the names
    %   of all available Mc-determination routines
    %
    % Copyright (C) 2004 by Danijel Schorlemmer, Jochen Woessner
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


    if nargin == 0
        fMc = ['1: Maximum curvature|' ...
            '2: Fixed Mc = minimum magnitude (Mmin)|' ...
            '3: Mc90 (90% probability)|' ...
            '4: Mc95 (95% probability)|' ...
            '5: Best combination (Mc95 - Mc90 - maximum curvature)|'];
        return
    end

    % Magnitude binning
    if ~exist('fBinning', 'var')
        fBinning = 0.1;
    end

    % Correction
    if ~exist('fMcCorrection', 'var')
        fMcCorrection = 0;
    end

    % Init return variable
    fMc = NaN;

    switch nMethod
        case 1
            % Maximum curvature
            fMc = Catalog.bvalue_lib.calc_McMaxCurvature(mag);
        case 2
            % Fixed Mc (Mc = Mmin)
            %fMc = min(mag(:,6));
            fMc = min(mag);
        case 3
            % Automatic Mc90
            [fDummy, fDummy, fMc] = Catalog.bvalue_lib.calc_McBest(mag, fBinning);
        case 4
            % Automatic Mc95
            [fDummy, fMc, fDummy] = Catalog.bvalue_lib.calc_McBest(mag, fBinning);
        case 5
            % Best combination (Mc95 - Mc90 - maximum curvature)
            [fMc, Mc95, Mc90] = Catalog.bvalue_lib.calc_McBest(mag, fBinning);
            if isnan(Mc95) == 0
                fMc = Mc95;
            elseif isnan(Mc90) == 0
                fMc = Mc90;
            else
                fMc = Catalog.bvalue_lib.calc_McMaxCurvature(mag);
            end
    end

    % Check fMc
    if isempty(fMc)
        fMc = NaN;
    end;

    % Apply correction
    if ~isnan(fMc)
        fMc = fMc + fMcCorrection;
    end
end
