---
title: "GISMO: A MATLAB Toolbox for Seismic and Infrasound Data Analysis"
version: "v1.21.0"
tags:
  - MATLAB
  - seismology
  - volcano seismology
  - earthquake monitoring
  - infrasound
  - waveform analysis
  - signal processing
  - geophysics
authors:
  - name: Glenn Thompson
    orcid: 0000-0002-9173-0097
    affiliation: "1"
  - name: Celso Reyes
    orcid: 0000-0002-0034-8889
    affiliation: "2"
  - name: Michael E. West
    orcid: 0000-0000-0000-0000  # Update if Mike provides one
    affiliation: "2"
affiliations:
  - name: University of South Florida
    index: 1
  - name: University of Alaska Fairbanks
    index: 2
date: 2025-12-01
bibliography: paper.bib
---

## Summary

**GISMO is an open-source MATLAB toolbox for analyzing seismic and infrasound waveform data**, providing an extensible object-oriented framework designed to support earthquake seismology, volcano monitoring, microseismic analysis, and related geophysical investigations.

Developed since 2008, GISMO integrates three major components:

- **The Waveform Suite** (Reyes)  
- **The Correlation Suite** (West)  
- **The Catalog & Event-Rate Suite** (Thompson)  

GISMO has been adopted by volcano observatories, national seismic networks, university research groups, and seismology teaching programs worldwide. It has been used to prototype real-time monitoring tools, analyze waveform similarity, and explore complex volcanic signals such as tremor, swarms, and pyroclastic flows.

