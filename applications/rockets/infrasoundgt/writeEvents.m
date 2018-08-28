function writeEvents(filepath, ev, array_distance_in_km, speed_of_sound)
fout = fopen(filepath, 'w');
fprintf(fout, 'Arrival Time,Pressure (Pa),Reduced Pressure (Pa.km),Infrasound Energy (J),P_SNR,Vertical Seismic Amplitude (um/s),Seismic Energy (J), S_SNR,Energy Ratio,mean correlation,time error (s),good event?,back azimuth (degrees),sound speed (m/s),predicted origin time,apparent speed, apparent speed error,apparent origin time\n');
for c=1:numel(ev)
    fprintf(fout, '"%s"', datestr(ev(c).FirstArrivalTime,'yyyy-mm-dd HH:MM:SS.FFF'));
    fprintf(fout,',');
    fprintf(fout, '%7.1f', median(ev(c).p2p(1:3)));
    fprintf(fout,',');
    fprintf(fout, '%7.1f', median(ev(c).reducedPressure));
    fprintf(fout,',');
    fprintf(fout, '%4.2e', ev(c).infrasoundEnergy);
    fprintf(fout,',');    
    fprintf(fout, '%5.1f', median(ev(c).snr(1:3)));
    fprintf(fout,',');
    fprintf(fout, '%7.1f', ev(c).p2p(6)/1000);
    fprintf(fout,',');
    fprintf(fout, '%4.2e', ev(c).seismicEnergy);
    fprintf(fout,',');       
    fprintf(fout, '%5.1f', ev(c).snr(6));
    fprintf(fout,',');
    fprintf(fout, '%5.1f', ev(c).infrasoundEnergy/ev(c).seismicEnergy);
    fprintf(fout,',');    
    fprintf(fout, '%4.2f', ev(c).meanCorr);
    fprintf(fout, ',');    
    fprintf(fout, '%7.3f', ev(c).meanSecsDiff);
    fprintf(fout, ',');    
    goodEvent = (ev(c).meanSecsDiff<0.001 && ev(c).meanCorr >= 0.7);% && ev(c).bestsoundspeed > 300.0 && ev(c).bestsoundspeed < 400.0);
    fprintf(fout, '%7.3f', goodEvent);    
    fprintf(fout, ',');
    if goodEvent
            fprintf(fout, '%6.1f', ev(c).bestbackaz);
    fprintf(fout,',');
    fprintf(fout, '%7.1f', ev(c).bestsoundspeed);
    fprintf(fout,',');
        daysDiff = (min(array_distance_in_km)*1000/ev(c).bestsoundspeed)/86400;
        fprintf(fout, '"%s"', datestr(ev(c).FirstArrivalTime-daysDiff,'yyyy-mm-dd HH:MM:SS.FFF'));
        fprintf(fout, ',');  
        fprintf(fout, '%7.1f', ev(c).apparentSpeed);
        fprintf(fout, ',');    
        fprintf(fout, '%7.1f', ev(c).apparentSpeedError);
        fprintf(fout, ',');    
        daysDiff = (min(array_distance_in_km)*1000/ev(c).apparentSpeed)/86400;
        fprintf(fout, '"%s"', datestr(ev(c).FirstArrivalTime-daysDiff,'yyyy-mm-dd HH:MM:SS.FFF'));        
    else  
            fprintf(fout, '');
    fprintf(fout,',');
    fprintf(fout, '');
    fprintf(fout,',');
        fprintf(fout, '');          
        fprintf(fout, '%7.1f', 0);
        fprintf(fout, ',');    
        fprintf(fout, '%7.1f', 0);  
        fprintf(fout, ',');    
        fprintf(fout, '');         
    end
    fprintf(fout, '\n');
    
end
fclose(fout);
    