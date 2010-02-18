

README Notes
- - -
Contents
* Note from me
* Zip file contents
* Installation
* Change notes
* Previous version information
* Acknowledgements

- - -
Thanks for trying out the waveform suite for MATLAB

This code has been created in MATLAB 2009b, and has been briefly tested in 2008b.  Older versions of matlab may or may not support the more recent changes.  Prior to this release, I had tested to MATLAB 7.1.0 (R14SP3).

I offer the waveform suite in "as is" condition, with no real promises... yada yada... I won't take responsibility for your use or misuse of this collection of software... yada yada... please see the license as stated on the MATLAB Waveform Suite download page.  Oh, and ALWAYS back up your data (independent of whether or not you use this product, it's just smart.)

If the waveform suite has been helpful to your research, and you are inclined to include a reference...

Reyes, C. G., M. E. West, S. R. McNutt (2009), The Waveform Suite: A robust platform for accessing and manipulating seismic waveforms in MATLAB, Eos Trans. AGU, 90 (52), Fall Meet. Suppl, Abstract S11B-1704

Also, feel free to send me a note with comments and suggestions, or just to let me know you use the product.

Thank you,
Celso Reyes
February 2010

- - - - - - - - - - - - - - - - - - - - - - - - 
README Notes
ZIP file contents:

    * @datasource/ source directory for the datasource class
    * @filterobject/ source directory for the filterobject class
    * @scnlobject/ source directory for the scnlobject class
    * @spectralobject/ source directory for the spectralobject class
    * @waveform/ source directory for the waveform class
    * uispecgram.fig UI component of the spectrogram generation program
    * uispecgram.m example of an interactive spectrogram generation program

- - - - - - - - - - - - - - - - - - - - - - - - 
Installation

Unzip the files either into the MATLAB directory from which you work, or into another directory. The parent directory (the one that contains all the @whatever directories) must be on the MATLAB path.

Additional help, along with examples can be found online at

    * http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/waveform_suite_example_index.html : several examples of the waveform suite in use http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/waveform.html : the main waveform information page. Check the links on the left for information about the other features of waveform.
    * http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/download.html : (this page)

= = = = = = = = = = = = = = = = = = = = = = = = 
Notes about the current release
r210

Fixed a bug in R207 (introduced ~r190) where attempting to read in a recently saved waveform (structure v1.1) will cause an error.  This was caused by the removal of the station and channel fields (which had been depricated since the introduction of scnlobjects)
Moved HISTORY out of miscelleneous fields and into its own proper field within the waveform structure.  This should save some speed overhead.

r207

Notice that the version # has changed to a release number. This has been prompted by changes with how the source code is version-controlled, and is a little less arbitrary than the 1.xx versions created before.

Improved:

    * speed & memory efficiency: the workings of several functions have been streamlined to reduce the amount of data juggling that occurs behind the scenes.
    * error handling: Several error messages have been improved, providing better explanations and/or suggestions on how to prevent the errors. Additional tests have been added to some functions further validating the data in order to prevent surprise (or less intelligible) errors.
    * NaN support: r191 Basic statistical functions (std, var, median, etc.) were rewritten to take advantage of MATLAB's existing NaN support (eg, nanstd, nanvar, nanmedian). Where NaN values cannot be handled eloquently, the error messages and warnings have been improved to provide better information about what is occurring
    * history: r200 Displaying a waveform now shows the number of items in the history, along with the latest modification date. Previously, it merely showed as an Nx2 cell
    * help text: the help text has been improved for several functions

Added:

    * cumtrapz integration: added ability to specify integration method for waveform/integrate. Previously, only cumsum integration was allowed, but now 'trapz' can be specified, which will use matlab's cumtrapz function.
    * log specgram plots: r192 added the ability to stretch the y-axis logarithmically for spectrograms. This has been added to spectralobject/specgram and spectralobject/specgram2, and depends upon the function uimagesc, created by Frederic Moisy, and available at the matlabcentral file exchange: File 11368
      usage: specgram.m(spectralobject,waveform,'yscale','log')
      Special Thanks to Jason Amundson for this one!

