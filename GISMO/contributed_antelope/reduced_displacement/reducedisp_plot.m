function reducedisp_plot(dbname)

%REDUCEDISP_PLOT plot reduced displacement data.
%
%REDUCEDISP_PLOT(DBNAME) is really just an example script that shows how a
%custom reduced displacement plot can be made. For most applications users
%will want more custom control over the data.  See below.
%
% This finction reads in a reduced displacement database and plot it as a
% function of time. As an intermediate step it also creates a version of
% the database table that is matlab formatted. The name of this file is the
% same as the database table except that the .wfmeas extension is replaced
% by .mat. This function automatically writes out a postscript plot of the
% results named FIG_reducedisp.ps. If this file already exists, it is
% overwritten without asking. To generate custom plots, copy this function
% to a local location and use it as a template:
% >> which reducedisp_plot
%    /[SomePathName]/reducedisp_plot
% cp /[SomePathName]/reducedisp_plot .  (outside matlab)
%
% Currently not compatible with Linux 64-bit Matlab libraries
% Use 32-bit version 

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



%%%%%%%%%%%%%%%%%% 32 only %%%%%%%%%%%%%%%%%%%%

db = dbopen(dbname,'r');
db = dblookup(db,'','wfmeas','','');
%db = dbsubset(db,'chan =~ /HHZ/');
%db = dbsubset(db,'sta =~ /BEZC/');
%db = dbsubset(db,'time > "01/05/2006 00:00:00"');
%db = dbsubset(db,'time < "01/14/2006 00:00:00"');
nrecords = dbquery(db,'dbRECORD_COUNT');
display(['Number of records: ' num2str(nrecords)]);
[sta,chan,tmeas,val1] = dbgetv(db,'sta','chan','tmeas','val1');
tmeas = epoch2datenum(tmeas);
dbclose(db);
save([dbname '.mat'])



%%%%%%%%%%%%%%%%%% 32 or 64 %%%%%%%%%%%%%%%%%%%%


figure('Color','w','Position',[50 500 1200 400]);
set(gcf,'DefaultAxesFontSize',14);
set(gca,'YScale','log');

semilogy(tmeas,val1,'o','Color','k','MarkerSize',4,'LineWidth',.25,'MarkerFaceColor','y');
xlim([min(tmeas) max(tmeas)]);
ylim( 0.5*[min(val1) 2*max(val1)] );
grid on; box on; hold on;

%xlim([min(tmeas) max(tmeas)]);
%xticklist = {'1/1/2006' '1/10/2006' '1/20/2006' '2/1/2006' '2/10/2006' '2/20/2006' '3/1/2006' '3/10/2006' '3/20/2006' '4/1/2006'};
%set(gca,'XTick',datenum(xticklist));
ylabel('Reduced displacement (cm^2)');
datetick('x',6,'KeepTicks');

set(gcf, 'paperorientation', 'landscape');
set(gcf, 'paperposition', [.25 4 10.5 3] );
print(gcf, '-depsc2', 'FIG_reducedisp.ps')




