GISMO Training, Cookbook & Test Framework
=========================================

This repository validates GISMO functionality using three layers:

1. Unit Tests (tests/)
   – Numerical correctness and API stability
   – CI safe
   – No plots, no web services required

2. Cookbooks (core/@*/cookbook.m, contributed/*/cookbook.m)
   – Feature demonstrations
   – Minimal reproducibility guarantee
   – May rely on demo datasets or optional toolboxes

3. Training Scripts (training/)
   – End-to-end scientific workflows
   – Designed for teaching and observatory practice
   – Multi-class, multi-tool integration

Recommended validation order:
   1. Run all unit tests
   2. Run all cookbooks in CI-safe mode
   3. Run all training scripts interactively