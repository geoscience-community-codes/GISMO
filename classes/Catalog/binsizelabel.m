function binsize_str = binsizelabel(binsize)
    binsize_str = ''; 
    if binsize == 1.0/1440
        binsize_str = 'per minute';
    elseif binsize == 1.0/24
        binsize_str = 'per hour';
    elseif binsize == 1.0 
        binsize_str = 'per day';
    elseif binsize == 7.0
        binsize_str = 'per week';
    elseif binsize >= 28 & binsize <=31 
        binsize_str = 'per month';
    elseif binsize >= 365 & binsize <= 366
        binsize_str = 'per year';
    end  
    
    %disp(sprintf('binsize label',binsize_str));
end