function gr=bvalue(catalogObject, mcType, manual_on)
    %BVALUE evaluate b-value, a-value and magnitude of completeness
    % of an earthquake catalog stored in a Catalog object.
    %
    % gr = BVALUE(catalogObject, MCTYPE) produces a Gutenberg-Richter type plot 
    %    with the best fit line and display of b-,a-values and Mc 
    %    for catalogObject. These values are also returned in a structure.
    %    MCTYPE is a number from 1-5 
    %    to select the algorithm used for calculation of the 
    %    magnitude of completeness. Options are:
    %
    %    1: Maximum curvature
    %    2: Fixed Mc = minimum magnitude (Mmin)
    %    3: Mc90 (90% probability)
    %    4: Mc95 (95% probability)
    %    5: Best combination (Mc95 - Mc90 - maximum curvature)
    %
    % * Note: it seems only 1 only really works, and 5 is same as 1 *'
    %
    % gr = BVALUE(catalogObject, MCTYPE, manual_on) where the value of manual_on
    %    computes as true will give the user the ability to manually pick a
    %    linear segment on the graph too (which is then plotted with a
    %    green line). The manual Mc and bvalue are returned in the gr
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

    if nargin < 2
        disp('* Note: it seems only 1 only really works, and 5 is same as 1 *')
        mcType = menu('mcType can be:','Maximum curvature','Fixed Mc = minimum magnitude (Mmin)', ...
            'Mc90 (90% probability)', 'Mc95 (95% probability)', ...
            'Best combination (Mc95 - Mc90 - maximum curvature)')
    end
    if ~exist('manual_on','var')
        manual_on = false;
    end

    % form magnitude vector - removing any NaN values with find
    good_magnitude_indices = find(catalogObject.mag > -3.0);
    mag = catalogObject.mag(good_magnitude_indices);
    %MIN AND MAX MAGNITUDE IN catalogObject
    minimum_mag = min(mag);
    maximum_mag = max(mag);

    %COUNT EVENTS IN EACH MAGNITUDE BIN
    [bval, xt2] = hist(mag, (minimum_mag:0.1:maximum_mag));

    %CUMULATIVE NUMBER OF EVENTS IN EACH MAGNITUDE BIN
    bvalsum = cumsum(bval);

    %NUMBER OF EVENTS IN EACH BIN IN REVERSE ORDER
    bval2 = bval(length(bval):-1:1);

    %NUMBER OF EVENTS IN EACH MAGNITUDE BIN IN REVERSE ORDER
    bvalsum3 = cumsum(bval(length(bval):-1:1));

    %BINS IN REVERSE ORDER
    xt3 = (maximum_mag:-0.1:minimum_mag);
    backg_ab = log10(bvalsum3);

    %CREATE FIGURE WINDOW AND MAKE FREQUENCY-MAGNITUDE PLOT
    figure('Color','w','Position',[0 0 600 600])

    pl = semilogy(xt3,bvalsum3,'sb'); % semilogy is same as plot, except a log (base10) scale is used for Y-axis
    set(pl, 'LineWidth', [1.0],'MarkerSize', [10],'MarkerFaceColor','r','MarkerEdgeColor','k');
    axis square
    hold on

    pl1 = semilogy(xt3,bval2,'^b');
    set(pl1, 'LineWidth',[1.0],'MarkerSize',[10],'MarkerFaceColor','w','MarkerEdgeColor','k');
    xlabel('Magnitude','Fontsize', 12)
    ylabel('Cumulative Number','Fontsize',12)
    set(gca,'visible','on','FontSize',12,'FontWeight','normal',...
        'FontWeight','bold','LineWidth',[1.0],'TickDir','in','Ticklength',[0.01 0.01],...
        'Box','on','Tag','cufi','color','w')

    %ESTIMATE B-VALUE (MAX LIKELIHOOD ESTIMATE)
    Nmin = 10;
    fMccorr = 0;
    fBinning = 0.1;

    if length(mag) >= Nmin

        %GOODNESS-OF-FIT TO POWER LAW
        %%%%%%%%%%%%%%%%%% mcperc_ca3.m start %%%%%%%%%%%%%%%%%%%%
        % This is a completeness determination test

        [bval,xt2] = hist(mag,-2:0.1:6);
        l = max(find(bval == max(bval)));
        magco0 =  xt2(l);

        dat = [];

        %for i = magco0-0.6:0.1:magco0+0.2
        for i = magco0-0.5:0.1:magco0+0.7
            l = mag >= i - 0.0499;
            nu = length(mag(l));
            if length(mag(l)) >= 25;
                %[bv magco stan av] =  bvalca3(catZmap(l,:),2,2);
                [mw bv2 stan2 av] =  Catalog.bvalue_lib.bmemag(mag(l));
                Catalog.bvalue_lib.synthb_aut;
                dat = [ dat ; i res2];
            else
                dat = [ dat ; i nan];
            end

        end

        j =  min(find(dat(:,2) < 10 ));
        if isempty(j) == 1; Mc90 = nan ;
        else;
            Mc90 = dat(j,1);
        end

        j =  min(find(dat(:,2) < 5 ));
        if isempty(j) == 1; Mc95 = nan ;
        else;
            Mc95 = dat(j,1);
        end

        j =  min(find(dat(:,2) < 10 ));
        if isempty(j) == 1; j =  min(find(dat(:,2) < 15 )); end
        if isempty(j) == 1; j =  min(find(dat(:,2) < 20 )); end
        if isempty(j) == 1; j =  min(find(dat(:,2) < 25 )); end
        j2 =  min(find(dat(:,2) == min(dat(:,2)) ));
        %j = min([j j2]);

        Mc = dat(j,1);
        magco = Mc;
        prf = 100 - dat(j2,2);
        if isempty(magco) == 1; magco = nan; prf = 100 -min(dat(:,2)); end
        %display(['Completeness Mc: ' num2str(Mc) ]);
        %%%%%%%%%%%%%%%%%% mcperc_ca3.m end %%%%%%%%%%%%%%%%%%%%%%

        %CALCULATE MC
        [fMc] = Catalog.bvalue_lib.calc_Mc(mag, mcType, fBinning, fMccorr);
        l = mag >= fMc-(fBinning/2);
        if length(mag(l)) >= Nmin
            [fMeanMag, fBValue, fStd_B, fAValue] =  Catalog.bvalue_lib.calc_bmemag(mag(l), fBinning);
        else
            [fMc, fBValue, fStd_B, fAValue] = deal(NaN);
        end

        %STANDARD DEV OF a-value SET TO NAN;
        [fStd_A, fStd_Mc] = deal(NaN);

    else
        [fMc, fStd_Mc, fBValue, fStd_B, fAValue, fStd_A, ...
            fStdDevB, fStdDevMc] = deal(NaN);
    end

    magco = fMc;
    index_low=find(xt3 < magco+.05 & xt3 > magco-.05);