GISMO is hosted on GitHub  
(https://github.com/geoscience-community-codes/GISMO)  
with documentation on the GISMO website  
(https://geoscience-community-codes.github.io/GISMO/).

GISMO remains a widely used MATLAB-based seismic analysis environment for both research and operational monitoring applications.

## Statement of Need

MATLAB has been heavily used within the seismological community, both for research workflows and prototyping real-time monitoring tools, leveraging MATLAB's numerical environment, mature toolboxes, and ease of prototyping. However, **prior to GISMO, MATLAB lacked a coherent object-oriented infrastructure for seismic data**, requiring researchers to repeatedly solve the same fundamental problems:

- Reading a variety of seismic waveform and catalog formats  
- Managing waveform metadata (station, channel, instrument response, time tags)  
- Processing and visualizing continuous waveforms  
- Implementing STA/LTA detectors, RSAM, event-rate analysis, and spectral analysis  
- Performing waveform correlation and template matching across large datasets  
- Exporting results in formats compatible with operational systems  

**GISMO provides these capabilities through a unified class-based architecture**, in much the same spirit as what non-MATLAB libraries (e.g. in Python) offer. GISMO slightly predates the widespread adoption of those tools, and remains the principal MATLAB-based toolkit offering:

- fully object-oriented support for waveforms and instrument metadata,  
- automatic integration with FDSNWS, Antelope/CSS3.0, Earthworm, SAC, SEISAN, and MiniSEED,  
- tools for catalog generation, event rates, cumulative energy plots, RSAM, and reduced displacement,  
- robust correlation and clustering tools,  
- high-level visualizations including drumplots, multistation spectrograms, and catalog/event-rate plots.  

While modern Python tools such as ObsPy now dominate cloud-based and large-scale seismic data services, a substantial body of operational monitoring systems, teaching laboratories, and historical observatory workflows remain MATLAB-based. GISMO continues to serve this community by providing a stable, object-oriented seismic analysis environment for MATLAB users, particularly in contexts where **legacy telemetry systems, historical datasets, or long-standing MATLAB workflows** must be maintained for reproducibility and operational continuity.

By providing this foundation, GISMO dramatically reduces the development effort required to build new seismic data workflows, prototype algorithms, or integrate legacy MATLAB systems with modern formats such as FDSN web services, StationXML, and QuakeML.

In addition to supporting contemporary research and teaching, GISMO plays a critical role in enabling the reproducible re-analysis of historical seismic datasets that were originally processed using MATLAB-based observatory workflows. This includes legacy volcano-monitoring archives, early digital telemetry systems, and long-term seismic catalogs that remain operationally relevant today.

## What GISMO Provides

Though full software documentation and API references are maintained in the GitHub repository and online wiki, a summary of major GISMO capabilities includes:

### - Waveform Handling  
- Object-oriented `waveform` class  
- Metadata-aware detrending, tapering, resampling, windowing, and instrument response removal  
- Support for a wide range of input/output formats: SAC, MiniSEED/SEED, SEISAN, Antelope/CSS3.0, Earthworm/Winston, FDSNWS (irisFetch, when used with compatible MATLAB versions)  

### - Signal Processing & Analysis  
- STA/LTA and amplitude-duration detectors  
- Broad-band, bandpass, high-pass, low-pass, and notch filtering  
- FFT and spectral analysis, amplitude spectra and spectrograms  
- Multi-station spectrograms and helicorder (drumplot) visualizations  
- RSAM/SSAM generation and plotting  
- Reduced-displacement (cumulative energy) computation and event-rate analysis  

### - Catalog and Event-Rate Tools  
- Reading and writing SEISAN, Antelope, and other catalog formats  
- Filtering, declustering, catalog combination/import/export  
- Event-rate computation, Gutenberg–Richter statistics, cumulative energy plots, and related event-rate visualizations  

### - Correlation and Template Matching  
- Cross-correlation of large waveform datasets (tens to thousands of events)  
- Similarity matrices, clustering, hierarchical tree analysis  
- Template-matching, stacking, residual extraction  
- Tools optimized for tremor detection, volcanoes, repeating earthquakes, and microseismicity  

### - Polarization & Three-Component Analysis  
- Support for 3-component (3C) waveform data  
- Rotation, polarization, and beamforming analyses  

### - Data Import/Export & Metadata Management  
- Reading/writing continuous seismic data, catalog data, and RSAM data  
- Auto-handling of metadata: station, network, channel, instrument response, sample rate, start time, units  
- Conversion to standard formats where needed  
- Built-in support for legacy telemetry and older observatory formats  

### - Visualization & Interactivity  
- Time-series plotting, overplotting multiple waveforms  
- Spectrograms, amplitude spectra  
- Drumplots / helicorder plots (multi-day / high-resolution)  
- Catalog summary and event-rate plots  
- Integration with typical MATLAB workflows and figure tools  

### - Documentation, Tests, and Tutorials  
- Extensive GitHub wiki with “Getting Started” guide, usage examples, cookbooks (tutorial scripts)  
- Full suite of unit tests (developed over many years) to ensure functionality and regression safety  
- Demonstrations, example data, and reproducible workflows for teaching and research  
- A fully documented **testing, documentation, and release workflow** ensuring reproducibility, regression safety, web documentation generation, and archival via Zenodo  

## Example Usage

```matlab
% Load a MiniSEED file
w = waveform('mydata.mseed');
plot(w);

% Load from an Antelope CSS3.0 database
db = datasource('antelope', '/opt/antelope/data/db/demo');
w = waveform(db, 'STATION', 'BHZ', '2025-01-01', '2025-01-02');
plot(w);

% Legacy FDSN download via irisFetch (MATLAB R2022b and earlier only)
v = ver('MATLAB'); 
yr = str2double(v.Release(2:5));

if yr <= 2022
    ds = datasource('irisdmcws');
    ctag = ChannelTag('AV', 'RSO', '--', 'EHZ');
    w = waveform(ds, ctag, '2009/03/21', '2009/03/22');
end

% Process the waveform
w2 = fillgaps(w, 'interp');
w3 = detrend(w2);
w_filt = filfilt(filterobject('h', 0.5, 2), w3);
plot(w_filt);

% 60-s RSAM data
rsamobj = waveform2rsam(w_filt, 'mean', 60.0);
rsamobj.plot();

% Spectrogram
s = spectrogram(w_filt, 'wlen', 256, 'overlap', 128);
plot(s);

% Catalog example (e.g. tsunami aftershock region)
mainshocktime = datenum('2011-03-11 05:46:24');
tohoku_events = Catalog.retrieve('iris', ...
            'radialcoordinates', [38.297 142.372 km2deg(200)], ...
            'starttime', mainshocktime - 1, ...
            'endtime', mainshocktime + 1);
tohoku_events.plot();

% Event rate (hourly)
eventrateObject = tohoku_events.eventrate('binsize', 1/24);
eventrateObject.plot();

```

# Installation
GISMO is developed and tested on MATLAB version R2022b, with the Signal Processing toolbox installed. 
IRIS Web Services via irisFetch.m rely on a Java library that is incompatible with MATLAB R2023a and later due to changes in MathWorks’ JVM.
```bash
git clone https://github.com/geoscience-community-codes/GISMO.git
```
Certain legacy data-access components (specifically IRIS/EarthScope waveform retrieval via irisFetch.m) rely on the IRIS Java Web Services library, which is not compatible with MATLAB R2023a and later due to JVM changes introduced by MathWorks. EarthScope formally deprecated irisFetch for MATLAB ≥ R2023a in August 2024 \cite{irisfetch2024}.

Users requiring modern FDSN web service access from newer MATLAB releases are encouraged to use Python-based tools such as ObsPy.

Full installation instructions, platform notes, and tutorials are provided on the GISMO GitHub Wiki.

## Software Testing, Documentation, and Archival

GISMO includes a comprehensive and continuously evolving suite of:
	•	Unit tests
	•	Cookbook-based executable tutorials
	•	End-to-end training workflows

These components are integrated into a structured release pipeline that:
	1.	Executes all tests, cookbooks, and training scripts
	2.	Regenerates the full web documentation using m2html
	3.	Publishes updated documentation to the gh-pages branch
	4.	Creates tagged software releases on GitHub
	5.	Archives each release with a versioned DOI on Zenodo

The full reproducible workflow is documented in
RELEASE_AND_DOCUMENTATION_WORKFLOW.md in the GISMO repository.

## Acknowledgements

We thank:
•	Martin Mityska for ReadMSEEDFast.m and François Beauducel for rdmseed.m, on which the former is based.
•	Colleagues at UAF and USGS AVO who contributed early ideas and feedback
•	The many users who reported issues, contributed patches, and helped refine the toolbox
