
global gismopath TESTDATA

%% Catalog_cookbook
close all
mfile = 'Catalog_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end

%% correlation_cookbook
close all
mfile = 'correlation_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end

%% drumplot_cookbook
close all
mfile = 'drumplot_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end 

%% EventRate_cookbook
close all
mfile = 'EventRate_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end 

%% rsam_cookbook
close all
mfile = 'rsam_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end 

%% waveform_cookbook
close all
mfile = 'waveform_cookbook';
outdir = fullfile(gismopath, '..', 'GISMO.website', 'cookbook_results');
mkdir(outdir);
try
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)
end 



