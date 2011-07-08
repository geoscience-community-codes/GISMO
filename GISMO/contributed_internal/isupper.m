function r = isupper(str)
for c=1:length(str)
	asc = cast(str(c), 'uint8');
	if (asc >= 65 && asc <= 90)
		r(c) = 1;
	else
		r(c) = 0;
	end
end
		
