function overlayplot(c,scale,ord)

% Private method. See ../plot for details.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% PREP PLOT
figure('Color','w','Position',[50 50 850 200]);
box on; hold on;


% GET TEMP CORRELATION OBJECT 
c1 = correlation(c);
c1 = set(c1,'WAVEFORMS', get(c,'WAVEFORMS') );
c1 = set(c1,'TRIG', get(c,'TRIG') );
c1 = subset(c1,ord);
c1 = norm(c1);
c1 = stack(c1);
c1 = norm(c1);


% GET MEAN TRACE AMPLITUDE FOR SCALING BELOW
maxlist = [];
for i = 1:length(c1.trig)
    maxlist(end+1) = max(abs( get(c1.W(i),'DATA') ));
end;
normval = mean(maxlist);


% LOOP THROUGH WAVEFORMS
tmin =  999999;
tmax = -999999;
count = 0;
for i = 1:length(c1.trig)-1
	count = count + 1;
    d = get(c1.W(i),'DATA');
    d = scale * d/normval;
    d = -1 * d; 				% because scale is reversed below
	wstartrel = 86400*(get(c1.W(i),'START_MATLAB')-c1.trig(i));	% relative start time (trigger is at zero)
	tr = wstartrel + [ 0:length(d)-1]'/get(c1.W(i),'Fs'); 
	plot(tr,d,'-','Color',[.4 .4 1],'LineWidth',1);
    % save min and max relative trace times
	if tr(1) < tmin
		tmin = tr(1);
	end;
	if tr(end) > tmax
		tmax = tr(end);
	end;

end;


% PLOT THE STACK OF TRACES
d = get(c1.W(end),'DATA');
d = scale * d/normval;			
d = -1 * d; 				
wstartrel = 86400*(get(c1.W(end),'START_MATLAB')-c1.trig(end));
tr = wstartrel + [ 0:length(d)-1]'/get(c1.W(end),'Fs'); 
plot(tr,d,'k-','LineWidth',2);


% adjust figure
axis([tmin tmax -1.1 1.1]);
set(gca,'YDir','reverse');
set(gca,'YTick',[]);
xlabel('Relative Time,(s)','FontSize',8);
text(tmin,-0.8,[' (' num2str(length(c1.trig)-1) ' traces)'],'HorizontalAlignment','Left');


%PRINT OUT FIGURE
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 5 8 2] );
%print(gcf, '-depsc2', 'FIG_alignwfm.ps')


