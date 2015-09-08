function binsize = autobinsize(daysdiff)
    % Copied after modgiseis.xpy/autobinsize
    % Try and keep to around 100 bins or less
    if daysdiff <= 2.0/24  % less than 2 hours of data, use a binsize of 1 minute
        binsize = 1.0/1440;
    elseif daysdiff <= 4.0  % less than 4 days of data, use a binsize of 1 hour
        binsize = 1.0/24;
    elseif daysdiff <= 100.0  % less than 100 days of data, use a binsize of 1 day
        binsize = 1.0;
    elseif daysdiff <= 700.0 % less than 700 days of data, use a binsize of 1 week
        binsize = 7.0;
    elseif daysdiff <= 365.26 * 23 % less than 23 years of data, use a binsize of (approx) 1 month
        binsize = 365.26/12;
    else
        binsize = 365.26; % otherwise use a binsize of 1 year
    end
    disp(sprintf('selecting a binsize of %e days',binsize));
end