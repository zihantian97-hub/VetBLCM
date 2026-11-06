# Reproducibility / 复现说明

## Environment

Use R 4.4.1 for the recorded environment and install JAGS 4.3.1 separately. The R package `rjags` does not install JAGS. Exact R package versions are in `renv.lock`. Run commands from the extracted project root, where `app.R` is located.

```r
source("scripts/setup.R")  # restore R packages; internet access required
shiny::runApp(".", host = "127.0.0.1")
```

On Windows, `launch_app.bat` or `launch_app.ps1` can also launch the app. Python is needed only to build a release ZIP, not to run analyses.

## Tests

```text
Rscript --vanilla scripts/run_tests.R
```

The test entry point generates the simulated fitted objects required by the tests when they are absent. A first run therefore performs MCMC and report generation before the tests. For subsequent runs, existing generated fixtures are reused. To regenerate them, use a fresh extracted source directory. On Windows, do not set the Unix-only locale value `LC_ALL=C.UTF-8`; use the system UTF-8 locale.

Current check results and the outstanding historical Shiny mock-session test are documented in `docs/RELEASE_CHECKS_1.0.0.md`.

## Complete simulated example

```text
Rscript --vanilla scripts/run_example.R
```

This fits independent and positive-dependence models and performs prior sensitivity analyses. It writes the example report and analysis bundle to `reports/example_analysis/` and an additional RDS to `validation/example_full.rds`. MCMC settings and chain seeds are recorded by the analysis code; the default seed in `mcmc_settings()` is 20260914. The example remains a simulated demonstration and is not the thesis dataset.

## Reproducing an empirical analysis

论文数值复现还需提供：用于该分析的逐样品数据或分群体四格表、检测编码和纳入排除规则、群体定义、先验参数及来源、所选依赖结构、MCMC设置和随机种子、敏感性分析配置，以及原始结果对应的软件版本。输出中的 `analysis_settings.json`、`model_used.jags`、`sessionInfo.txt` 和 `analysis.rds` 用于核对实际运行。

本公开包包含软件和模拟示例，不包含论文实测数据。若仅发布本包，论文应表述为“分析软件源代码及运行说明已公开”，不能仅凭该存档声称论文全部数值结果均可复现。

## Distribution contents

Generated reports, saved posterior draws, runtime logs and private working notes are omitted. Historical structured validation summaries remain for provenance. Historical references to omitted generated files can be reproduced with the associated scripts; they are not files guaranteed to be present in this source distribution. See `release_manifest.json` for the exact archived file list and SHA-256 hashes.
