classdef test_ChanDetails < matlab.unittest.TestCase
   %UNTITLED Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
   end
   
   methods(Test)
      function TestRetrieve(testCase)
         ANMO = 'IU.ANMO.00.BHZ';
         ANTO = 'IU.ANTO.00.BHZ';
         % * test retrieve with default source *
         cdKey = ChanDetails.retrieve([], 'station','ANMO',...
            'channel','BHZ','location','00','network','IU',...
            'starttime','2015-10-21');
         % make sure the first one works, so we can trust use it to
         % evaluate the other ones
         testCase.assertLength(cdKey, 1);
         testCase.assertEqual(cdKey.channelinfo,ChannelTag(ANMO));
         testCase.assertEqual(cdKey.samplerate, 20);
         testCase.assertEqual(cdKey.elevation, 1671);
         testCase.assertEqual(cdKey.latitude, 34.9459, 'absTol', 0.0001);
         testCase.assertEqual(cdKey.depth, 145);
         testCase.assertEqual(cdKey.azimuth, 0);
         testCase.assertEqual(cdKey.dip, -90);
         testCase.assertEqual(cdKey.sensordescription,'Geotech KS-54000 Borehole Seismometer');
         testCase.assertEqual(cdKey.scalefreq,0.0200);
         testCase.assertEqual(cdKey.scaleunits,'M/S');
         testCase.assertEqual(datestr(cdKey.starttime),'17-Dec-2014 18:40:00');
         testCase.assertGreaterThan(cdKey.endtime, cdKey.starttime);
         
         % test retrieve with a single N.S.L.C string
         chd = ChanDetails.retrieve([], ANMO);
         testCase.verifyEqual(chd(end),cdKey);
         % test retrieve with ChannelTag
         chaninfo = ChannelTag(ANMO);
         chd = ChanDetails.retrieve([], chaninfo);
         testCase.verifyEqual(chd(end),cdKey);
         % test retrieve with multiple channeltags
         chansinfo = ChannelTag({ANMO, ANTO});
         chd = ChanDetails.retrieve([], [chansinfo; chansinfo]);
         testCase.verifySize(chd, [2 2], 'Wrong size returned for multiple Traces');
         % test retrieve with SeismicTrace
         T = SeismicTrace; T.name = ANMO;T.start = datenum('2015-10-21');
         chd = ChanDetails.retrieve([],T);
         testCase.verifyEqual(chd,cdKey);
         % test retrieve with multiple Traces
         chd = ChanDetails.retrieve([], [T T; T T]);
         testCase.verifySize(chd, [2, 2], 'Wrong size returned for multiple Traces');
      end
   end
   
end

