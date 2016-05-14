function [units, data_description] = segtype2units(unitCode)
   %segtype2units   retrieves unit and description based on the segtype code
   %'segtype' in antelope datasets indicate the natural units of the detector
   persistent codeKey
   if isempty(codeKey)
      codeKey = createCodeKey();
   end
   if codeKey.isKey(unitCode)
      details = codeKey(unitCode);
      units = details{1};
      data_description = details{2};
   else
      [units, data_description] = deal('null');
   end
   
   function SU = createCodeKey()
      %createSegUnits   creates a map  where SU(char) = {units, data_description}
      SU = containers.Map;
      SU('A') = {'nm / sec / sec','acceleration'};
      SU('B') = {'25 mw / m / m','UV (sunburn) index(NOAA)'};
      SU('D') = {'nm', 'displacement'};
      SU('H') = {'Pa','hydroacoustic'};
      SU('I') = {'Pa','infrasound'};
      SU('J') = {'watts','power (Joulses/sec) (UCSD)'};
      SU('K') = {'kPa','generic pressure (UCSB)'};
      SU('M') = {'mm','Wood-Anderson drum recorder'};
      SU('P') = {'mb','barometric pressure'};
      SU('R') = {'mm','rain fall (UCSD)'};
      SU('S') = {'nm / m','strain'};
      SU('T') = {'sec','time'};
      SU('V') = {'nm / sec','velocity'};
      SU('W') = {'watts / m / m', 'insolation'};
      SU('a') = {'deg', 'azimuth'};
      SU('b') = {'bits/ sec', 'bit rate'};
      SU('c') = {'counts', 'dimensionless integer'};
      SU('d') = {'m', 'depth or height (e.g., water)'};
      SU('f') = {'micromoles / sec / m /m', 'photoactive radiation flux'};
      SU('h') = {'pH','hydrogen ion concentration'};
      SU('i') = {'amp','electric curent'};
      SU('m') = {'bitmap','dimensionless bitmap'};
      SU('n') = {'nanoradians','angle (tilt)'};
      SU('o') = {'mg/l','diliution of oxygen (Mark VanScoy)'};
      SU('p') = {'percent','percentage'};
      SU('r') = {'in','rainfall (UCSD)'};
      SU('s') = {'m / sec', 'speed (e.g., wind)'};
      SU('t') = {'C','temperature'};
      SU('u') = {'microsiemens/cm','conductivity'};
      SU('v') = {'volts','electric potential'};
      SU('w') = {'rad / sec', 'rotation rate'};
      SU('-') = {'null','null'};
   end
end
      