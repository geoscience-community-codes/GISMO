function publish_cookbooks()

    %% Catalog_cookbook
    cleanup()
    mfile = 'Catalog_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true);

    %% correlation_cookbook
    cleanup()
    mfile = 'correlation_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true);

    %% drumplot_cookbook
    cleanup()
    mfile = 'drumplot_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true);  
    
    %% EventRate_cookbook
    cleanup()
    mfile = 'EventRate_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true);
    cleanup()

    %% rsam_cookbook
    cleanup()
    mfile = 'rsam_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)

    %% waveform_cookbook
    cleanup()
    mfile = 'waveform_cookbook';
    outdir = fullfile(GISMO, '..', 'GISMO.website', 'cookbook_results');
    mkdir(outdir);
    htmlfile = publish(mfile, 'format', 'html', 'outputDir', outdir, 'createThumbnail', true)

end
%%

