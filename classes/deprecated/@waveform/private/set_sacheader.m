function header = set_sacheader(header,property, val)
   %set_sacheader    modify sac header variables
   %  modifiedheader = set_sacheader(originalheader, property, value)
   %  The properties are standards sac variables, and are not repeated here.
   %   examples: DELTA, B, NZYEAR, LEVEN, etc...
   %
   %    See also: waveform/private/readsacfile, waveform/private/sac2waveform,
   %    waveform/private/waveform2sacheader, waveform/private/writesac
   
   % VERSION: 1.1 of waveform objects
   % AUTHOR: Celso Reyes (celso@gi.alaska.edu)
   %    modified from Michael Thorne (4/2004)
   % LASTUPDATE: 9/2/2009
   
   
   property = deblank(upper(property));
   
   switch property
      case 'DELTA', header(1) = val;
      case 'DEPMIN', header(2) = val;
      case 'DEPMAX', header(3) = val;
      case 'SCALE', header(4) = val;
      case 'ODELTA', header(5) = val;
      case 'B', header(6) = val;
      case 'E', header(7) = val;
      case 'O', header(8) = val;
      case 'A', header(9) = val;
      case 'T0', header(11) = val;
      case 'T1', header(12) = val;
      case 'T2', header(13) = val;
      case 'T3', header(14) = val;
      case 'T4', header(15) = val;
      case 'T5', header(16) = val;
      case 'T6', header(17) = val;
      case 'T7', header(18) = val;
      case 'T8', header(19) = val;
      case 'T9', header(20) = val;
      case 'F', header(21) = val;
      case 'RESP0', header(22) = val;
      case 'RESP1', header(23) = val;
      case 'RESP2', header(24) = val;
      case 'RESP3', header(25) = val;
      case 'RESP4', header(26) = val;
      case 'RESP5', header(27) = val;
      case 'RESP6', header(28) = val;
      case 'RESP7', header(29) = val;
      case 'RESP8', header(30) = val;
      case 'RESP9', header(31) = val;
      case 'STLA', header(32) = val;
      case 'STLO', header(33) = val;
      case 'STEL', header(34) = val;
      case 'STDP', header(35) = val;
      case 'EVLA', header(36) = val;
      case 'EVLO', header(37) = val;
      case 'EVEL', header(38) = val;
      case 'EVDP', header(39) = val;
      case 'MAG', header(40) = val;
      case 'USER0', header(41) = val;
      case 'USER1', header(42) = val;
      case 'USER2', header(43) = val;
      case 'USER3', header(44) = val;
      case 'USER4', header(45) = val;
      case 'USER5', header(46) = val;
      case 'USER6', header(47) = val;
      case 'USER7', header(48) = val;
      case 'USER8', header(49) = val;
      case 'USER9', header(50) = val;
      case 'DIST', header(51) = val;
      case 'AZ', header(52) = val;
      case 'BAZ', header(53) = val;
      case 'GCARC', header(54) = val;
      case 'DEPMEN', header(57) = val;
      case 'CMPAZ', header(58) = val;
      case 'CMPINC', header(59) = val;
      case 'XMINIMUM', header(60) = val;
      case 'XMAXIMUM', header(61) = val;
      case 'YMINIMUM', header(62) = val;
      case 'YMAXIMUM', header(63) = val;
         
      case 'NZYEAR', header(71) = val;
      case 'NZJDAY', header(72) = val;
      case 'NZHOUR', header(73) = val;
      case 'NZMIN', header(74) = val;
      case 'NZSEC', header(75) = val;
      case 'NZMSEC', header(76) = val;
      case 'NVHDR', header(77) = val;
      case 'NORID', header(78) = val;
      case 'NEVID', header(79) = val;
      case 'NPTS', header(80) = val;
      case 'NWFID', header(82) = val;
      case 'NXSIZE', header(83) = val;
      case 'NYSIZE', header(84) = val;
      case 'IFTYPE', header(86) = val;
      case 'IDEP', header(87) = val;
      case 'IZTYPE', header(88) = val;
      case 'IINST', header(90) = val;
      case 'ISTREG', header(91) = val;
      case 'IEVREG', header(92) = val;
      case 'IEVTYP', header(93) = val;
      case 'IQUAL', header(94) = val;
      case 'ISYNTH', header(95) = val;
      case 'IMAGTYP', header(96) = val;
      case 'IMAGSRC', header(97) = val;
         
      case 'LEVEN', header(106) = val;
      case 'LPSPOL', header(107) = val;
      case 'LOVROK', header(108) = val;
      case 'LCALDA', header(109) = val;
         
      case 'KSTNM';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(111:118) = newname(1:8)';
      case 'KEVNM';
         newname = double(val);
         if size(newname) < 16;
            newname((length(val)+1):16) = 32;
         end
         header(119:134) = newname(1:16)';
      case 'KHOLE';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(135:142) = newname(1:8)';
      case 'KO';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(143:150) = newname(1:8)';
      case 'KA';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(151:158) = newname(1:8)';
      case 'KT0';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(159:166) = newname(1:8)';
      case 'KT1';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(167:174) = newname(1:8)';
      case 'KT2';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(175:182) = newname(1:8)';
      case 'KT3';
         newname = double(val);
         if size(newname) < 8;
            newname((length(val)+1):8) = 32;
         end
         header(183:190) = newname(1:8)';
      case 'KT4';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(191:198) = newname(1:8)';
      case 'KT5';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(199:206) = newname(1:8)';
      case 'KT6';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(207:214) = newname(1:8)';
      case 'KT7';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(215:222) = newname(1:8)';
      case 'KT8';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(223:230) = newname(1:8)';
      case 'KT9';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(231:238) = newname(1:8)';
      case 'KF';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(239:246) = newname(1:8)';
      case 'KUSER0';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(247:254) = newname(1:8)';
      case 'KUSER1';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(255:262) = newname(1:8)';
      case 'KUSER2';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(263:270) = newname(1:8)';
      case 'KCMPNM';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(271:278) = newname(1:8)';
      case 'KNETWK';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(279:286) = newname(1:8)';
      case 'KDATRD';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(287:294) = newname(1:8)';
      case 'KINST';
         newname = double(val);
         if size(newname) < 8; newname((length(val)+1):8) = 32; end
         header(295:302) = newname(1:8)';
   end %switch
end
