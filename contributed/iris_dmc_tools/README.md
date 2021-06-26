# irisFetch-matlab

## Summary

The MATLAB file irisFetch.m provides an interface for access to data stored within the IRIS-DMC as well as other data centers that implement FDSN web services.

## Description

The file irisFetch.m provides a collection of routines that allow access to:

* seismic trace data, containing information similar to a basic SAC file
* station metadata, providing details down to the instrument response level
* event parameters, including magnitudes and locations of earthquakes

## Setup and Installation

The irisFetch.m script requires a Java JAR file to be present in the MATLAB java class path in order to communicate with the FDSN web services.  The most recent version of the JAR file can be obtained from the IRIS software download page: http://ds.iris.edu/ds/nodes/dmc/software/downloads/IRIS-WS/

For convenience, the user may elect to add a line similar to the one below to their startup.m file to automatically load the JAR file when MATLAB starts.
```
javaaddpath('/path/to/jar/IRIS-WS.jar')
```

## Usage and Examples

The data request methods for irisFetch address a broad range of needs for station metadata, earthquake hypocentral parameters, and seisimc trace data.  For more detailed information about these methods and usage examples, please refer to the irisFetch software manual page: http://ds.iris.edu/ds/nodes/dmc/software/downloads/irisFetch.m/2-0-10/manual/

Additionally, several example requests for retrieving and plotting trace or event data may be seen by running the following command from MATLAB:
```
>> irisFetch.runExamples
```
