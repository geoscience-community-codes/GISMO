%publish_tutorials

%% Catalog_cookbook
mfile = 'Catalog_cookbook';
outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
publish(mfile, 'format', 'html', 'outputDir', 'outdir', 'createThumbnail', true);
close all
clc

%% rsam_cookbook
mfile = 'rsam_cookbook';
outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
% close all
% clc