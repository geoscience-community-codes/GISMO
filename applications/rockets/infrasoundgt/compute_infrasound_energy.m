function e = compute_infrasound_energy(dataInPascals, samplingFrequency, distanceInMetres, densityAir, speed_of_sound);
% densityAir = 1.225; % (kg/m3)
dimensionlessEnergy = dataInPascals.^2 / samplingFrequency;
e = 2 * pi * distanceInMetres^2 * dimensionlessEnergy / (densityAir * speed_of_sound);
