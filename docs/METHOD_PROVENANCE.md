# Method provenance / 方法溯源

Initial verification: 2026-09-14; Dendukuri & Joseph text audit: 2026-09-20; equation-image audit recorded 2026-09-21. Implementation is an independent transcription of mathematical methods; no published program is copied or redistributed. See REFERENCES.md and SOURCE_AUDIT_20260921.md for source details and the explicit prior-normalization distinction. This is a software audit, not WOAH certification.

| Component | Method and location | Authority | Verification |
|---|---|---|---|
| Intended use, target population, imperfect comparator | Metadata and explicit assumptions | WOAH 1.1.6, B.2.2; current SONT RID 268; archived PDF p.15 | Current official content retrieved; PDF labelled 2023 |
| Nucleic acid assay scope | Statistical diagnostic evaluation only; analytical sensitivity is not DSe | WOAH 2.2.3, current SONT RID 282 | Current official text retrieved; most recent updates adopted 2025; old static PDF is 2024 |
| Bayesian evaluation | Cross-classified results, priors, assumptions | WOAH 2.2.5, section on Bayesian latent class modelling, SONT RID 284 | Current official text retrieved; most recent updates adopted 2025 |
| Reference animals | Representativeness and independence of observations | WOAH 1.1.6 and 2.2.6 (RID 285) | Official content retrieved |
| Independent likelihood | Two tests, J populations, multinomial in ++,+-,-+,-- order | Hui & Walter 1980; Branscum et al. 2005 section 3.2 | Branscum full text and equations read; Hui metadata verified |
| Dependent likelihood | CovD and CovH added to concordant cells and subtracted from discordant cells | Branscum et al. 2005 section 3.3.3, p.155; Dendukuri & Joseph 2001, p.160 equations 1–2 | Text and equation images checked |
| Full covariance support | L=max(-p1*p2,-(1-p1)*(1-p2)), U=min(p1*(1-p2),(1-p1)*p2) | Fréchet–Hoeffding bounds; Erdely 2026 equations 7–8; Branscum p.155 special case | General bound independently derived from four nonnegative cells; tested separately |
| Scaled covariance prior | Cov=L+(U-L)*u, u~Beta(a,b); positive model uses L=0 | Generalized beta parameterization in Branscum p.155; Dendukuri & Joseph pp.160–161 | Conditional change of variables documented below; no claim of reproducing Dendukuri's full Gibbs posterior/Appendix |
| Beta priors | Positive alpha,beta; optional explicitly selected fixed truncation; mean/ESS conversion | Branscum section 2; R stats Beta documentation; JAGS manual truncation section | No pathogen-specific default accuracy/prevalence |
| MCMC | dmulti, dbeta, T; jags.model/adapt/update/coda.samples | JAGS 4.3.0 manual; CRAN rjags manual; installed rjags 4-16 documentation | Real engine JAGS 4.3.1 loads locally; upstream rjags manual currently 4-17 |
| Convergence | Rank-normalized folded split R-hat; bulk/tail ESS; trace/autocorrelation | Vehtari et al. 2021; posterior official docs | Use posterior package; no bespoke R-hat/ESS |
| PPC | Replicated multinomial counts for each posterior draw | Stan User's Guide, Posterior and Prior Predictive Checks | Replication uses full posterior uncertainty, not posterior mean plug-in |
| Agreement | Directional PPA/NPA with T2 as comparator; overall agreement and kappa | FDA 2007 diagnostic-test reporting guidance; standard kappa identity | Denominator-zero returns NA, not zero |
| Prior sensitivity | Refit complete scenarios, compare medians, intervals and diagnostics | Branscum section 3.3.3.1 | Scenarios must be labelled; alternate scientific priors supplied by user |

## Parameterization audit

Let q=P(X1=1,X2=1). The four cell probabilities are q,p1-q,p2-q,1-p1-p2+q. Their nonnegativity implies max(0,p1+p2-1) <= q <= min(p1,p2). Subtracting p1*p2 gives the full covariance interval above. Branscum's printed lower bound -(1-p1)(1-p2) is sufficient only in the branch p1+p2>=1. The general implementation covers both branches and is essential when unrestricted priors allow smaller margins. For healthy animals either specificity indicators or their complements give the same covariance: Cov(1-X,1-Y)=Cov(X,Y).

Given margins, Cov=L+(U-L)u has density dbeta((Cov-L)/(U-L),a,b)/(U-L). Uniform u gives a uniform conditional covariance on its feasible interval, not uniform Pearson correlation. In the positive model u=0 is independence; in the signed model independence is u=-L/(U-L), which changes with the margins. CovD/CovH marginal prior plots must be simulated jointly with accuracy priors.

The visually inspected Dendukuri & Joseph printed posterior (p.161) and accuracy conditionals (p.166) do not display the margin-dependent normalization of this conditional prior. VetBLCM explicitly retains its generative scaled-Beta specification rather than claiming to reproduce those printed kernels. The independent change-of-variables derivation and numerical integration checks are in SOURCE_AUDIT_20260921.md. No additional density factor is needed in the generative JAGS implementation.

## Structural limitation and reporting policy

Branscum pp.155–156 explicitly treats two dependent tests in L populations as non-identifiable. Additional populations alone do not remove this defect. To see the issue, write P_j=H+Prev_j(D-H). Perturb the endpoints along the same line and rescale prevalences; interior feasible parameter sets can produce identical observed distributions. This derivation explains the published limitation; it is not a proposed new model. MCMC convergence and PPC cannot prove identification or a correct latent infection interpretation.

The >=3 population rule is a user-requested review safeguard, not a theorem. A completed checklist means eligible for scientific review under recorded assumptions, never automatic publication approval. R-hat <1.01 and bulk/tail ESS >=100 per chain follow current Stan guidance; thresholds for boundary accumulation, posterior correlations, or prevalence separation are transparent screening heuristics, not universal scientific cutoffs.

## Excluded pending verification

- No automatic prevalence prior from external apparent x/n.
- No unrecorded truncation, prevalence ordering, or strength inflation of priors.
- No hierarchical clustering correction, individual infection classification, composite multiplex accuracy, or Ct-dependent likelihood in this version.
- No DIC-based automatic model selection.
- No claim that Se1>0.5 and Sp1>0.5 is universally innocuous: this is a substantive optional restriction requiring rationale.

## Publication-output provenance (0.1.4)

The 0.1.4 publication layer does not introduce a new diagnostic-accuracy model. `Delta_DSe` and `Delta_DSp` are deterministic posterior contrasts obtained by subtracting the paired MCMC draws (`Se1-Se2` and `Sp1-Sp2`) from the already fitted model; their credible intervals and `Pr(T1>T2)` are empirical summaries of those derived draws. They do not add a likelihood term, change priors or refit the model.

The sample-flow figure is a reporting visualization constructed only from user-recorded `samples_assessed`, exclusion notes and the final population counts. It does not infer unreported exclusions.

As of 0.1.7, VetBLCM does not scan historical runs or construct project-level multi-analyte forest plots. Each analyte remains a separate BLCM. Complete local saves export standardized single-analyte summary files for optional downstream aggregation in other software; no cross-analyte likelihood, hierarchical pooling, meta-analysis or overall panel DSe/DSp is implemented.

The STARD-BLCM export is a VetBLCM mapping aid to reporting topics described by Kostoulas et al. (2017), DOI 10.1016/j.prevetmed.2017.01.006. It is not presented as the official checklist and does not reproduce that checklist verbatim. The original publication remains the authoritative reporting source.
