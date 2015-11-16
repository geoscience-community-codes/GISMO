function statplot(c);

% Private method. See ../plot for details.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



Rmean  = c.stat(:,1);
Rrmshi = c.stat(:,2);
Rrmslo = c.stat(:,3);
T      = c.stat(:,4);
Trms   = c.stat(:,5);




% PLOT RESULTS
figure('Color','w','Position',[50 50 1000 600]);
set(gcf,'DefaultLineLineWidth',1);
set(gcf,'DefaultAxesFontSize',14);

subplot(2,1,1);
hold on; grid on; box on;
ylabel('Time (s)');
title('Best fit delay time and 1\sigma error');
xfill = [ [1:length(T)]' ; [length(T):-1:1]' ];
yfill = [T+Trms ; flipud(T-Trms)];
fill(xfill,yfill,[.9 .9 .9]);
plot(c.L','b.','MarkerSize',5);
plot(T,'ko-','LineWidth',2);
xlim([1 length(T)]);
maxval = 1.05*max(max(abs(c.L)));
ylim([-1*maxval maxval]);


subplot(2,1,2);
hold on; grid on; box on;
xfill = [ [1:length(T)]' ; [length(T):-1:1]' ];
yfill = [Rrmshi ; flipud(Rrmslo)];
fill(xfill,yfill,[.9 .9 .9]);
plot(Rmean,'ko-','LineWidth',2);
xlabel('Trace no.');
ylabel('Mean R');
title('Mean max correlation and 1\sigma error');
xlim([1 length(T)]);
ylim([0 1]);



% PREP PRINT OUT
set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [1 3 9 4] );
print(gcf, '-depsc2', 'FIG_stat.ps');


