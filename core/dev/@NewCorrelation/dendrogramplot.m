function dendrogramplot(c)
   %dendrogramplot   create a dendrogram plot
   % Private method. See ../plot for details.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   assert(~isempty(c.link), 'LINK field must be filled in input object');
   
   if ~isempty(c.lags)
      disp('NOTE: Time corrections from LAG field have not been applied to traces yet.');
   end;
   
   
   % CREATE DENDROGRAM PLOT
   [~,~,perm] = dendrogram(c.link,length(c.trig),'Orientation','right');
   set(gcf,'Color','w','Position',[50 50 680 880]);
   ylabel('event number','FontSize',16);
   set(gca,'XGrid','on');
   box on; hold on;
   set(gcf,'Position',[0 0 640 1024]);
   
   
   % SWITCH X AXIS LABELS
   set(gca,'XDir','reverse');
   label = 1- str2num(get(gca,'XTickLabel'));
   set(gca,'XTickLabel',label);
   xlabel('inter-cluster correlation','FontSize',16);
   
   
   % MODIFY Y AXIS LABELS
   if ~isempty(c.clust)
      YT = (get(gca,'YTickLabel'));
      set(gca,'YTickLabel',YT);
      ylabel('event number (and cluster)','FontSize',16);
   end
   
   
   % PREP PRINT OUT
   set(gcf, 'paperorientation', 'portrait');
   set(gcf, 'paperposition', [.25 .25 8 10.5] );
   
   
   % ADD WIGGLE PLOT
   perm = fliplr(perm);
   if length(perm)>=100
      plot(c,'sha',1,perm);
   else
      plot(c,'wig',1,perm);
   end
   
   set(gcf,'Position',[641 0 640 1024]);
end


