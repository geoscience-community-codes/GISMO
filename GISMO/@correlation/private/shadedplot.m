function shadedplot(c,scale,ord)

% Private method. See ../plot for details.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% PREP PLOT
figure('Color','w','Position',[50 50 850 1100]);
box on; hold on;


% GET TIME MAX AND MINS
tmin =  999999;
tmax = -999999;
count = 0;
wstartrels = 86400 .* (get(c.W(ord),'START_MATLAB') - c.trig(ord));
wlengths = get(c.W(ord),'DATA_LENGTH');
wFs = get(c.W(ord),'Freq');

for i = 1:numel(ord)
	%wstartrel = 86400*(get(c.W(i),'START_MATLAB')-c.trig(i));	% relative start time (trigger is at zero)
        %tr = wstartrel + [ 0:get(c.W(i),'DATA_LENGTH')-1]'/get(c.W(i),'Fs');      
        tr = wstartrels(i) + [ 0:wlengths(i)-1]'/wFs(i); 

    % save min and max relative trace times
	if tr(1) < tmin
		tmin = tr(1);
	end;
	if tr(end) > tmax
		tmax = tr(end);
	end;
end;


% MAKE ALIGNED DATA MATRIX
%p = 1/get(c.W(1),'Fs');         % assumes all sampling periods are thesame
p = 1/wFs(1);         % assumes all sampling periods are the same

tmin = round(tmin*wFs(i))*p;      % round to nearest sample
tmax = round(tmax*wFs(i))*p;
N = 1:length(ord);
T =  tmin : p : tmax ;
D = zeros(length(N),length(T));
count = 0;
absmax = max(abs(c.W(ord)));
absmax(absmax==0) = scale; %next line will be negated for zero-scale
d = double(c.W(ord) .* (scale ./ absmax));
for i = 1:numel(ord)
	count = count + 1;
   %d = get(c.W(ord(i)),'DATA');            %%%d = c.w(:,i);
    %if (max(abs(d)) ~= 0)
    %    d = scale * d/max(abs(d));		% apply a uniform amplitude scale;
    %end
    % DONE ABOVE: wstartrel = 86400*(get(c.W(i),'START_MATLAB')-c.trig(i));	% relative start time (trigger is at zero)
       [tmp,startindex] = min(abs(T-wstartrels(i)));
        D( count ,  startindex : (startindex+wlengths(i)-1) ) = d(:,i); 
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
    labels = strcat(sta,'_', chan);
%     for i=1:get(c,'TRACES')
%        labels(i) = strcat( sta(i) , '_' , chan(i) );
%     end
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

