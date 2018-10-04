function gr=bvalue_rewrite(catalogObject, runmode)
    %BVALUE evaluate b-value, a-value and magnitude of completeness
    % of an earthquake catalog stored in a Catalog object.
    %
    % gr = BVALUE(catalogObject) produces a Gutenberg-Richter type plot 
    %    with the best fit line and display of b-,a-values and Mc 
    %    for catalogObject. These values are also returned in a structure.
    %    Uses Maximum curvature to find Mc.
    %
    % gr = BVALUE(catalogObject, MCTYPE, runmode)
    %    runmode can be:
    %            0 - no plot
    %            1 - show G-R plot & autofit a slope 
    %            2 - as 1, but also allow user to manually fit a slope
    %    The manual Mc and bvalue are returned in the gr
    %    structure as gr.Mc_manual and gr.bvalue_manual

    % Liberally adapted from original code in ZMAP.
    % Author: Silvio De Angelis, 27/07/2012 00:00:00
    % Modified and included in Catalog by Glenn Thompson,
    % 14/06/2014

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

    if ~exist('runmode','var')
        runmode = 1;
    end
    manual_on = (runmode == 2);
    plot_figure = (runmode > 0);
    magBinSize = 0.1;

    % form magnitude vector - removing any NaN values with find
    good_magnitude_indices = find(catalogObject.mag > -3.0);
    mag = catalogObject.mag(good_magnitude_indices);
    if numel(mag)<30
        error('Not enough data for a b-value');
    end
    
    %MIN AND MAX MAGNITUDE IN catalogObject
    minimum_mag = min(mag);
    maximum_mag = max(mag);

    %COUNT EVENTS IN EACH MAGNITUDE BIN
    binEdges = minimum_mag : magBinSize : maximum_mag;
    [N, magBinCenter] = hist(mag, binEdges);
    % xt2 = mag bin centers. rename this to magBinCenter
    % bval = number in each bin. rename this to N

    %CUMULATIVE NUMBER OF EVENTS IN EACH MAGNITUDE BIN
    cumN = cumsum(N);

    %NUMBER OF EVENTS IN EACH BIN IN REVERSE ORDER
    reverseN = N(end:-1:1);

    %NUMBER OF EVENTS IN EACH MAGNITUDE BIN IN REVERSE ORDER
    cumReverseN = cumsum(reverseN);
    
    %BINS IN REVERSE ORDER
    reverseBinEdges = fliplr(binEdges);

    % Sophisticated method for computing Mc  
    fMccorr = 0; % Mc correction
    try
        mcType = 5;
        Mc = Catalog.bvalue_lib.calc_Mc(mag, mcType, magBinSize, fMccorr);
    catch
        for mcType = 1:4
            fMc(mcType) = NaN;
            try
                fMc(mcType) = Catalog.bvalue_lib.calc_Mc(mag, mcType, magBinSize, fMccorr);
            end
        end
        fMc
        Mc = nanmedian(fMc);
        clear fMc
    end
    
    % Glenn's simple method for guessing Mc
    % just take peak of N v magnitude curve
    if isnan(Mc)
        [Nmax,Nmaxi] = max(N);
        Mc = magBinCenter(Nmaxi);
    end

    % Compute a & b value  
    gr = maxlik(mag, reverseBinEdges, magBinSize, Mc);
      
    if plot_figure
        %CREATE FIGURE WINDOW AND MAKE FREQUENCY-MAGNITUDE PLOT
        figure('Color','w','Position',[0 0 600 600])

        pl = semilogy(reverseBinEdges, cumReverseN,'sb'); % semilogy is same as plot, except a log (base10) scale is used for Y-axis
        set(pl, 'LineWidth', [1.0],'MarkerSize', [10],'MarkerFaceColor','r','MarkerEdgeColor','k');
        axis square
        hold on

        pl1 = semilogy(reverseBinEdges,reverseN,'^b');
        set(pl1, 'LineWidth',[1.0],'MarkerSize',[10],'MarkerFaceColor','w','MarkerEdgeColor','k');
        xlabel('Magnitude','Fontsize', 12)
        %ylabel('Cumulative Number','Fontsize',12)
        ylabel('Number of events','Fontsize',12)
        set(gca,'visible','on','FontSize',12,'FontWeight','normal',...
            'FontWeight','bold','LineWidth',[1.0],'TickDir','in','Ticklength',[0.01 0.01],...
            'Box','on','Tag','cufi','color','w')

        %PLOT LINE FOR MC IN FIGURE
        thisa = axis;
        line([gr.Mc gr.Mc],[thisa(2) thisa(4)],'LineStyle',':','Color','b'); %'LineStyle',

        %CREATE AND PLOT FIT LINE
        p = [ -1*gr.bvalue gr.avalue];
        f = polyval(p, gr.mag_zone);
        f = 10.^f;
        hold on
        hfit= semilogy(gr.mag_zone, f,'k');
        set(hfit,'LineWidth',[2.0])     
        set(gca,'XLim',[min(mag)-0.5  max(mag+0.5)]);
        
        % Add title & legend
        title(sprintf('log_{10}(cumN)=a-bM\nb=%.2f+/-%.2f a=%.2f', ...
            gr.bvalue,gr.bvalue_error,gr.avalue),'FontSize',12);
        legend({'cum N';'N'; sprintf('Mc=%.2f',gr.Mc); 'fitted slope'},'Location','northeast')
    end

    
    %% Manually fit a line (added by Glenn 2018-05-01)
    if manual_on
        [xmag, yN] = ginput(2);
        slope = (log10(yN(1)) - log10(yN(2) )) / (xmag(2) - xmag(1) )
        plot(xmag, yN, 'g');
        gr.Mc_manual = xmag(1);
        gr.bvalue_manual = slope;
        text(xmag(1) + (xmag(2)-xmag(1))*0.5, yN(1) + (yN(2)-yN(1))*0.5, sprintf('manual b=%.2f',slope),'Color','g');
    end

    
end 


function gr = maxlik(mag, reverseBinEdges, magBinSize, Mc)
%ESTIMATE B-VALUE (MAX LIKELIHOOD ESTIMATE)
    Nmin = 10;
    l = mag >= Mc - (magBinSize/2);
    if length(mag(l)) >= Nmin
        [fMeanMag, fBValue, fStd_B, fAValue] = Catalog.bvalue_lib.calc_bmemag(mag(l), magBinSize);

        index_low=find(reverseBinEdges < Mc + magBinSize/2 & reverseBinEdges > Mc - magBinSize/2);
        mag_hi = reverseBinEdges(1);
        mz = reverseBinEdges <= mag_hi & reverseBinEdges >= Mc -.0001;
        mag_zone=reverseBinEdges(mz);

        % output structure    
        gr.bvalue = fBValue;
        gr.bvalue_error = fStd_B;
        gr.avalue = fAValue;
        gr.Mc = Mc;
        gr.index_low = index_low;
        gr.mag_hi = mag_hi;
        gr.mag_zone = mag_zone;  
    else
        gr.bvalue = NaN;
        gr.bvalue_error = NaN;
        gr.avalue = NaN;
        gr.Mc = Mc;
        gr.index_low = NaN;
        gr.mag_hi = NaN;
        gr.mag_zone = NaN; 
    end
end



    