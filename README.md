# GISMO
A seismic data analysis toolbox for MATLAB. It can be useful for research, monitoring, and education.

[![DOI](https://zenodo.org/badge/365883125.svg)](https://doi.org/10.5281/zenodo.1404723)

---

## Getting Started

<ol>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/The-GISMO-Users-Group">Sign up for the Users Group</a></li>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/Getting-started">Download/Install GISMO</a></li>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/">Explore the GISMO Wiki</a></li>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/Tutorials">Browse the Tutorials</a></li>
<li><a href="https://geoscience-community-codes.github.io/GISMO/">Visit the GISMO Website</a></li>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/Reporting-errors%2C-bugs%2C-issues">Get Help / Report Issues</a></li>
<li><a href="https://github.com/geoscience-community-codes/GISMO/wiki/SUGGESTED-CITATION">Please Cite GISMO in Your Work</a></li>  
</ol>

---

## Testing, Documentation, and Releases (For Developers & Reviewers)

GISMO enforces **three-tier reproducibility**:

1. **Automated unit tests**
2. **Executable cookbooks**
3. **End-to-end training workflows**

## Test Data (Automatic Download & Configuration)

GISMO test data are **not stored inside the main repository**. Instead,
all unit tests, cookbooks, and training workflows share a **single
external testdata directory** configured via the global MATLAB variable:

``` matlab
global TESTDATA
```

### Automatic Setup (Recommended)

All core runners automatically check and install test data as needed:

``` matlab
run_all_tests
run_all_cookbooks
run_all_training
```

On first use, GISMO will:

1.  Detect whether `TESTDATA` is defined
2.  If not, prompt for or select a default testdata location
3.  Download and unzip the full testdata archive
4.  Set `global TESTDATA` for the session

This process is **fully automatic and CI-safe** (no GUI is used during
automated runs).

### Testdata Contents

The testdata archive contains:

-   **CSS 3.0 relational databases** (Antelope format)
-   **MiniSEED waveform files**
-   **SAC waveform files**
-   **SEISAN waveform and catalog databases**
-   **RSAM time series**
-   **Poles & Zeros (SACPZ) files**
-   **MATLAB-native `.mat` datasets** for fast testing
-   **ObsPy MATLAB interoperability datasets**

The full directory structure is documented on the GISMO website:
https://geoscience-community-codes.github.io/GISMO/testdata.html

This workflow is designed to ensure:
- Long-term numerical correctness  
- Fully executable documentation  
- Observatory-scale scientific reproducibility  
- Full compliance with JOSS and FAIR software principles

The full validation and release procedure is documented here:

👉 **[`RELEASE_AND_DOCUMENTATION_WORKFLOW.md`](RELEASE_AND_DOCUMENTATION_WORKFLOW.md)**  
(How to run tests, cookbooks, training scripts, update the website via `m2html`, create GitHub releases, and obtain Zenodo DOIs.)

---

## Optional MATLAB Toolboxes & External Dependencies

GISMO is designed to run with **core MATLAB only**, but several advanced
analysis, visualization, and data-access features require additional
toolboxes or third-party software. All such functionality is **optional**
and automatically disabled when dependencies are not present.

### MATLAB Toolboxes (Optional)

The following MathWorks toolboxes are required for specific feature sets:

#### Signal Processing Toolbox (Highly Recommended)
Required for:
- Digital filtering (Butterworth, `filtfilt`)
- Spectral analysis
- Spectrograms
- RSAM / amplitude spectrum workflows
- Correlation and waveform filtering utilities

Used by:
- RSAM
- Drumplot
- Three-component processing
- Correlation analysis
- Instrument response deconvolution post-filtering

#### Statistics & Machine Learning Toolbox (Optional)
Required for:
- Advanced correlation metrics
- Regression-based utilities
- Some similarity / distance measures

Used by:
- Master correlation tools
- Correlation clustering utilities

#### Mapping Toolbox (Optional)
Required for:
- event map plots

Used by:
- Catalog class

#### Antelope Toolbox (Optional, External)

Some GISMO functionality supports **Antelope databases** via the
Antelope MATLAB Toolbox provided by **BRTT, Inc.**

Required for:
- Loading waveforms from Antelope databases
- Retrieving instrument responses from Antelope
- `test_antelope2waveform`
- Optional response loading via `sacpz.from_antelope()`

Antelope is **not required** for core GISMO operation.

Available from:
https://brtt.com

> Note: Antelope support is automatically skipped if Antelope is not installed.

### IRIS / EarthScope Data Access (Legacy)

GISMO supports legacy **IRIS DMC waveform retrieval** via `irisFetch`
for MATLAB **R2022b and earlier only**.

Required for:
- `+irisdmc` package
- `test_irisfetch`
- `test_irisdmc_cookbook`

Limitations:
- MATLAB R2023a+ no longer supports the required Java IRIS-WS libraries
- These features are automatically skipped in newer MATLAB versions

### Continuous Integration & Testing

GISMO unit tests automatically detect:
- Missing toolboxes
- Missing Antelope installations
- Unsupported MATLAB versions
- Missing Java / internet connectivity

and **gracefully skip tests** when required dependencies are unavailable.
This ensures that GISMO remains CI-safe and portable across systems.

### Quick Dependency Summary

| Feature | Required Dependency |
|--------|----------------------|
| Basic waveform processing | None (MATLAB only) |
| Filtering, spectra, RSAM | Signal Processing Toolbox |
| Correlation & clustering | Signal + Statistics Toolboxes |
| Antelope database access | Antelope Toolbox (BRTT) |
| IRIS / EarthScope downloads | `irisFetch` + Java (≤ R2022b) |

---

## MATLAB Compatibility Note

GISMO is fully supported on **MATLAB R2022b and earlier**.  
Some legacy data-access functionality (e.g., `IRIS/irisFetch`) is **not compatible with MATLAB R2023a and later** due to JVM changes introduced by MathWorks.

Users on newer MATLAB releases should use **Python/ObsPy** for FDSN data access.

---

**Last updated: Glenn Thompson 2025/11/26**
