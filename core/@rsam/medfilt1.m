function rsamobj = medfilt1(rsamobj, nsamples_to_average_over)
% MEDFILT1 Median filter for RSAM objects
% For removing outliers due to transient events, or telemetry spikes
    for c = 1:numel(rsamobj)
        if nargin==1
            nsamples_to_average_over = 3;
        end
        rsamobj(c).data = medfilt1(rsamobj(c).data, nsamples_to_average_over);
    end
end