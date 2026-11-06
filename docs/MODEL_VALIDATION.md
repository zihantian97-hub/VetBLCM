# Model validation / 模型验证说明

Validation run: 2026-09-14. VetBLCM 0.1.0; R 4.4.1; JAGS 4.3.1; rjags 4-16; posterior 1.6.1. All numbers below come from saved runs. No empirical animal data were used.

## 结论与适用边界

实现通过了概率合法性、真实JAGS运行、数据处理、导出和回归检查。重复模拟不是“所有情景都恢复良好”：140次拟合均完成，其中136次达到数值诊断目标。低患病率、零格、群体区分不足和有符号依赖情景暴露了明显的信息不足或先验敏感性。软件仍需逐研究验证，不能据此认证任意检测。

两个具有自由类内协方差的检测，即使增加群体，也不能仅凭似然保证结构可识别。信息先验、准确度恒定性和潜在类别解释均是实质假设。收敛、覆盖一次真值或良好PPC都不能代替这些假设。

## Reproducible scenarios / 可复现情景

All scenarios use Se1=0.90, Sp1=0.97, Se2=0.84 and Sp2=0.95. The same covariance applies across populations. Twenty independent data replicates are generated per scenario. Zero cells are allowed to arise naturally; counts are never overwritten to manufacture a zero.

| Scenario | N per population | Generating prevalences | CovD, CovH |
|---|---:|---|---|
| 条件独立 / Independence | 1000 | 0.06, 0.30, 0.70 | 0, 0 |
| 正依赖 / Positive | 1000 | 0.06, 0.30, 0.70 | 0.040, 0.015 |
| 低患病率 / Low prevalence | 1000 | 0.005, 0.02, 0.06 | 0.040, 0.015 |
| 群体区分不足 / Weak separation | 1000 | 0.18, 0.20, 0.22 | 0.040, 0.015 |
| 小样本 / Small sample | 60 | 0.06, 0.30, 0.70 | 0.040, 0.015 |
| 零格 / Zero-cell setting | 40 | 0.002, 0.01, 0.03 | 0.040, 0.015 |
| 有符号依赖 / Signed | 1000 | 0.06, 0.30, 0.70 | -0.005, -0.001 |

All T1 accuracy priors are Beta(1,1) explicitly truncated to (0.5,1), and prevalence priors are Beta(1,1), without ordering. In dependent scenarios, the simulated comparator priors are Se2~Beta(336,64) and Sp2~Beta(380,20), both with concentration 400; uD/uH~Beta(1,1). These are deliberately correctly centred simulation priors, not recommendations for real assays. The independent scenario uses unrestricted Beta(1,1) for T2.

Repeated runs use 4 chains, 1,500 adaptation, 4,000 burn-in and 12,000 sampling iterations per chain, thin=1. Seeds and task order are explicit in scripts/run_validation.R. Numerical targets: adaptation complete, every monitored key parameter R-hat<1.01, bulk/tail ESS>=400. Initial values are dispersed prior quantiles, not generating truths.

## Pilot results / 试点结果

Coverage below includes every completed run, including runs with failed convergence. Such posterior estimates are retained for audit and must not be treated as acceptable analyses. The CSV also provides the converged subset separately. Bias is mean posterior median minus generating value, on the proportion scale.

| Scenario | Converged / 20 | Se1 coverage | Sp1 coverage | Se1 bias | Mean Se1 CrI width |
|---|---:|---:|---:|---:|---:|
| 条件独立 / Independence | 18 | 0.95 | 0.95 | -0.0049 | 0.0929 |
| 正依赖 / Positive | 20 | 1.00 | 1.00 | +0.0055 | 0.0973 |
| 低患病率 / Low prevalence | 20 | 0.85 | 1.00 | -0.0870 | 0.3446 |
| 群体区分不足 / Weak separation | 18 | 1.00 | 1.00 | -0.0514 | 0.2902 |
| 小样本 / Small sample | 20 | 0.95 | 0.95 | -0.0214 | 0.2060 |
| 零格 / Zero-cell setting | 20 | 1.00 | 0.95 | -0.1970 | 0.4662 |
| 有符号依赖 / Signed | 20 | 0.90 | 0.90 | -0.0111 | 0.0817 |

The nonconverged replicates were independence 5 and 6, and weak_separation 11 and 14. No error or nonconverged run was silently discarded. Detailed R-hat/ESS values and zero-cell indicators are in validation/simulation_all_runs.csv and validation/nonconverged_runs.csv.

低患病率时，T1 DSe平均偏差约为−8.7个百分点；零格情景中为−19.7个百分点，同时区间明显变宽。宽区间带来的高覆盖不能解释为精确估计。零格情景最低患病率的区间仅13/20次覆盖真值。

