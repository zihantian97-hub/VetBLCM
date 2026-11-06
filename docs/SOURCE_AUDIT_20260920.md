# Source audit / 来源补核

Date: 2026-09-20. This supplements the initial source verification without refitting models.

Historical record: the local-archive and equation-image gaps below were subsequently closed. See SOURCE_AUDIT_20260921.md for the successful retrieval, hash and normalization distinction. The earlier access failures remain recorded here; they are not current blockers.

## Dendukuri & Joseph (2001)

[Author-hosted PDF](https://joseph.research.mcgill.ca/publications/Methodological/conddep_diag.pdf); DOI [10.1111/j.0006-341X.2001.00158.x](https://doi.org/10.1111/j.0006-341X.2001.00158.x). Status: **FULL_TEXT_TEXT_INSPECTED; LOCAL_ARCHIVE_PENDING; EQUATION_IMAGE_REVIEW_PENDING**.

| Printed location | Text check and implementation consequence |
|---|---|
| p.160, equations 1–2 | Covariance increases concordant probabilities and decreases discordant probabilities; consistent with the existing likelihood. |
| p.160, equation 5; pp.160–161 | Positive covariance support and a beta scaled to that support agree with the current positive-model parameterization. |
| pp.161–162 | Prior influence can persist with increasing sample size in a nonidentified model; retain the warning. |
| pp.163–164, application/discussion | Prior sensitivity and uncertainty in test properties matter; retain scenario refits and qualified interpretation. |

No source-derived code change was needed. This check does not transfer the paper's single-population parameter count into a universal identification rule, implement its random-effects model, or reproduce its Appendix sampler. The signed model continues to use independently derived full Bernoulli bounds. The app's normalized conditional covariance density is explicit in METHOD_PROVENANCE.md; a garbled OCR posterior expression is not used to redefine it.

Access evidence: the web PDF reader returned ten pages of extracted text. Direct HTTPS download failed TLS authentication; certificate validation was not disabled. Screenshot requests returned references without inspectable images. Therefore no local PDF hash or visual equation-verification claim is recorded. Earlier failed course-URL attempts remain in source_manifest.json. No article copy is distributed.

## Toft et al. (2005)

[DTU primary record](https://orbit.dtu.dk/en/publications/diagnosing-diagnostic-tests-evaluating-the-assumptions-underlying/) and the recorded DOI were checked again. Metadata/abstract access remains available; full-text review remains **PENDING_VERIFICATION**. No detailed method or equation is attributed to an unread full text.

## Delivery checks

The source-refresh stage changed only provenance documentation and the embedded reference block in the frozen example HTML. Existing numeric outputs, posterior draws and figures were preserved. File hashes and the report body outside its reference block were compared with the previous candidate; results are retained in validation/source_refresh_20260920.json. Subsequent browser testing and its separate prior-editor fix are recorded in PROGRESS.md and QA_STATUS.md; they are outside this source-refresh check.
