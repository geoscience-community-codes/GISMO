---
title: "GISMO: A MATLAB Toolbox for Seismic and Infrasound Data Analysis"
version: "1.20b"
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
    orcid: 0000-0000-0000-0000   # Update if Mike provides one
    affiliation: "3"
  - name: Dane Morrow Ketner
    orcid: 0000-0002-1610-0773   # Placeholder until confirmed
    affiliation: "4"
affiliations:
  - name: University of South Florida
    index: 1
  - name: Roche Diagnostics, Switzerland
    index: 2
  - name: University of Alaska Fairbanks
    index: 3
  - name: U.S. Geological Survey — Alaska Volcano Observatory
    index: 4
date: 2025-12-01
bibliography: paper.bib
---

# Summary

**GISMO is an open-source MATLAB toolbox for analyzing seismic and infrasound waveform data**, providing an extensible object-oriented framework designed to support earthquake seismology, volcano monitoring, microseismic analysis, and related geophysical investigations.

Developed since 2008, GISMO integrates three major components:

1. **The Waveform Suite** (Reyes)  
2. **The Correlation Suite** (West)  
3. **The Catalog Suite** (Thompson)

GISMO has been adopted by volcano observatories, national seismic networks, university research groups, and seismology teaching programs worldwide. It has been used to prototype real-time monitoring tools, analyze waveform similarity, and explore complex volcanic signals such as tremor, swarms, and pyroclastic flows.

GISMO is hosted on GitHub
(https://github.com/geoscience-community-codes/GISMO)
with documentation on the GISMO website
(https://geoscience-community-codes.github.io/GISMO/).

# Statement of Need

MATLAB has been heavily used within the seismological community, both for research workflows and prototyping real-time monitoring tools, leveraging MATLAB's numerical environment, mature toolboxes, and ease of prototyping. However, **prior to GISMO, MATLAB lacked a coherent object-oriented infrastructure for seismic data**, requiring researchers to repeatedly solve the same fundamental problems:

- read diverse seismic waveform data and catalog formats,
- attach and manage waveform metadata,
- process and visualize continuous waveforms,
- write STA/LTA detectors,
- correlate waveforms or perform template matching,
- export results to formats compatible with operational systems.

**GISMO provides these capabilities through a unified class-based architecture**, in much the same way that ObsPy provides a foundational ecosystem for Python seismology (Krischer et al., 2015). GISMO slightly predates ObsPy and remains the principal MATLAB-based toolkit offering:

- fully object-oriented support for waveforms and instrument metadata,
- automatic integration with FDSNWS, Antelope/CSS3.0, Earthworm, SAC, SEISAN, and MiniSEED,
- tools for catalog generation, event rates, cumulative energy release, RSAM, and reduced displacement
- robust correlation and clustering tools,
- high-level visualizations including drumplots, multistation spectrograms, and catalog and event rate plots.

By providing this foundation, GISMO dramatically reduces the development effort required to build new seismic data workflows, prototype algorithms, or integrate legacy MATLAB systems with modern formats such as FDSN web services, StationXML, and QuakeML.

# Features

### Waveform Handling
- Object-oriented `waveform` class    
- Metadata-aware detrending, tapering, resampling, windowing  
- Instrument response removal and deconvolution tools

### Signal Processing
- STA/LTA and amplitude-duration detectors  
- Bandpass, highpass, lowpass, and notch filters  
- FFT and spectral analysis  
- Multi-station spectrograms  
- RSAM/SSAM generation and plotting

### Catalog and Event Tools
- Tools for reading SEISAN and Antelope catalogs  
- Detection and arrival objects  
- Catalog combination, filtering, declustering  
- Event rate, Gutenberg–Richter, and cumulative energy plots

### Correlation and Template Matching
- Cross-correlation  
- Similarity matrices and clustering  
- Template matching for tremor, repetitive earthquakes, and volcanic drumbeats

### Polarization analysis
- Rotation and polarization analysis for 3-component stations

### Data Import and Export
- Read/write support for Antelope/CSS3.0 databases 
- Earthworm/Winston waveserver  
- SEISAN waveform and catalog (REA/Nordic) support  
- MiniSEED import/export  
- FDSNWS waveform and event/station metadata downloaders

### Visualization
- Interactive waveform browsing  
- Drumplots
- Spectrograms  
- Catalog summary plots  
- Event rate plots

### Documentation and Tutorials
- Extensive GitHub wiki with Getting Started Guide  
- Teaching examples for computational seismology  
- Historical notes on GISMO’s development  

# Community and Impact

GISMO has been used by:

- Alaska Volcano Observatory  
- Universities in the U.S., U.K., Europe, Latin America, and Japan  

Usage metrics include:

- **~400 members** in the GISMO Users Group  
- **~6,500 downloads** from MATLAB File Exchange  
- **>11,000 downloads** for the earlier Waveform Suite  
- Numerous untracked GitHub clones and release downloads  

GISMO has supported research on volcanic earthquakes and tremor, pyroclastic flows, tectonic earthquakes, mining blasts, infrasound sources, and rocket launches.

# Example

```matlab
% Load a MiniSEED file
w = waveform('mydata.mseed');
plot(w);

% Load from an Antelope CSS3.0 database
db = datasource('antelope', '/opt/antelope/data/db/demo');
w = waveform(db, 'STATION', 'BHZ', '2025-01-01', '2025-01-02');
plot(w);

% Load from IRIS/EarthScope FDSNWS
ds = datasource('irisdmcws');
ctag = ChannelTag('AV', 'RSO', '--', 'EHZ');
w = waveform(ds, ctag, '2009/03/21', '2009/03/22');
plot(w);

% Process
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

% Catalog
mainshocktime = datenum('2011/03/11 05:46:24');
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
GISMO requires MATLAB R2016b or later.
```bash
git clone https://github.com/geoscience-community-codes/GISMO.git
```

Full installation instructions and tutorials are provided on the GitHub Wiki.

# Acknowledgements

We thank:
	•	Martin Mityska for ReadMSEEDFast.m and François Beauducel for rdmseed.m, on which the former is based.
	•	Colleagues at UAF and USGS AVO who contributed early ideas and feedback
	•	The many users who reported issues, contributed patches, and helped refine the toolbox
