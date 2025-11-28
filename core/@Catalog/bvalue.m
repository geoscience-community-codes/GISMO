function gr = bvalue(catalogObject, runmode, mcType)
%BVALUE Evaluate b-value, a-value, and magnitude of completeness (Mc)
%   gr = BVALUE(catalogObject)
%   gr = BVALUE(catalogObject, runmode)
%   gr = BVALUE(catalogObject, runmode, mcType)
%
%   runmode:
%       0 - no plot (batch / CI safe)
%       1 - show G-R plot & autofit slope (default)
%       2 - as 1, but also allow manual slope fit
%
%   mcType (optional):
%       1–5 : passed to Catalog.bvalue_lib.calc_Mc
%       default = 5 (best combination)
%
%   Output structure gr:
%       gr.bvalue
%       gr.bvalue_error
%       gr.avalue
%       gr.Mc
%       gr.mag_zone
%
%   Author:
%       Silvio De Angelis (original ZMAP adaptation)
%       Glenn Thompson (refactor & modernization)
%
%   License: GNU GPL v2+

    % ----------------------------
    % Input handling & defaults
    % ----------------------------
    if nargin < 2 || isempty(runmode)
        runmode = 1;
    end
    if nargin < 3 || isempty(mcType)
        mcType = 5;   % best-combination default
    end

    manual_on  = (runmode == 2);
    plot_figure = (runmode > 0);
    magBinSize = 0.1;

    % ----------------------------
    % Extract & validate magnitudes
    % ----------------------------
    goodIdx = find(catalogObject.mag > -3.0);
    mag = catalogObject.mag(goodIdx);

    if numel(mag) < 30
        error('Catalog:bvalue:InsufficientData', ...
              'Not enough events for b-value calculation (<30).');
    end

    minimum_mag = min(mag);
    maximum_mag = max(mag);

    % ----------------------------
    % Histogram (modernized)
    % ----------------------------
    binEdges = minimum_mag : magBinSize : maximum_mag;
    [N, edges] = histcounts(mag, binEdges);
    magBinCenter = edges(1:end-1) + diff(edges)/2;

    cumN = cumsum(N);
    reverseN = N(end:-1:1);
    cumReverseN = cumsum(reverseN);
    reverseBinEdges = fliplr(magBinCenter);

    % ----------------------------
    % Magnitude of completeness (Mc)
    % ----------------------------
    fMccorr = 0;

    try
        Mc = Catalog.bvalue_lib.calc_Mc(mag, mcType, magBinSize, fMccorr);
    catch
        fMc = NaN(1,4);
        for k = 1:4
            try
                fMc(k) = Catalog.bvalue_lib.calc_Mc(mag, k, magBinSize, fMccorr);
            end
        end
        Mc = nanmedian(fMc);
    end

    % Fallback: peak of N(M)
    if isnan(Mc)
        [~, Nmaxi] = max(N);
        Mc = magBinCenter(Nmaxi);
    end

    % ----------------------------
    % Compute a & b values (MLE)
    % ----------------------------
    gr = maxlik(mag, reverseBinEdges, magBinSize, Mc);

    % ----------------------------
    % Plotting
    % ----------------------------
    if plot_figure
        figure('Color','w','Position',[0 0 600 600])

        pl = semilogy(reverseBinEdges, cumReverseN,'sb');
        set(pl,'LineWidth',1.0,'MarkerSize',10, ...
               'MarkerFaceColor','r','MarkerEdgeColor','k');
        axis square
        hold on

        pl1 = semilogy(reverseBinEdges,reverseN,'^b');
        set(pl1,'LineWidth',1.0,'MarkerSize',10, ...
                'MarkerFaceColor','w','MarkerEdgeColor','k');

        xlabel('Magnitude','FontSize',12)
        ylabel('Number of events','FontSize',12)
        set(gca,'FontSize',12,'FontWeight','bold','LineWidth',1.0,...
                'TickDir','in','Box','on','Color','w')

        % Mc line
        thisa = axis;
        line([gr.Mc gr.Mc],[thisa(2) thisa(4)], ...
             'LineStyle',':','Color','b');

        % Fit line
        p = [-gr.bvalue gr.avalue];
        f = polyval(p, gr.mag_zone);
        hfit = semilogy(gr.mag_zone, 10.^f,'k');
        set(hfit,'LineWidth',2.0)

        set(gca,'XLim',[min(mag)-0.5  max(mag)+0.5])

        title(sprintf('log_{10}(cumN)=a-bM\nb=%.2f ± %.2f   a=%.2f', ...
              gr.bvalue, gr.bvalue_error, gr.avalue), ...
              'FontSize',12);

        legend({'cum N','N',sprintf('Mc=%.2f',gr.Mc),'fitted slope'}, ...
               'Location','northeast')
    end

    % ----------------------------
    % Manual slope override (optional)
    % ----------------------------
    if manual_on
        [xmag, yN] = ginput(2);
        slope = (log10(yN(1)) - log10(yN(2))) / (xmag(2) - xmag(1));
        plot(xmag, yN,'g');

        gr.Mc_manual     = xmag(1);
        gr.bvalue_manual = slope;

        text(mean(xmag), mean(yN), ...
             sprintf('manual b = %.2f',slope),'Color','g');
    end
end


% ============================================================
% Internal Maximum-Likelihood Engine
% ============================================================
function gr = maxlik(mag, reverseBinEdges, magBinSize, Mc)

    Nmin = 10;
    l = mag >= Mc - (magBinSize/2);

    if numel(mag(l)) >= Nmin
        [~, fBValue, fStd_B, fAValue] = ...
            Catalog.bvalue_lib.calc_bmemag(mag(l), magBinSize);

        index_low = find(reverseBinEdges < Mc + magBinSize/2 & ...
                         reverseBinEdges > Mc - magBinSize/2);
        mag_hi = reverseBinEdges(1);
        mz = reverseBinEdges <= mag_hi & reverseBinEdges >= Mc - 1e-4;
        mag_zone = reverseBinEdges(mz);

        gr.bvalue        = fBValue;
        gr.bvalue_error  = fStd_B;
        gr.avalue        = fAValue;
        gr.Mc            = Mc;
        gr.index_low     = index_low;
        gr.mag_hi        = mag_hi;
        gr.mag_zone      = mag_zone;
    else
        gr.bvalue        = NaN;
        gr.bvalue_error  = NaN;
        gr.avalue        = NaN;
        gr.Mc            = Mc;
        gr.index_low     = NaN;
        gr.mag_hi        = NaN;
        gr.mag_zone      = NaN;
    end
end
