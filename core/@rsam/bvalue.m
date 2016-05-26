function [aw,tt1, tt2, tmc, mag_zone]=bvalue(this, mcType, method)
    %BVALUE evaluate b-value, a-value and magnitude of completeness
    % of an earthquake catalog stored in a Catalog object.
    %
    % BVALUE(COBJ, MCTYPE) produces a Gutenberg-Richter type plot 
    %    with the best fit line and display of b-,a-values and Mc 
    %    for the catalog object COBJ. MCTYPE is a number from 1-5 
    %    to select the algorithm used for calculation of the 
    %    magnitude of completeness. Options are:
    %
    %    1: Maximum curvature
    %    2: Fixed Mc = minimum magnitude (Mmin)
    %    3: Mc90 (90% probability)
    %    4: Mc95 (95% probability)
    %    5: Best combination (Mc95 - Mc90 - maximum curvature)

    % Liberally adapted from original code in ZMAP.
    % Author: Silvio De Angelis, 27/07/2012 00:00:00
    % Modified and included in Catalog by Glenn Thompson,
    % 14/06/2014

    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License cobj.magas published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Pucobj.magblic License
    % along with this program; if not, write to the
    % Free Software Foundation, Inc.,
    % 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    if nargin < 2
        disp('--------------------------------------------------------')
        disp('ERROR: Usage is: bvalue(cobj, mcType). mcType not specified')
        disp('--------------------------------------------------------')
        disp('mcType can be:')
        disp('1: Maximum curvature')
        disp('2: Fixed Mc = minimum magnitude (Mmin)')
        disp('3: Mc90 (90% probability)')
        disp('4: Mc95 (95% probability)')
        disp('5: Best combination (Mc95 - Mc90 - maximum curvature)')
        return
    end

    % form magnitude vector - removing any NaN values with find
    good_magnitude_indices = find(this.data > 0.0);
    if strcmp(method, 'power')
        mag = log10(this.data(good_magnitude_indices));
    elseif strcmp(method, 'exponential')
        mag = this.data(good_magnitude_indices);
    end   

    %MIN AND MAX MAGNITUDE IN CATALOG
    minimum_mag = min(mag);
    maximum_mag = max(mag);

    %COUNT EVENTS IN EACH MAGNITUDE BIN
    if strcmp(method, 'power')
        magrange = minimum_mag:0.1:maximum_mag;
    elseif strcmp(method, 'exponential')
        magrange = 10.^(log10(minimum_mag):0.1:log10(maximum_mag));
    end  
    [bval, xt2] = hist(mag, magrange);

    %CUMULATIVE NUMBER OF EVENTS IN EACH MAGNITUDE BIN
    bvalsum = cumsum(bval);

    %NUMBER OF EVENTS IN EACH BIN IN REVERSE ORDER
    bval2 = bval(length(bval):-1:1);

    %NUMBER OF EVENTS IN EACH MAGNITUDE BIN IN REVERSE ORDER
    bvalsum3 = cumsum(bval(length(bval):-1:1));

    %BINS IN REVERSE ORDER
    xt3 = fliplr(magrange);
    backg_ab = log10(bvalsum3);

    %CREATE FIGURE WINDOW AND MAKE FREQUENCY-MAGNITUDE PLOT
    figure('Color','w','Position',[0 0 600 600])

    pl = semilogy(xt3,bvalsum3,'sb'); 

    set(pl, 'LineWidth', [1.0],'MarkerSize', [10],'MarkerFaceColor','r','MarkerEdgeColor','k');
    axis square
    hold on

    %pl1 = semilogy(xt3,bval2,'^b');
    %set(pl1, 'LineWidth',[1.0],'MarkerSize',[10],'MarkerFaceColor','w','MarkerEdgeColor','k');
    if strcmp(method, 'power')
        %xlabel('Log_1_0(Amplitude)','Fontsize', 12)
        xlabel('Magnitude','Fontsize', 12)
    elseif strcmp(method, 'exponential')
        xlabel('Amplitude','Fontsize', 12)
    end             

    ylabel('Cumulative Minutes','Fontsize',12)
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


        if strcmp(method, 'power')
            [bval,xt2] = hist(mag,-2:0.1:6);
        elseif strcmp(method, 'exponential')
            [bval,xt2] = hist(log10(mag),-2:0.1:6);
        end  
        l = max(find(bval == max(bval)));
        magco0 =  xt2(l)

        dat = [];

        %for i = magco0-0.6:0.1:magco0+0.2
        for i = magco0-0.5:0.1:magco0+0.7
            if strcmp(method, 'power')
                l = mag >= i - 0.0499;
            elseif strcmp(method, 'exponential')
                l = mag >= 10^(i - 0.0499);
            end
            nu = length(mag(l));
            if length(mag(l)) >= 25;
                %[bv magco stan av] =  bvalca3(catZmap(l,:),2,2);
                if strcmp(method, 'power')
                    [mw bv2 stan2 av] =  bvalue_lib.bmemag(mag(l));
                elseif strcmp(method, 'exponential')
                    [mw bv2 stan2 av] =  bvalue_lib.bmemag(log10(mag(l)));
                end
                bvalue_lib.synthb_aut;
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
        [fMc] = bvalue_lib.calc_Mc(mag, mcType, fBinning, fMccorr);
        l = mag >= fMc-(fBinning/2);
        if length(mag(l)) >= Nmin
            [fMeanMag, fBValue, fStd_B, fAValue] =  bvalue_lib.calc_bmemag(mag(l), fBinning);
        else
            [fMc, fBValue, fStd_B, fAValue] = deal(NaN);
        end

        %STANDARD DEV OF a-value SET TO NAN;
        [fStd_A, fStd_Mc] = deal(NaN);

    else
        [fMc, fStd_Mc, fBValue, fStd_B, fAValue, fStd_A, ...
            fStdDevB, fStdDevMc] = deal(NaN);
    end

    magco = fMc; % magnitude of completeness?
    index_low=find(xt3 < magco+.05 & xt3 > magco-.05);
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
    a0 = aw-log10((max(this.dnum)-min(this.dnum))/365);

    text(.53,.88, ['b-value = ',tt1,' +/- ',tt2,',  a value = ',num2str(aw,3)],'FontSize',12);
    %text(.53,.85,sol_type,'FontSize',12 );
    text(.53,.82,['Magnitude of Completeness = ',tmc],'FontSize',12);


    % Glenn 20150111 add R^2 value
    thiscorr = corrcoef(mag_zone, f)
    r2 = thiscorr(1,2);
    thiscorr2 = corrcoef(mag_zone, log10(f))
    r22 = thiscorr2(1,2);
    %text(.53,.76,['R^2 = ',num2str(r2)],'FontSize',12);
    %text(.53,.70,['R^2 = ',num2str(r22)],'FontSize',12);

end         