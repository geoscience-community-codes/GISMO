function plot_existence(rsam_vector)
    % RSAM/PLOT_EXISTENCE plot rsam data existence
    % handle = plot_existence(rsam_vector)

    % Glenn Thompson Jun 2020 based on rsam/plot


    previousfignum = get_highest_figure_number();
    try
        figure(previousfignum + 1);
    catch
        figure;
    end

    % Plot the data graphs
    N = numel(rsam_vector);
    for c = 1:N
        self = rsam_vector(c);
        fprintf('Making RSAM existence plot for %s\n',self.ChannelTag.string())

        
        hold on; 
        t = self.dnum;
        y = self.data;
        y(~isnan(y))=1;
        y(isnan(y))=0;
        y(2:2:end)=y(2:2:end)*-1.0;      

        debug.print_debug(10,sprintf('Data length: %d',length(y)));
        
        subplot(N,1,c);
        handlePlot = plot(t, y, 'Color', 'k');
        ylabel(self.ChannelTag.string());
        a = axis;
        datetick('x')
        set(gca,'XLim',[a(1) a(2)]);
        xlabel('Date/Time');
        axis tight

    end
end