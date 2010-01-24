function wiggleinterferogram(c,scale,type,norm,range)

% Private method. See ../plot for details.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



% EXTRACT IMAGE
w = get(c,'WAVES');
if isempty(get(w(1),'interferogram_time'))
    error('PLOT INTERFER method can only be used following INTERFEROGRAM function');
end    
I.time  = get(w(1),'INTERFEROGRAM_TIME');
I.index = get(w(1),'INTERFEROGRAM_INDEX');
I.CC    = get(w(1),'INTERFEROGRAM_MAXCORR');
I.LL    = get(w(1),'INTERFEROGRAM_LAG');

% SET COLOR SCALE FOR LAG PLOT
I.LL = I.LL ./ range;
f = find((I.LL)<-1); I.LL(f)=-1;      % eliminate outliers
f = find((I.LL)> 1); I.LL(f)= 1;
I.LL = 31.5 * I.LL;
I.LL = round(I.LL + 32.5);                       % shift to positive indices

I.TRANS = I.CC - 0.6;
f = find(I.TRANS<0);
I.TRANS(f) = 0;
I.TRANS = round(0.75*10*I.TRANS);
I.LL = I.LL + 64*I.TRANS;


% PREP PLOT
figure('Color','w','Position',[50 50 850 1100]);
box on; hold on;


% FIX ORDER OF TRACES
ord = 1:get(c,'TRACES');


% GET MEAN TRACE AMPLITUDE FOR SCALING BELOW (when norm = 0)
maxlist = [];
for i = ord
    maxlist(end+1) = max(abs( get(c.W(i),'DATA') ));
end;
normval = mean(maxlist);


% ADD IMAGE
if strncmpi(type,'C',1)
    imagesc(I.time,I.index,I.CC);
    colormap(c,'LTC');
    colorbar;
    hold on;    
elseif strncmpi(type,'L',1)
    h = image(I.time,I.index,I.LL);
    colormap(jet);
    %caxis([-1 1]);
    cmap = load('colormap_lag.txt');
    invcmap = 1 - cmap;
    cmap = 1 - [0*invcmap ; 0.33*invcmap ; 0.66*invcmap ; 1*invcmap];
    colormap(cmap);
    hcb = colorbar;
    set(hcb,'YLim',[193 256]);
    set(hcb,'YTick',193+64*[0:.125:1]);
    set(hcb,'YTickLabel',range*[-1:.25:1]);
    
    hold on;
else
    error('Plot type not recognized.');
end

% SET COLOR



% LOOP THROUGH WAVEFORMS
tmin =  999999;
tmax = -999999;
count = 0;
for i = ord
	count = count + 1;
    d = get(c.W(i),'DATA');            %%%d = c.w(:,i);
	if norm==0
        d = scale * d/normval;			% do not normalize trace amplitudes
    else
        if max(abs(d))==0
            d = scale * d;              	% ignore zero traces
        else
            d = scale * d/max(abs(d));		% normalize trace amplitudes
        end
    end
    d = -1 * d; 				% because scale is reversed below
	wstartrel = 86400*(get(c.W(i),'START_MATLAB')-c.trig(i));	% relative start time (trigger is at zero)
	tr = wstartrel + [ 0:length(d)-1]'/get(c.W(i),'Fs'); 
	plot(tr,d+count,'k-','LineWidth',1.5);
    % save min and max relative trace times
	if tr(1) < tmin
		tmin = tr(1);
	end;
	if tr(end) > tmax
		tmax = tr(end);
	end;

end;


% adjust figure
axis([tmin tmax 0 length(ord)+1]);
set(gca,'YDir','reverse');
set(gca,'YTick',1:length(ord));
set(gca,'YTickLabel',datestr(c.trig(ord)),'FontSize',6);
xlabel('Relative Time,(s)','FontSize',8);




% replace dates with station names if stations are different
if ~check(c,'STA')
    sta  = get(c,'STA');
    chan = get(c,'CHAN');
    
    for i=1:get(c,'TRACES')
       labels(i) = strcat( sta(i) , '_' , chan(i) );
    end
    set( gca , 'YTick' , [1:1:get(c,'TRACES')] );
    set( gca , 'YTickLabel' , labels );
end




%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.25 .25 10.5 8] );
try
if strncmpi(type,'C',1)
    print(gcf, '-depsc2', 'FIG_interferogram_corr.ps')
else
    print(gcf, '-depsc2', 'FIG_interferogram_lag.ps')
end
catch
disp('Warning: Unable to save figure in current directory.');
end


