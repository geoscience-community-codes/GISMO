function c = computeSpeedOfSound(temperatureC, relativeHumidity)
c = 331.3 + 0.606 * temperatureC + 1.26 * relativeHumidity/100;