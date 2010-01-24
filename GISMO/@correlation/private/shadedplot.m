function shadedplot(c,scale,ord);

% Private method. See ../plot for details.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% PREP PLOT
figure('Color','w','Position',[50 50 850 1100]);
box on; hold on;


% GET TIME MAX AND MINS
tmin =  999999;
tmax = -999999;
count = 0;
for i = ord
	wstartrel = 86400*(get(c.W(i),'START_MATLAB')-c.trig(i));	% relative start time (trigger is at zero)
        tr = wstartrel + [ 0:get(c.W(i),'DATA_LENGTH')-1]'/get(c.W(i),'Fs'); 

    % save min and max relative trace times
	if tr(1) < tmin
		tmin = tr(1);
	end;
	if tr(end) > tmax
		tmax = tr(end);
	end;
end;


% MAKE ALIGNED DATA MATRIX
p = 1/get(c.W(1),'Fs');         % assumes all sampling periods are the same
tmin = round(tmin*get(c.W(i),'Fs'))*p;      % round to nearest sample
tmax = round(tmax*get(c.W(i),'Fs'))*p;
N = 1:length(ord);
T = [ tmin : p : tmax ];
D = zeros(length(N),length(T));
count = 0;
for i = ord
	count = count + 1;
    d = get(c.W(i),'DATA');            %%%d = c.w(:,i);
    if (max(abs(d)) ~= 0)
        d = scale * d/max(abs(d));		% apply a uniform amplitude scale;
    end
    wstartrel = 86400*(get(c.W(i),'START_MATLAB')-c.trig(i));	% relative start time (trigger is at zero)
       [tmp,startindex] = min(abs(T-wstartrel));
        D( count ,  startindex : (startindex+get(c.W(i),'DATA_LENGTH')-1) ) = d; 
end;
imagesc(T,N,D);


% ADJUST PLOT
axis([tmin tmax 0.5 length(ord)+0.5]);
set(gca,'YDir','reverse');
n = length(ord);
set(gca,'YTick',[1:round(n/50):n]);
yt = get(gca,'YTick');
set(gca,'YTickLabel',datestr(c.trig(ord(yt))),'FontSize',6);
xlabel('Relative Time,(s)','FontSize',8);


% SET COLOR MAP
cmap = [ 0 0 1;
          1 1 1
          1 0 0];
cmap = interp1([-1 0 1],cmap,[-1:.1:1],'linear');
colormap(cmap);




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
set(gcf, 'paperorientation', 'portrait');
set(gcf, 'paperposition', [.25 .25 8 10.5] );
% print(gcf, '-depsc2', 'FIG_alignwfm.ps')
%!ps2pdf FIG_alignwfm.ps
%!convert FIG_alignwfm.ps FIG_alignwfm.gif
%!rm FIG_alignwfm.ps

