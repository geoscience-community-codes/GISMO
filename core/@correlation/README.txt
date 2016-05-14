% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$
############################


Contents
	- Install notes
	- Disclaimer
	- Release notes
	- To do list



############################
#     Install notes        #	
############################

[ *** Most of the install notes have been superceded by including the correlation toolbox in the GISMO suite. If the GISMO suite if tools is being installed, then the correlation toolbox should install automatically. *** ]

Uncompress the distribution into a directory where you keep matlab codes. The correlation toolbox is written according to the protocols of a matlab object. In order to use a matlab object, all directories beginning with "@" must be in the matlab path. This can be done one of three ways: (1) select the FILE pulldown menu and then SET PATH; (2) edit your startup.m files; or (3) use the addpath command to include the path for just a single matlab session. You can test whether the correct path is set by entering HELP CORRELATION. If you see the correlation help page then the path has been set correctly. If you have downloaded the waveform suite as well, it is important to first consult the waveform toolbox documentation (and test dat importing directly) to ensure that you have set up the necessary components to interface with your desired data source. The cookbook in @correlation/html/correlation_cookbook.html (or .pdf) provides an overview of basic features. Detailed useage information can be obtained from the help pages.

I have made considerable effort to include good documentation. However I am sure it is incomplete and/or lacking. Please let me know what problems you find or if you have trouble getting started with the correlation toolbox. I would be happy to help if I can and I will certainly use any comments to improve the future generations of the code.


############################
#      Disclaimer          #	
############################
This is beta software. There ARE bugs. This software was written initially for in-house use in the Alaska Volcano Observatory and the Geophysical Institute at the University of Alaska Fairbanks. There was enough interest as it developed to warrant packaging it for distribution to other researchers pursuing similar topics. To get the full use of this toolbox, it is important to understand something about how the underlying waveform object operates. It is advisable to get a feel for how the waveform objects "thinks" before moving on to correlation objects, as the correlation toolbox is built on top of waveform. If you write interesting extensions to this code (really quite easy) let me know and I will integrate them into the toolbox. 

Use at your own risk. The author assumes no liability for code that is confusing, misleading, or just plain wrong though reports of bugs are always welcomed. This software may be distributed freely and edited at will. For any productive uses, I would appreciate if the code is cited.

Michael West
November 2007




############################
#   Release notes v2.0 +   #
############################

For code modifications since 2009, see the SVN repository change log:
https://code.google.com/p/gismotools/source/list


June 2009

Note that future updates to correlation will not be tracked through a formal release number. Following 2.0, changes in the correlation toolbox will be tracked by SVN revision number. This is a more honest accounting of how the correlation toolbox is actually maintained.

GETCLUSTERSTAT function added to extract relevent parameters from the CLUSTER field. (January 2, 2009)

This release warrants 2.0 because there have been substantial improvements to the correlation data calls and the actual CORRELATION constructor itself. Most of these changes have been made to make use of the new DATASOURCE and SCNLOBJECT objects and WAVEFORM version 1.8 which makes use of them. This allows much more flexible loading of waveforms and in many cases, vastly improved speed. Users are strongly encouraged to invest a few minutes to understand these tools. While these my appear to be more work on the surface, the power they bring justifies the code changes. Older function calls to CORRELATION work. However they are unlikely to be maintained in the future.

New WAVEFORM function and CORRELATION uageage to allow waveforms to be quickly extracted from a correlation obejct and replaced, presumeably after manipulation. See HELP CORRELATION/WAVEFORM.

Demo dataset upgraded to use scnlobjects. See CORRELATION('DEMO')

Default iterferogram plotting no longering normalizes by trace amplitudes. If this is important, use the NORM command before plotting.

New TAPER, SIGN, HILBERT, DETREND, INTEGRATE and DIFF functions added. These are mostly wrappers around the WAVEFORM versions of the same.

CORRELATION_COOKBOOK was moved outside of the toolbox and into GISMO/contributed.



############################
#   Release notes v1.6     #
############################
November 2008


An option in ADJUSTTRIG which makes use of event clusters is included by not completed, nor ready for use. In the works ...

Revised the interferogram plotting options such that plots invoking the 'LAG' style use a shaded coloring scheme to show the lag and correlation value concurrently. A red-yellow-blue hus represents the lag time relative to the reference trace. These colors are progressively faded to represent the correlation value.

Bug fix in ADJUSTTRIG when using the timeshift feature.


############################
#   Release notes v1.5     #
############################
March 2008

revised LINKAGE, CLUSTER and dendrogram plotting routines to minimize references to the obscure concept of dissimilarity. Since clusters in the correlation toolbox are almost always based on the idea of correlation, these functions were revised to operate directly on correlation values. This is a hack because the underlying Matlab routines deal with dissimilarity. The LINK field still stores values as dissimilarity. However the two main (only?) uses of the linkage field (to create clusters and to plot dendrogram) now work natively with correlation values.

the CLUSTER routine was modified so that when used as CLUSTER(c,CUTOFF), CUTOFF is now given as an inter-cluster correlation vlaue instead of dissimilarity. In practice, CUTOFF has become 1-CUTOFF. THIS IS A BREAK (THOUGH MINOR) IN BACKWARD COMPATIBILITY.

added a default use for the most common LINKAGE method (average). Now c=LINKAGE(c) is the same as c=LINKAGE(c,'average').

