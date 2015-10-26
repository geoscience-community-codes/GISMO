function [mean_m1, b1, sig1, av2] =  bmemag(mag);
    %BMEMAG
    maximum_mag = max(mag );
    minimum_mag = min(mag );
    if minimum_mag > 0 ; minimum_mag = 0 ; end

    % calculate the mean magnitude, b(mean) and std
    n = length(mag );
    mean_m1 = mean(mag );
    b1 = (1/(mean_m1-min(mag -0.05)))*log10(exp(1));
    sig1 = (sum((mag -mean_m1).^2))/(n*(n-1));
    sig1 = sqrt(sig1);
    sig1 = 2.30*sig1*b1^2;            % standard deviation
    %disp ([' b-value segment 1 = ' num2str(b1) ]);
    %disp ([' standard dev b_val_1 = ' num2str(sig1) ]);
    av2 = log10(length(mag ))+b1*min(mag );
end