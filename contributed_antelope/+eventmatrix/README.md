# eventmatrix Package (GISMO Contributed)

Modern replacement for the legacy Antelope-based import_events workflow.

This package:
- Uses ONLY modern GISMO core classes:
  - Catalog
  - Arrival
  - waveform
  - threecomp
- Is database-format agnostic
- Produces event × station waveform matrices
- Supports three-component conversion
- Is fully testable and refactor-safe

## Main Entry Point

```matlab
[EQTC, EQWF, meta] = eventmatrix.import( ...
    dbname, chanfile, starttime, endtime, phase, pretrig, posttrig);
````

## Outputs

* EQTC: cell array of threecomp or waveform objects
* EQWF: raw waveform matrix
* meta:

  * stations
  * orids
  * otimes

## Status

This package replaces the deprecated:
import_events.m (Bruton, UAF, legacy Antelope workflow)