the dendrogram plotting routine was modified to display "inter-cluster correlation" instead of dissimilarity. All that was really changed in xais labels, the orientation of the x axis and the xlabel. The change is important, but hopefully it is a shift toward a more intuitive concept. If the CLUST field is filled, then the cluster number is now included on the dendrogram plot Y-axis.


############################
#   Release notes v1.4     #
############################
October 30, 2007
fixed bug in align and stack routines that could introduce traces of different lengths.


############################
#   Release notes v1.3     #
############################
August 30, 2007

Added direct access to the correlation README and COOKBOOK texts from the correlation function. 

Changed PLOT so that station names and channels are displayed on the Y-axis when multiple stations are present. PLOT makes some attempt to determine whether the data represent an "event gather" or a "receiver gather".

Revised XCORR routine to adds polynomial interpolation of lag and correlation values to estimate lag times with sub-sample precision. By default XCORR still estimates lag time to the nearest sample only. However, sub-sample interpolation is now available using the INTERP flag for XCORR. Interpolation requires about 30-40% more CPU time, which is the reason it is not being made default dehavior. However for earthquake relative relocation and coda wave interferometry sub-sample precision is advantageous. It has been made the default behavior in the interferogram routine.
 

############################
#   Release notes v1.2     #	
############################
August 10, 2007

New function INTERFEROGRAM returns correlation and lag information as a function of trace time.

New capability to read in data from CORAL data structure into a correlation object. 

New plot routine 'interfer' to plot the output of the INTERFEROGRAM function.

Overwrite of colormap function to include standard color maps for correlation and lag plots. New color map used for half-tone version of correlation color map.

Update of XCORR 'row' method now fills in corr and lag fields with a matrix of NaNs if they do not already exist.

New function CHECK tests to for similar start time offsets, frequencies, data_lengths, etc. There may be some overlap between this function and what is hard coded into some of the functions.


############################
#   Release notes v1.1     #	
############################
April 2007

This is the first public release of the waveform correlation toolbox. It is a significant change from earlier versions. A significant change in v1.x is the internal use of the @waveform object written by Celso Reyes. Though I was loath to tackle this retrofit, the end result is much stronger for it.


MAJOR CHANGES from v.0 (THAT BREAK BACKWARD COMPATIBILITY):
-------------------------------------------
Correlation object rewritten to store seismograms as waveform objects. Correlation object fields WAVES, Fs, and START have been removed and replaced with a single WAVEFORM field. Preserving original waveform objects makes better use of the underlying waveform toolbox and allows arbitrary information stored as waveform properties, such as station names, channels and calibrations to be preserved. The change in the correlation definition means this code is not backward compatible. With exceptions noted below, existing scripts should work fine. However data previously stored into a correlation object will need to be regenerated. I don't think this will be an issue for most users.

Old function CLIP has been removed and replaced by CROP. The terminology is consistent with the waveform toolbox and uses the new definition of PRETRIG. All prior calls to CLIP will need to be replaced with CROP using the new definition of the PRETRIG term. See HELP CROP and HELP CORRELATION for details.

Formatting of the filter routine BUTTER has been changed (not backward compatible). This was done for consistency with the @filterobject input and to allow more default settings. A basic bandpass filter can now be applied with just BUTTER(c,[1 5]).

New function GETSTAT calculates the best fit multichannel cross-correlation values following the widely used method of Vandecar and Crosson (BSSA 1990). This function has been used in-house for some time.


MINOR CHANGES from v.0 (THAT DO NOT BREAK BACKWARD COMPATIBILITY)
-------------------------------------------
New function STACK allows subsets of correlated waveforms to be stacked on the fly. The resulting waveform is appended as the last waveform in the list. If existing waveforms have already been cross-correlated, the stacked trace is added to the cross-correlation matrices as well.

New function MINUS allows one trace to be subtracted from all other traces. MINUS is particularly powerful in conjunction with STACK. Together these functions will isolate the differences in a set of similar waveforms.

New function NORM allows different types of trace amplitude scaling.

New function AGC allows for automatic gain control scaling of all traces. This is useful for emphasizing low amplitude, but coherent, phases.

New function CAT concatenates two correlation objects. Together with SUBSET, this allows for arbitrary mixing and matching of different families of waveforms.

New cross correlation method 'row' allows subsets of traces to be cross correlated. Essentially this allows new traces to be appended to an existing correlation object without having to recompute the complete cross correlation matrix.

New plotting option 'raw' allows traces to be plotted without any relative amplitude rescaling.

New plotting option 'stat' plots multichannel cross-correlation statistics from the stat field. 

Cross correlations methods 'dec' and '1x1' have been deprecated (no one uses them anyway)

Option 'event' for plot is now fully functional. It creates a stack of the largest families of waveforms and a time history of when events in each cluster occured.

Greatly expanded list of properties available with GET. Where possible properties definitions are consistent with WAVEFORM/GET

New color scale on correlation plots with discrete colors centered on correlation values of 0.6(light blue), 0.7(green), 0.8(yellow), 0.9(red), 1.0(black).

Lag plot color scale changed to red-white-blue to avoid confusion with correlation plots.

Informal version tracking.




############################
#       TO DO List         #	
############################

Deconvolution routine is not yet complete!


