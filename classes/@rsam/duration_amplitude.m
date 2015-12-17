function [lambda, r2] = duration_amplitude(self, law, min_amplitude, mag_zone)
%DURATION_AMPLITUDE Use the duration-amplitde
%Compute the fraction of a data series above each
%amplitude level, plot the duration vs amplitude data, and then
%allow user input to fit a regression line.
%   rsamObject.duration_amplitude(law, min_amplitude)
%   
%   Inputs: 
%       law = 'exponential' or 'power'
%       min_amplitude = (Optional) the smallest amplitude to use on
%       the x-axis. Otherwise will be 10^10 times smallest than the
%       largest amplitude.
%
%   Outputs:
%       (None) A graph is plotted, the user clicks two points, and
%       from that slope, the characteristic amplitude is computed
%       and shown on the screen.

    y = self.data;
    n = length(y);
    a = abs(y);
    max_amplitude = max(a);
    if ~exist('min_amplitude', 'var')
        min_amplitude = max([min(a) max(a)*1e-10]);
    end

    % Method 1
    index=0;
    x = min_amplitude;
    while x < max_amplitude,
        i = find(a>x);
        f = length(i);
        index = index+1;
        frequency(index) = f;
        threshold(index) = x;
        x = x * 1.2;
    end
    clear x y a  f  n  min_amplitude max_amplitude index ;

%             % Method 2
%             threshold = [0.0 logspace(min_amplitude, max_amplitude, 50)];
%             nsamples=[];
%             for d = 1:length(threshold)
%                 i = find(a > threshold(d));
%                 frequency(d) = length(i)/length(y);
%             end 
%             clear d, nsamples, i, y

    %% PLOT_DURATION_AMPLITUDE 
    % plot graph, user select two points, compute
    % characteristic from slope.
    % Use different method depending on whether it is a
    % power law or exponential.

    % define x and y
    switch law
        case {'exponential'}
            x = threshold;
            xlabelstr = 'RMS Displacement(nm)';
        case {'power'}
            x = log10(threshold);
            xlabelstr = 'log10(RMS Displacement(nm))';
        otherwise
            error('law unknown')
    end
    y=log10(frequency);

    % plot duration-amplitude data as circles
    figure
    plot(x,y,'o');
    xlabel(xlabelstr);
    ylabel('log10(Cumulative Minutes)');
    hold on;
    %set(gca,'XLim',[xmin xmax]);

    lambda=0;
    r2=0;

    % check if we have pre-set the magnitude range, effectively
    % our x1 and x2 click points with ginput
    if exist('mag_zone','var') % no user select
        switch law
            case {'power'}
                x1=min(mag_zone);
                x2=max(mag_zone);
            case {'exponential'}
                x1=10^min(mag_zone);
                x2=10^max(mag_zone);

            otherwise
                error('law unknown')
        end      
        if x1<min(x)
            x2=min(x);
        end
        y1=interp1(x,y,x1);
        if x2>max(x)
            x2=max(x);
        end
        y2=interp1(x,y,x2); 

        % draw a dotted line to show where user selected	
        %plot([x1 x2], [y1 y2], '-.');

        % select requested data range and do a least squares fit
        ii = find(x >= x1 & x <= x2);
        wx = x(ii);
        wy = y(ii);
        [p,S]=polyfit(wx,wy,1);
        yfit = polyval(p,wx);
        thiscorr = corrcoef(wy, yfit)
        %try
        if numel(thiscorr)>1
            r2 = thiscorr(1,2);

            % compute lambda
            switch law
                case {'exponential'}
                    lambda = -p(1)/log10(exp(1));
                case {'power'}
                    lambda = -p(1); 
                otherwise
                    error('law unknown')
            end

            disp(sprintf('characteristic D_R_S=%.2f cm^2, R^2=%.2f',lambda,r2));

            % draw the fitted line
            xf = [min(wx) max(wx)];
            yf = xf * p(1) + p(2);
            plot(xf, yf,'-');

            %ylabel('log10(t/t0)');
            %xlabel(sprintf('D_R_S (%s) (cm^2)',measure));


            % Add legend
            yrange=get(gca,'YLim');
            xlim = get(gca,'XLim');
            xmax=max(xlim);

            xpos = xmax*0.65;
            ypos = (yrange(2)-yrange(1))*0.8;
            r2str=sprintf('%.2f',r2);
            lambdastr=sprintf('%.2f',lambda);
            if strcmp(law,'exponential')
                tstr = [' \lambda=',lambdastr,' R^2=',r2str];
            else
                tstr = [' \gamma=',lambdastr,' R^2=',r2str];
            end

            text(xpos, ypos, tstr, ...
                'FontName','Helvetica','FontSize',[14],'FontWeight','bold');   
        else
            lambda=NaN;
            r2=NaN;
        end

    else

        % user select a range of data
        disp('Left-click Select lowest X, any other mouse button to ignore this station')
        [x1, y1, button1]=ginput(1);
        if button1==1
            disp('Left-click Select highest X, any other mouse button to ignore this station')
            [x2, y2, button2]=ginput(1);    
            if button2==1
                if x2>x1
                   % draw a dotted line to show where user selected	
                    plot([x1 x2], [y1 y2], '-.');

                    % select requested data range and do a least squares fit
                    ii = find(x >= x1 & x <= x2);
                    wx = x(ii);
                    wy = y(ii);
                    [p,S]=polyfit(wx,wy,1);
                    yfit = polyval(p,wx);
                    thiscorr = corrcoef(wy, yfit)

                    r2 = thiscorr(1,2);

                    % compute lambda
                    switch law
                        case {'exponential'}
                            lambda = -p(1)/log10(exp(1));
                        case {'power'}
                            lambda = -p(1); 
                        otherwise
                            error('law unknown')
                    end

                    disp(sprintf('characteristic D_R_S=%.2f cm^2, R^2=%.2f',lambda,r2));

                    % draw the fitted line
                    xf = [min(wx) max(wx)];
                    yf = xf * p(1) + p(2);
                    plot(xf, yf,'-');

                    %ylabel('log10(t/t0)');
                    %xlabel(sprintf('D_R_S (%s) (cm^2)',measure));


                    % Add legend
                    yrange=get(gca,'YLim');
                    xlim = get(gca,'XLim');
                    xmax=max(xlim);

                    xpos = xmax*0.65;
                    ypos = (yrange(2)-yrange(1))*0.8;
                    r2str=sprintf('%.2f',r2);
                    lambdastr=sprintf('%.2f',lambda);
                    if strcmp(law,'exponential')
                        tstr = [self.sta,' \lambda=',lambdastr,' R^2=',r2str];
                    else
                        tstr = [self.sta,' \gamma=',lambdastr,' R^2=',r2str];
                    end

                    text(xpos, ypos, tstr, ...
                        'FontName','Helvetica','FontSize',[14],'FontWeight','bold');


                end
            end
        end
    end	

end