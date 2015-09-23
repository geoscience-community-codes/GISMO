function result = saveImageFile(arg1, arg2, arg3);
% saveImageFile(IMGDIR, fname, res);
% saveImageFile(IMGFULLFILEPATH, res);
% res=200 for spectrograms
global paths PARAMS; % we need to knwo the value of PARAMS.mode

debug.printfunctionstack('>');

result = 0;
switch nargin
	case 2,
		% GTHO 20121101: Replacing basename with fileparts
		%[fname, IMGDIR] = basename(arg1); 
		[IMGDIR, fname] = fileparts(arg1); 
		outpath = arg1;
		res = arg2;
	case 3,	
		[IMGDIR, fname] = deal(arg1, arg2);
		outpath = fullfile(arg1, sprintf('%s.png',arg2));
		res = arg3;
    otherwise,
        debug.print_debug(0, 'could not save image file - wrong number of arguments')
        return;
end

if ~exist(IMGDIR,'dir')
	mkdir(IMGDIR);
end

try
	% Save the image file
	print(gcf, '-dpng', sprintf('-r%d',res), outpath );

	% Lock the output directory if in archive mode - it means we do not want to delete these files ever
	if strcmp('PARAMS.mode','archive') 
		system(sprintf('touch %s/lock',IMGDIR));
	end

	% Did our image file actually get saved?
	if exist(outpath, 'file')
		debug.print_debug(1, sprintf('%s: Saved image file %s',datestr(utnow),outpath) );
		result = 1;
	else
		debug.print_debug(1, sprintf('%s: Image file %s was not created',datestr(utnow),outpath));
	end
catch
	debug.print_debug(0, sprintf('%s: Could not save the image file %s',datestr(utnow),outpath));
end

%print_debug(sprintf('< %s',mfilename),2);
debug.printfunctionstack('<');

