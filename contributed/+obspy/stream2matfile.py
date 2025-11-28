def stream2matfile(st, outdir):
    from scipy.io import savemat
    import os

    os.makedirs(outdir, exist_ok=True)

    for tr in st:
        mdict = {
            'network': tr.stats.network,
            'station': tr.stats.station,
            'location': tr.stats.location,
            'channel': tr.stats.channel,
            'sampling_rate': float(tr.stats.sampling_rate),
            'starttime': tr.stats.starttime.isoformat(),
            'data': tr.data,
            'calib': tr.stats.get('calib', 1.0),
            'mseed': tr.stats._format if '_format' in tr.stats else ''
        }

        fname = f"obspy.stream.{tr.id.replace('.', '_')}.mat"
        savemat(os.path.join(outdir,fname), mdict)


if __name__ == "__main__":
    import obspy, sys, os

    if len(sys.argv) < 3:
        raise SystemExit("Usage: stream2matfile.py <datasource> <outdir>")

    source  = sys.argv[1]
    outdir  = sys.argv[2]

    st = obspy.read(source)
    stream2matfile(st,outdir)