try
    mag_hi = xt3(1);
    index_hi = 1;
    mz = xt3 <= mag_hi & xt3 >= magco-.0001;
    mag_zone=xt3(mz);
    y = backg_ab(mz);

    %PLOT MC IN FIGURE
    Mc = semilogy(xt3(index_low),bvalsum3(index_low)*1.5,'vk');
    set(Mc,'LineWidth',[1.0],'MarkerSize',7)
    Mc = text(xt3(index_low)+0.2,bvalsum3(index_low)*1.5,'Mc');
    set(Mc,'FontWeight','normal','FontSize',12,'Color','k')

    %CREATE AND PLOT FIT LINE
    sol_type = 'Maximum Likelihood Solution';
    bw=fBValue;
    aw=fAValue;
    ew=fStd_B;
    p = [ -1*bw aw];
    f = polyval(p,mag_zone);
    f = 10.^f;
    hold on
    ttm= semilogy(mag_zone,f,'k');
    set(ttm,'LineWidth',[2.0])
    std_backg = ew;

    %ERROR CALCULATIONS
    %b = mag;
    bv = [];
    si = [];

    set(gca,'XLim',[min(mag)-0.5  max(mag+0.5)])
    %set(gca,'YLim',[0.9 length(mag+30)*2.5]);

    p=-p(1,1);
    p=fix(100*p)/100;
    tt1=num2str(bw,3);
    tt2=num2str(std_backg,1);
    tt4=num2str(bv,3);
    tt5=num2str(si,2);
    tmc=num2str(magco,2);
    rect=[0 0 1 1];
    h2=axes('position',rect);
    set(h2,'visible','off');
    t=catalogObject.gettimerange();
    a0 = aw-log10((t(2)-t(1))/365);

    text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
    text(.53,.85,sol_type,'FontSize',12 );
    text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);
    
    %% Added by Glenn 2018-05-01 to return a structure
    gr.bvalue = str2num(tt1);
    gr.bvalue_error = str2num(tt2);
    gr.avalue = aw;
    gr.Mc = str2num(tmc);
    
    %% Manually fit a line (added by Glenn 2018-05-01)
    if manual_on
        [xmag, yN] = ginput(2);
        slope = (log10(yN(1)) - log10(yN(2) )) / (xmag(2) - xmag(1) )
        plot(xmag, yN, 'g');
        gr.Mc_manual = xmag(1);
        gr.bvalue_manual = slope;
        text(xmag(1) + (xmag(2)-xmag(1))*0.5, yN(1) + (yN(2)-yN(1))*0.5, sprintf('manual b=%.2f',slope),'Color','g');
    end
catch
    gr.bvalue = NaN;
    gr.Mc = NaN;
    gr.avalue = NaN;
    gr.bvalue_error = NaN;
end
    
end 