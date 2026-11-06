# Statistical specification / 统计规范

## Estimand and data

DSe=P(T+|D=1), DSp=P(T-|D=0). D is an explicitly defined latent target condition, not confirmed infection for each specimen. The user defines its epidemiological meaning. Analysis units must be independent under the MVP likelihood. Each analyte has its own data, comparator, priors and fit. No pooled panel DSe/DSp is computed.

For J>=2 populations, fixed cell order is ++,+-,-+,--. Each Y_j~Multinomial(N_j,P_j), with P_j=Prev_j Q_D+(1-Prev_j)Q_H. Accuracy and conditional covariance are constant across populations; prevalence varies. Population membership must not be determined by current T1/T2 outcomes. Different risk labels do not establish different true prevalences.

For margins p1,p2 and covariance c, Q=(p1*p2+c,p1*(1-p2)-c,(1-p1)*p2-c,(1-p1)*(1-p2)+c). Q_D uses p1=Se1,p2=Se2; Q_H uses p1=1-Sp1,p2=1-Sp2. The independent model fixes c=0. The positive model sets c=u*U; the advanced signed model sets c=L+u*(U-L), with the complete bounds in METHOD_PROVENANCE.md. u has a Beta prior, not a Pearson-correlation prior. No probability clipping or renormalization will conceal invalid parameter values.

## Priors

Alpha,beta must be finite and strictly positive. Mean/ESS input means alpha=m*ESS and beta=(1-m)*ESS; ESS is alpha+beta, not MCMC ESS. Users provide independent sources/rationales. No current-data-derived priors, automatic corrected prevalence from x/n, pathogen-specific performance defaults or hidden prevalence order are permitted.

Weak default is Beta(1,1), explicitly labelled weak/reference rather than scientific knowledge. Optional fixed lower/upper limits are recorded; displayed mean/quantiles/density must use the actual truncated distribution. Optional restriction Se1>0.5 and Sp1>0.5 requires explicit rationale, because this excludes admissible screening tests with DSp<0.5 and is stronger than a positive Youden index. With no label restriction or externally justified asymmetric priors, the class labels need not have the claimed infection meaning. Passing diagnostics is insufficient to resolve that interpretation.

Ordered prevalence, if implemented, conditions the joint independent prior on the stated order; sequential truncated priors are not silently substituted. Jointly conditioned prior sampling and overlays must match the actual model. Until verified, ordering remains unavailable with a clear explanation.

## Model computation and assessment

Four chains by default, distinct seeds and dispersed starts. Adaptation and burn-in are excluded from posterior summaries. Thin=1 by default. Preview is exploratory; final mode only increases the requested computation and does not certify convergence. Adaptation success is recorded. Rank-normalized folded split R-hat and bulk/tail ESS use posterior. Main targets: R-hat<1.01 and ESS>=100*chains. MCSE is retained.

PPC uses posterior replicated multinomial counts at the observed sample sizes. Each cell reports observed count, predictive median and 95% interval. A Pearson discrepancy uses expected counts N_j*P_j for observed and replicated counts, with a documented numerical denominator safeguard for zeros; it is a fit summary, not an identification test or a frequentist p-value.

Parameter summaries: posterior mean, median and equal-tail 95% CrI; one decimal percentage points in narrative. Full precision is preserved in machine exports. Trace, autocorrelation, densities, prior/posterior overlay, correlation matrices, cell plots and model/scenario comparisons are required.

## Reliability gate

All dependent models carry a permanent structural non-identifiability notice. Two dependent tests in three populations are not labelled just-identified. The >=3 population preference and expert override are recorded safeguards only. No source-backed information strength can be inferred merely from a large user-entered ESS.

Failure of convergence, unconfirmed interpretation, missing prior provenance, absent sensitivity analysis or design violations prevents final interpretation. An independent model, dependent model, weak-prior scenario and user-defined plausible alternative must be evaluated before the reporting checklist can be complete. Automated pathology flags require human review; no algorithm claims to exclude all multimodality or prior dominance.

Mixed specimen types and incompatible procedures prevent the basic pooled model from final use. Herd clustering is measured where IDs exist; it is not corrected by the basic likelihood. Missing herd IDs mean unknown clustering, not absence. Binary missing/invalid/equivocal results and duplicate IDs are rejected with row-level messages; there is no silent recoding or complete-case deletion. Ct is retained for descriptive discordance review, with no automatic causal explanation.

## Reproducibility

Each fit freezes input, cross tables, priors, metadata, exact model text, settings, initial values, seed, versions and diagnostics. SHA256 of input representation and model text is recorded; imported-file hash is also retained where available. Exports always use frozen run settings, never later UI edits. Analysis IDs are unique. Model/scenario differences and intervals are descriptive, not automatic robustness or superiority claims.

## Validation plan

Before UI work: independent simulation recovery, then dependent covariance tests and simulation. Stress scenarios include low prevalence, weak separation, small sample and zero cells. Repeated-simulation empirical coverage must be labelled by scenario, number of replicates and Monte Carlo uncertainty; a single successful fit is not coverage validation. Failures are retained rather than selectively excluded. Add meaningful data, prior, probability, engine, summary, report and bilingual UI regression tests.

## Derived posterior contrasts and project summaries (0.1.4)

For every retained posterior draw s, VetBLCM may derive

- Delta_DSe[s] = Se1[s] - Se2[s]
- Delta_DSp[s] = Sp1[s] - Sp2[s]

The reported posterior median and 95% credible interval are the empirical median and 2.5th/97.5th percentiles of these derived draws. `Pr(DSe1>DSe2)` and `Pr(DSp1>DSp2)` are the fractions of retained paired draws for which the corresponding difference is positive. These are posterior probabilities conditional on the fitted model, data and priors; they are not frequentist p-values.

VetBLCM 0.1.7 does not create multi-analyte project summaries. It exports standardized single-analyte summaries only. Any later cross-analyte display must be assembled externally and does not define a joint probability model, pooled estimate, or overall panel DSe/DSp.