The signed model reached numerical targets in all 20 runs, but CovH coverage was only 14/20 (0.70). This illustrates prior/support sensitivity in a structurally nonidentified model. It is a limited advanced option, not a validated default for negative dependence.

Twenty replicates provide imprecise coverage estimates. For example, 14/20 has an exact binomial 95% interval of roughly 0.46–0.88; 20/20 does not imply zero uncertainty. Exact binomial intervals are recorded alongside plug-in Monte Carlo SEs in simulation_summary.csv. A plug-in SE of zero at 0%/100% coverage must not be interpreted as certainty. These fixed-truth experiments are not simulation-based calibration with parameters drawn from the joint prior.

## Single-replicate recovery / 单次参数恢复

The independent check used N=2,500 per group, generating prevalences 0.06/0.30/0.70, 4 chains, 2,000 adaptation, 4,000 burn-in and 10,000 posterior iterations per chain. All seven generating parameters were inside their 95% CrIs.

The positive-dependence check used N=2,000 per group, the same accuracy/prevalence values, CovD=0.04 and CovH=0.015, 4 chains, 3,000 adaptation, 8,000 burn-in and 24,000 sampling iterations. All eleven monitored generating parameters, including support-position uD/uH, were covered. It uses the simulated informative comparator priors above.

| Positive model parameter | Truth | Posterior median | 95% CrI |
|---|---:|---:|---|
| Se1 | 0.9000 | 0.8923 | 0.8467–0.9336 |
| Sp1 | 0.9700 | 0.9594 | 0.9320–0.9798 |
| Se2 | 0.8400 | 0.8433 | 0.8057–0.8746 |
| Sp2 | 0.9500 | 0.9527 | 0.9287–0.9690 |
| Prev[1] | 0.0600 | 0.0636 | 0.0308–0.0886 |
| Prev[2] | 0.3000 | 0.2872 | 0.2542–0.3187 |
| Prev[3] | 0.7000 | 0.7048 | 0.6666–0.7491 |
| uD | 0.4762 | 0.4342 | 0.1394–0.6072 |
| uH | 0.5263 | 0.4545 | 0.0926–0.6483 |
| CovD | 0.0400 | 0.0393 | 0.0085–0.0718 |
| CovH | 0.0150 | 0.0173 | 0.0020–0.0386 |

## Worked analysis and sensitivity / 完整示例

The 6,000-row sample-level example exactly reproduces the positive recovery counts. It independently runs the GUI-facing analysis API with full metadata, both models, weak priors and a plausible simulation alternative with half the comparator concentration. Using the same data counts, priors and seed intentionally reproduces the positive-model posterior draws; this is not a second independent validation dataset.

| Run | Maximum R-hat | Minimum bulk ESS | Minimum tail ESS | Numerical targets |
|---|---:|---:|---:|---|
| independent | 1.0002 | 28789 | 42984 | TRUE |
| positive | 1.0015 | 2355 | 3896 | TRUE |
| Weak | 1.0248 | 134 | 341 | FALSE |
| Alternative | 1.0034 | 1386 | 2185 | TRUE |

Weak先验情景R-hat约1.0248，最低bulk ESS约134，未达到目标。该情景被保留，未替换成“更好看”的先验；示例报告因此不能被视为正式DSe/DSp结论。其余情景达标也不能消除原模型的结构不可识别性。

## Checks and limitations / 检查与限制

Automated checks cover invalid/missing coding, duplicate IDs, population matching, zero cells, all four probabilities and their sum, complete covariance endpoints, Beta/truncation calculations, prevalence prior order, observable nonidentification, frozen report settings, escaping user text, saved-draw reload, reproducible PPC and strict Excel-reader compatibility. Shiny server-state tests cover example import, language changes preserving data, prior editing and project/scenario state. See QA_STATUS.md for the exact final test and visual status.

The main diagnostic appendix has 44 pages: trace, density, prior overlay and autocorrelation for each of 11 key parameters. Density overlays are smoothed estimates; apparent shape near bounded support can reflect kernel smoothing. Assess actual prior bounds and quantiles as well. No automatic algorithm certifies absence of multimodality or prior dominance.

Not evaluated: misspecified comparator priors across a systematic grid, spectrum effects, clustering, informative sampling, dependence varying between populations, more than two tests, individual infection classification, an independent Stan backend, or fresh-computer package restoration. Optional future methods remain unavailable. No study-specific sample-size recommendation follows from this pilot.

To reproduce, run scripts/verify_independent.R, scripts/verify_dependent.R, scripts/run_validation.R 20 and scripts/run_example.R from the project root. scripts/summarise_validation.R rebuilds summary tables from recorded CSVs without fitting. All simulations are synthetic; do not transfer their priors to real pathogens.