Upgraded:

    * Mathematical operators: r189 When an NxM waveform is added, subtracted, multiplied, or divided ( ./ , .* , - , + ) by an NxM numeric.
      Where N is numeric and W is a waveform of the same size (both may be N-dimensional), then W .* N will multiply them element-wise. likewise, W + N will add them element-wise.
      ie., for addition, if W is a 1x2 waveform, and N is a 1x2 double, then
      W .* N = [W(1).* N(1) W(2) .*N(2)]
      The same will hold true for the other basic operators 

Removed:

    * user manual has been removed from the suite. It had grown outdated, and by now is more misleading than useful. For details about how to use the functions, consult the inline help. Additional resources are the waveform suite website and the GISMO user group.
    * global variables: r200 the number of global variables used withinn waveform has been reduced. In doing so, functions waveform/private/mep2dep and waveform/private/dep2mep have been reinstated. (These functions have yoyo'd between .m files and global inline functions ever since the inception of waveform.) Other than freeing up global namespace, this should be invisible to the user.
    * waveform/lookupunits.m has been removed from the waveform suite. Its use is antelope specific, and really doesn't belong with the distribution. Instead its name has been changed and is now located in the GISMO suite download contributed_antelope/add_waveform_fields/db_lookupunits.m
    * spectralobject/spwelch.m has been deprecated. Its functionality merely duplicated pwelch, and (perhaps) should not ever have been included in releases of the waveform suite.

- - - - - - - - - - - - - - - - - - - - - - - - 
Previous Versions

v 1.12
includes major changes to how waveform handles SAC files. Several bugs regarding the loading and saving of SAC files were brought to my attention. In response, all the sac-related files within the @waveform/private directory have been modified. These modification should be mostly transparent to overlying programs with the exception of User Fields.

When waveform opens a sac file, it read the header into user-defined fields. Much information from these fields were incorporated into the waveform, such as period, start time, units, etc. The user fields were then left in the waveform, but were vestigial. When a waveform writes out to a sac file, it recalculates much of this information because all of it was subject to change by the user. Now, most of these "vestigial" fields have been removed from the waveform. Fields that are no longer in the user-defined field section include: B, E, DEPMIN, DEPMAX, DEMEN, NPTS, KSTNM, KCMPNM, KNETWK, DELTA, NVHDR, IDEP, and LEVEN. All of the values contained in these fields are accessible through pre-existing means.

Starting with the file marked as v 1.10, i have implemented a fundamental change in the way waveform works. The source of the data, which used to be deeply entwined with the waveform class has been pulled out and split into its own class, datasource. This means that the waveform constructor call no longer requires a different series of arguments depending on the source. Now, the overlying program does not need to know whether data is imported via SAC, winston, antelope, etc. Additionally, this change has allowed the easy importation of user-defined file types and the ability to intelligently navigate directory structures. It is still backwards compatible, but warnings will be generated that aid the user in updating code to the new paradigm.

Support for the importation of SEISAN files was added, too. However, the inherent directory structure used with SEISAN precludes the datasource's ability to navigate and find the appropriate files. They can still be imported, but the file names will have to be individually declared.

scnlobjects were introduced as a way to make waveform more seed compliant, and to provide a robust way of handling the locales associated with each waveform. Other than the initial creation of scnlobjects necessary for the creation or importation of waveforms, this change is relatively transparent. That is to say, you can still access stations and channels through waveform's set/get routines without having to deal with the scnlobject contained within each waveform.

- - - - - - - - - - - - - - - - - - - - - - - - 
Acknowledgements

In one form or another, the waveform suite has been around for roughly 5 years. I'd like to thank those that have helped me improve it throughout that time. I especially would like to recognize Jackie-Caplan Auerbach (for introducing me to MATLAB and inspiring this suite in the first place), Jason Amundson (a great debugger and source of addtional functionality), Micheal Thorne (who's SAC routines I thoroughly cannibalized), Glenn Thompson and Silvio DeAngelis (as testers and for SEISAN help), my advisor Steve McNutt (who let me get away with working on this stuff when, perhaps I should have been concentrating on the wiggles themselves), and Michael West (For plenty of discreet encouragement and great conversations on waveform philosophy... and author of the correlation toolbox, which is based upon the waveform object).

I'm sure I'm leaving out important people; and I reserve the right to add them as they pop to mind.

Waveform Suite
for MATLAB