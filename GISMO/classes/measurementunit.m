classdef measurementunit
   %MEASUEMENTUNIT handles units integrated or differentiated in time
   %   munit = measurementunit('meters / sec');
   %   
   %  this tracks '/ sec' and '* sec' only.
   %  differentiation and integration are assumed to be with respect to
   %  time (in seconds)
   
   properties
      unitlabel = '';
      secondsExponent; % [Length Weight Time]
   end
   
   methods
      function munit = integrate(munit)
         munit.secondsExponent = munit.secondsExponent - 1;
      end
      function munit = diff(munit)
         munit.secondsExponent = munit.secondsExponent + 1;
      end
      function s = formattedtext(munit)
         if munit.secondsExponent == 0
            s = munit.unitlabel;
         else
            s = [munit.unitlabel ' * sec^{',num2str(munit.secondsExponent),'}'];
         end
      end
      
      function s = string(munit)
         if munit.secondsExponent == 0
            s = munit.unitlabel;
         else
            s = [munit.unitlabel ' * sec^',num2str(munit.secondsExponent)];
         end
      end
      
      function munit = measurementunit(unitlabel, secondsExponent)
         if exist('secondsExponent','var')
            munit.unitlabel = unitlabel;
            munit.secondsExponent = secondsExponent;
         else
            [munit.unitlabel, munit.secondsExponent] = measurementunit.parseFromText(unitlabel);
         end
         % strip out seconds from unit label, modifying
      end
   end
   methods(Static)
      function [units, secExp] = parseFromText(txt)
            lowertext = lower(txt);
            firstOccurrence = min([strfind(lowertext,'* sec') strfind(lowertext,'/ sec')]);
            if firstOccurrence
               secExp = numel(strfind(lowertext,'* sec')) - numel(strfind(lowertext,'/ sec'));
               units = strtrim(txt(1 : firstOccurrence - 1));
            else
               units = txt;
               secExp = 0;
            end
      end
   end %methods
   
end

