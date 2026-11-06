# Source verification / 来源核验日志

Initial retrieval and checks: 2026-09-14. Dendukuri & Joseph local PDF and selected equation-image audit completed and recorded 2026-09-21; see SOURCE_AUDIT_20260921.md. Exact URLs and local-file SHA-256 hashes are in source_manifest.json. Historical failed-access entries remain for traceability. No full copyrighted papers or operational laboratory chapters are redistributed. Only model mathematics, diagnostic terminology and non-operational study-design implications are incorporated.

| Source | Evidence checked | Limit |
|---|---|---|
| WOAH 1.1.6, current SONT RID 268 | Intended use; source/target populations; reference-animal applicability; B.2.2 latent-class evaluation | Static PDF carries 2023 label; dynamic content was checked separately |
| WOAH 2.2.3, RID 282 | Statistical distinction between analytical and diagnostic evaluation; intended use | Current text says updates adopted 2025; older static PDF was 2024 |
| WOAH 2.2.5, RID 284 | Design, latent-class methods, prior reporting and STARD-BLCM context | Current content says updates adopted 2025; no claim of WOAH software endorsement |
| WOAH 2.2.6, RID 285 | Reference-sample and population applicability | No laboratory procedures incorporated |
| Branscum et al. 2005 | Full published paper; sections 3.2, 3.3.3 and 3.3.3.1; pp.155–156 covariance and structural nonidentification | Printed covariance lower-bound branch is extended to full Bernoulli bounds with documented derivation |
| Dendukuri & Joseph 2001 | Author-hosted full text; local SHA-256 archived; equation images pp.160–161 and 166 inspected | Printed kernel normalization differs from the explicit generative prior specification; see SOURCE_AUDIT_20260921.md. No claim of complete Gibbs reproduction |
| Gardner et al. 2000; Johnson et al. 2001 | Primary bibliographic records and abstracts | Abstract-level support only |
| Toft et al. 2005 | University/publisher metadata and abstract; DTU record rechecked 2026-09-20 | Full text PENDING_VERIFICATION; no unverified equation used |
| Erdely 2026 | Full-text equations 7–8 for bivariate Bernoulli feasible bounds | Mathematical identities independently implemented; no adapted code/prose |
| JAGS manual 4.3.0; installed rjags 4-16 help | dbeta, dmulti, T() syntax; jags.model, adapt, update, coda.samples and initial seeds | Actual engine tested is JAGS 4.3.1; current upstream rjags 4-17 is not falsely claimed tested |
| posterior and Vehtari et al. | Rank-normalized folded split R-hat, bulk/tail ESS; official Stan diagnostic guidance | Screening thresholds for boundary/correlation/prevalence flags are identified as heuristics |
| Stan User Guide | Posterior predictive replication concept | Stan not used as a fitting backend |
| Kostoulas et al. 2017 STARD-BLCM | PubMed bibliographic record and abstract; DOI 10.1016/j.prevetmed.2017.01.006 | VetBLCM exports a reporting-topic mapping aid, not a verbatim official checklist |
| FDA diagnostic-test reporting guidance, 2007 | Agreement with an imperfect comparator | Not a claim of human/regulatory validation for this veterinary app |

The official WOAH route is /wp-json/woah-sont/v1/back-office-api-call, with navigation-chapter-preview and RID, language_id=102, is_manual=true, animal_type=7, standard_type=6. Requests and resulting hashes are preserved in the JSON manifest for direct auditing.

Implementation help was also checked against [renv scaffold](https://rstudio.github.io/renv/reference/scaffold.html), [renv snapshot](https://rstudio.github.io/renv/reference/snapshot.html), [openxlsx saveWorkbook](https://ycphs.github.io/openxlsx/reference/saveWorkbook.html), and installed zip 2.x help. The dependency lock includes development tests. Scaffold preserves the shipped lock before creating infrastructure.

Strict-reader QA found openxlsx 4.2.7.1 left unused relationships to absent drawing parts. The exporter removes only absent drawing links that are not referenced by the worksheet. It verifies archive structure before replacement, preserves worksheet XML byte-for-byte in regression testing, and reopens output with an independent reader. This is file-format compatibility handling, not a statistical change.
