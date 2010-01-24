

README Notes
- - -
Thanks for trying out the waveform suite for MATLAB

The code remains backwards compatable to MATLAB 7.1.0 (R14SP3) for two reasons:
1. I need to maintain backwards compatibility due to local system requirements
2. Sometime, eventually, I'll need to defend... and I've got alot of other work to do before then

However, that doesn't mean that I'm not constantly improving the code base, but, rather that (another) complete overhaul is unlikely. 

I offer it in "as is" condition, with no real promises... yada yada... I won't take responsibility for your use or misuse of this collection of software... yada yada... 

Oh, and Always back up your data (independent of whether or not you use this product, it's just smart.)


I, and several colleagues have found the waveform suite useful, and I hope you do too.  Feel free to contact me with comments and bug fixes.

Thank you,
Celso Reyes
April 2009

- - -
ZIP file contents:

    * @datasource/ source directory for the datasource class
    * @filterobject/ source directory for the filterobject class
    * @scnlobject/ source directory for the scnlobject class
    * @spectralobject/ source directory for the spectralobject class
    * @waveform/ source directory for the waveform class
    * uispecgram.fig UI component of the spectrogram generation program
    * uispecgram.m example of an interactive spectrogram generation program

Installation

Unzip the files either into the MATLAB directory from which you work, or into another directory. The parent directory (the one that contains all the @whatever directories) must be on the matlab path.

Additional help, along with examples can be found online at

  * http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/waveform_suite_example_index.html
  * http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/waveform.html
  * http://kiska.giseis.alaska.edu/Input/celso/matlabweb/waveform_suite/download.html (containing these notes, as well)

Notes about this release

Starting with the file marked as v 1.10, i have implemented a fundimental change in the way waveform works. The source of the data, which used to be deeply entwined with the waveform class has been pulled out and split into its own class, datasource. This means that the waveform constructor call no longer requires a different series of arguments depending on the source. Now, the overlying program does not need to know whether data is imported via SAC, winston, antelope, etc. Additionally, this change has allowed the easy importation of user-defined file types and the ability to intelligently navigate directory structures. It is still backwards compatible, but warnings will be generated that aid the user in updating code to the new paradigm.

Support for the importation of SEISAN files was added, too. However, the inherent directory structure used with SEISAN precludes the datasource's ability to navigate and find the appropriate files. They can still be imported, but the file names will have to be individually declared.

scnlobjects were introduced as a way to make waveform more seed compliant, and to provide a robust way of handling the locales associated with each waveform. Other than the initial creation of scnlobjects necessary for the creation or importation of waveforms, this change is relatively transparent. That is to say, you can still access stations and channels through waveform's set/get routines without having to deal with the scnlobject contained within each waveform.
Acknowledgements

In one form or another, the waveform suite has been around for roughly 5 years. I'd like to thank those that have helped me improve it throughout that time. I especially would like to recognize Jackie-Caplan Auerbach (for introducing me to MATLAB and inspiring this suite in the first place), Jason Amundson (a great debugger and source of addtional functionality), Micheal Thorn (whos SAC routines I thoroughly canabalized), Glenn Thompson and Silvio DeAngelis (as testers and for SEISAN help), my advisor Steve McNutt (who let me get away with working on this stuff when, perhaps I should have been concentrating on the wiggles themselves), and Michael West (For plenty of descreet encouragement and great conversations on waveform philosophy... and author of the correlation toolbox, which is based upon the waveform object).

I'm sure I'm leaving out important people; and I reserve the right to add them as they pop to mind.