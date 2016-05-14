function [optExists, value, vargs] = peel_option(vargs, searchValue, searchClass, minPos)
   optExists = false; value = [];
   if minPos > numel(vargs)
      return
   end
   switch searchClass
      case 'char'
         for n = minPos:numel(vargs)
            if ischar(vargs{n})
               if isempty(searchValue) || strcmp(searchValue,vargs{n})
                  optExists = true; value = vargs{n}; vargs(n) = [];
                  return
               end
            end
         end
      otherwise
         for n = minPos: numel(vargs)
            if isa(vargs{n},searchClass)
               if isempty(searchValue) || vargs{n} == searchValue
                  optExists = true; value = vargs{n}; vargs(n) = [];
                  return
               end
            end
         end
   end
end