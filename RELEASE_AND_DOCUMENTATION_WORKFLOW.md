# GISMO Testing, Documentation, and Release Workflow

This document describes the **official end-to-end workflow** for validating GISMO, updating the public documentation website, creating a new software release, and obtaining a Zenodo DOI.

It is intended for:
- Core developers
- JOSS reviewers
- Long-term maintainers

---

## 1. Running the Full GISMO Validation Suite

GISMO validation is structured in **three layers**:

1. **Unit Tests** – numerical and API correctness  
2. **Cookbooks** – feature and class-level demonstrations  
3. **Training Scripts** – end-to-end scientific workflows  

These layers must be executed **in this order** before any release.

---

### 1.1 Run All Unit Tests

From the MATLAB command window at the GISMO repository root:

```matlab
run_all_tests
```

This executes:
	•	All files in tests/test_*.m
	•	All numerical correctness checks
	•	All plotting functions in headless (CI-safe) mode

✅ Passing all unit tests is mandatory before any release.

If failures occur:
	•	Fix the code
	•	Re-run run_all_tests
	•	Do not proceed until all tests pass

### 1.2 Run All Cookbooks (Smoke Tests)

Cookbooks demonstrate the user-facing behavior of all major GISMO classes.    
```matlab
run_all_cookbooks
```

This:
	•	Executes every cookbook.m
	•	Verifies that all tutorials still run
	•	Detects documentation breakage
	•	May skip optional sections (Antelope, Mapping Toolbox, web services)

✅ All core cookbooks must execute without fatal errors.

Warnings due to missing toolboxes are acceptable. Crashes are not.

⸻

### 1.3 Run All Training Scripts (Interactive Validation)

Training scripts demonstrate complete observatory workflows and are not CI-bound.

```matlab
run_all_training
```

```
git clone -b gh-pages https://github.com/geoscience-community-codes/GISMO GISMO-ghpages
```

These cover:
	•	Waveforms
	•	Event detection
	•	RSAM
	•	Catalogs
	•	Instrument response
	•	Cross-correlation
	•	Clustering & hierarchy

✅ Training scripts validate:
	•	Multi-class interoperability
	•	Observatory-style workflows
	•	Teaching reproducibility

These are expected to be visually inspected.

⸻

## 2. Updating the Public GISMO Website (gh-pages + m2html)

GISMO documentation is published from the gh-pages branch and generated using m2html.

This includes:
	•	All cookbooks
	•	All training scripts
	•	API reference pages

⸻

### 2.1 Check Out the gh-pages Branch Separately

From outside your working repository:

```
git clone -b gh-pages https://github.com/geoscience-community-codes/GISMO GISMO-ghpages
```

This creates a separate working directory for the website.

⸻

### 2.2 Generate HTML from MATLAB Using m2html

From your main GISMO development branch (not gh-pages):
```matlab
m2html( ...
  'mfiles', {'core','contributed','training'}, ...
  'htmldir', '../GISMO-ghpages/cookbook_results', ...
  'recursive', 'on' )
```

This:
	•	Converts all .m files (including cookbooks and training scripts)
	•	Writes static HTML into gh-pages/cookbook_results/
	•	Preserves legacy URLs used by the Wiki and external citations

✅ After completion, open locally to verify:    

```
GISMO-ghpages/cookbook_results/index.html
```

### 2.3 Publish the Website Update

From the GISMO-ghpages directory:

```bash
git add cookbook_results
git commit -m "Updated GISMO cookbooks and training materials"
git push
```


Within ~1 minute the public site updates at:

https://geoscience-community-codes.github.io/GISMO/cookbook_results/

⸻

## 3. Creating a New GISMO Software Release

All releases are created directly from GitHub.

⸻

### 3.1 Prepare the Release
	1.	Ensure:
        •	run_all_tests passes
        •	run_all_cookbooks completes
        •	Training scripts run without critical failures
	2.	Update:
        •	CHANGELOG.md
        •	paper.md (if JOSS-related)
        •	Version numbers in metadata if present

⸻

### 3.2 Create the GitHub Release
	1.	Push all changes to the main branch
	2.	Go to the GISMO GitHub repository
	3.	Click Releases → Draft a new release
	4.	Create a new semantic version tag (e.g., v2.7.0)
	5.	Add concise release notes
	6.	Publish the release

⸻

## 4. Obtaining a New Zenodo DOI

GISMO is archived on Zenodo via the GitHub-Zenodo integration.

✅ Once a GitHub release is published, Zenodo automatically creates a new DOI.

⸻

### 4.1 Verify Zenodo DOI Creation
	1.	Go to the GISMO Zenodo record
	2.	Confirm:
        •	New version entry exists
        •	New version-specific DOI has been minted
	3.	Copy:
        •	The version-specific DOI (for citation)
        •	The concept DOI (for general reference)

⸻

### 4.2 Update Repository Citation Files

Update as needed:
	•	CITATION.cff
	•	paper.md
	•	README.md
	•	.zenodo.json or .zenodo-software.json

Include:
	•	New version DOI
	•	Updated release version
	•	Contributor list (if changed)

⸻

## 5. Required Pre-Release Checklist

Before any official release:
	•	All unit tests pass
	•	All core cookbooks run
	•	Training scripts execute
	•	Website updated via gh-pages
	•	GitHub release created
	•	Zenodo DOI verified
	•	Citation files updated

Only when all boxes are checked is a release considered valid.

⸻

## 6. Reproducibility & JOSS Compliance Statement

GISMO enforces reproducibility at three levels:
	1.	Automated numerical unit testing
	2.	Executable documentation via cookbooks
	3.	End-to-end workflow validation via training scripts

This ensures:
	•	Long-term software stability
	•	Scientific transparency
	•	Classroom and observatory reproducibility
	•	Full compliance with JOSS and FAIR software principles

⸻

## 7. Access Rule (Hard Requirement)

All scripts must access test data using:

``` matlab
fullfile(TESTDATA, <subdirectory>, <filename>)
```

Hard-coded paths, relative paths, and GUI file selection are **not
permitted** inside: - Unit tests - Cookbooks - Training scripts

____


Last updated: Dec 1, 2025