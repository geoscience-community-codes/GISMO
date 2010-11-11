function describe(threecomp)
 
%Detailed description of threecomp properties
% DESCRIBE(THREECOMP) provides detailed descriptions of threecomp object
% properties and how they are related.
%
%
% ------------------- COORDINATE SYSTEM -------------------------
% The threecomp object is designed to use a familiar spherical polar
% coordinate system in which horizontal direction on Earth is given in
% clockwise degrees from north: north is 0; east is 90; south is 180; and
% west is 270 degrees. Vertical directions are given with respect to
% vertical up. up is 0 degrees; horizontal is 90 degrees; and 180 is down.
%
%
% ------------------ TRACE NAME CONVENTIONS -----------------------
% Trace names follow the convention of network-station-channel-location.
% (Internally, this is enforced via the scnlobject and waveform objects.)
% Station and channel codes have particular importance in threecomp
% objects. A simple check is performed upon initiation to ensure that all
% three traces in each object come from the same seismic station. In other
% words, all three traces must have the same station code. The channel
% codes have specific meaning and users are encouraged to make sure that
% channel names are correct before converting to a threecomp object. The
% threecomp channel code convention adheres to the SEED standard of a
% minimum three character name where the third character represents the
% component orientation. Threecomp requires that the third channel
% characters be: Z-N-E, Z-R-T, or Z-2-1. Modest deviations from these
% channel names are accomodated by the horizontal and vertical orientation
% properties (see below). However, the actual channel names must contain
% one of these character sets. 
%
%
% ------------------ COMPONENT ORIENTATIONS ----------------------
% The orientation of each component of trace data is essential to
% performing any type of three component analysis. The safest way to ensure
% that component orientations are correct is to provide them explicitly.
% The THREECOMP function allows users to provide the horizontal and
% vertical orientation of all three channels of data. It is also possible
% to read these parameters automatically from the original waveforms if they
% have been set as properties there. If no orientation information is
% given, THREECOMP will assign default values where possible.
%
% DEFAULT VALUES
% If the component (third character of the channel name) is Z, N, E and no
% explicit orientation is given, then the orientations are assumed to be 
%       Z: [0 0]    N:[0 90]    E: [90 90]
% This is equivalent to calling the THREECOMP function with an orientation
% matrix [0 0 0 90 90 90 ; ... ; ... ]. If the components are Z, R, T, and
% a backazimuth is given, then the horizontal components will be aligned
% accordingly. Components of Z, 2, 1 do not have any default orientations.
% Orientations provided as arguments to function THREECOMP, and
% orientations described in the input waveform properties, will override
% default values. For details see horizontal and vertical orientation
% descriptions below.
%
% HORIZONTAL ORIENTATION
% This attribute specifies the orientation of the component in the
% horizontal plane, measured clockwise from North.  For a North-South
% orientation, positive toward the north, the horizontal orientation is 0.
% For East-West orientation with positive to the east, the horizontal
% orientation is 90. Allowable range is 0 to 360.
%
% VERTICAL ORIENTATION
% This attribute measures the angle between the sensitive axis of a
% seismometer and the outward-pointing vertical direction.  For a
% vertically-oriented seismometer, the vertical orientation is 0, or 180
% (to reverse the sense of the instrument). For a horizontally oriented
% component, the vertical orientation is 90. Allowable range is 0 - 180.
%
% RADIAL TRANSVERSE COORDINATE SYSTEM
% Threecomp objects recognize the familiar coordinate system of vertical,
% radial, and transverse (ZRT). In this system the positive radial
% direction (R+) is 180 degrees opposite the backazimuth. The relative
% component orientations in a ZRT coordinate system are the same as in ZNE
% coordinates. That is, the positive transverse direction points 90 degrees
% clockwise from the positive radial direction. For example, for a wave
% arriving from due south on Z-N-E components, there is no rotation and N
% becomes R, while E becomes T.
%
%
% ------------------ PARTICLE MOTION ----------------------
% Particle motions are calculated in a sliding time window. In each window
% the covariance matrix of the three waveform vectors in computed. The
% eigenvectors of the covariance matrix define the dominant orientations of
% the data, while the eigenvalues express the relative amplitudes in each
% of these directions. Conceptually, rectilinearity expresseses the
% relative dominance of the largest eigenvalue (range is 0 to 1). Planarity
% is the degree to which the largest two eigenvalues dominate (range is 0
% to 1). Energy is the trace of the eigenvalue matrix. Azimuth and
% inclination give the spherical polar orientation of the largest
% eigenvector. It is important to note that azimuth and inclination only
% have meaning if the waveforms show a high degree of rectilinearity or in
% some orientations, planarity. It makes sense - think about it!
%
% As defined here, the azimuth range is 0 to 360 degrees measured from
% north. Inclination ranges from 0 (up) to 90 (horizontal). This reference
% frame differs from some in the literature, but is used here because it is
% intuitive; it is consistent through the threecomp toolbox; and, most
% importantly, to match the reference frame used for component
% orientations. See horizontal and vertical orientation, above. For
% mathematical descriptions of the particle motion coefficients, users are
% encouraged to consult the PARTICLEMOTION.M code. It is reasonably short
% and well commented. Note that rectilinearity and planarity have somewhat
% variable definitions in the literature. For the discerning user, parallel
% definitions are included in the PARTICLEMOTION code, but are commented
% out.



help describe
