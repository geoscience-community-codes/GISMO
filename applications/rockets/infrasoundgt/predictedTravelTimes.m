%% compute predicted travel times for infrasound waves based on GPS coords & wind
%% also add lat, lon, distance and backaz fields to waveform objects
disp('Predicting travel times based on GPS coordinates and wind vector...')
fout = fopen(fullfile(figureOutDirectory, 'predictedTravelTimes.txt'), 'w');
fprintf(fout,'\n_______________________________________________\n');
fprintf(fout,'PREDICTED TRAVEL TIME BASED ON:\n');
fprintf(fout,'  sound speed(c) %.1fm/s\n', speed_of_sound);
fprintf(fout,'  wind speed     %.1fm/s\n', wind_speed);
fprintf(fout,'  wind direction %.1f degrees\n', wind_direction);
fprintf(fout,'------\t--------\t-----------\t----------\t-----------\n');
fprintf(fout,'Channel\tDistance\tBackAzimuth\tTravelTime\tc_effective\n');
fprintf(fout,'------\t--------\t-----------\t----------\t-----------\n');
for c=1:length(lat)
    [arclen(c), backaz(c)] = distance(lat(c), lon(c), source.lat, source.lon, 'degrees');
    arclen(c) = deg2km(arclen(c))*1000;
    effective_speed(c) = speed_of_sound + wind_speed * cos(deg2rad( (180+backaz(c)) - wind_direction) );
    predicted_traveltime_seconds(c) = arclen(c)/effective_speed(c);
    fprintf(fout,'%s\t%.1fm\t\t%.1f degrees\t%.3fs\t\t%.1fm/s\n',get(w(c),'channel'), arclen(c), backaz(c), predicted_traveltime_seconds(c),effective_speed(c));
    w(c) = addfield(w(c), 'lat', lat(c));
    w(c) = addfield(w(c), 'lon', lon(c));
    w(c) = addfield(w(c), 'distance', arclen(c));
    w(c) = addfield(w(c), 'backaz', backaz(c));
end
fprintf(fout,'_______________________________________________\n');
fprintf(fout,'Program name: %s\n',mfilename('fullpath'));
fclose(fout);