hdistance1 = 1393.5;
hdistance2 = 1425.2;
sourceheight=0:500;
soundspeed=350.4;
pathlength1 = sqrt(hdistance1^2 + sourceheight.^2);
traveltime1 = pathlength1 ./ soundspeed;
pathlength2 = sqrt(hdistance2^2 + sourceheight.^2);
traveltime2 = pathlength2 ./ soundspeed;
apparentC = (hdistance2 - hdistance1)./(traveltime2-traveltime1);
plot(sourceheight, apparentC)
xlabel('Source Height (m)');
ylabel('Apparent sound speed (m/sec)')

figure
theta = 180 * atan(sourceheight./hdistance1) / pi;
plot(theta, apparentC)
xlabel('Incidence angle (degrees)');
ylabel('Apparent sound speed (m/sec)')