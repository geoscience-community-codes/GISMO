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

The full validation and release procedure is documented here:

👉 **[`RELEASE_AND_DOCUMENTATION_WORKFLOW.md`](RELEASE_AND_DOCUMENTATION_WORKFLOW.md)**  
(How to run tests, cookbooks, training scripts, update the website via `m2html`, create GitHub releases, and obtain Zenodo DOIs.)

This workflow is designed to ensure:
- Long-term numerical correctness  
- Fully executable documentation  
- Observatory-scale scientific reproducibility  
- Full compliance with JOSS and FAIR software principles  

---

## Optional MATLAB Toolboxes & External Dependencies

GISMO is designed to run with **core MATLAB only**, but several advanced
analysis, visualization, and data-access features require additional
toolboxes or third-party software. All such functionality is **optional**
and automatically disabled when dependencies are not present.

### MATLAB Toolboxes (Optional)

The following MathWorks toolboxes are required for specific feature sets:

#### Signal Processing Toolbox (Recommended)
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

### Antelope Toolbox (Optional, External)

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