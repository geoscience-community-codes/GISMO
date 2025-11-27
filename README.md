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

## MATLAB Compatibility Note

GISMO is fully supported on **MATLAB R2022b and earlier**.  
Some legacy data-access functionality (e.g., `IRIS/irisFetch`) is **not compatible with MATLAB R2023a and later** due to JVM changes introduced by MathWorks.

Users on newer MATLAB releases should use **Python/ObsPy** for FDSN data access.

---

**Last updated: Glenn Thompson 2025/11/26**
