# Dendukuri & Joseph equation-image audit

Recorded 2026-09-21 (Asia/Shanghai); author-hosted PDF retrieved 2026-09-20. This closes the earlier local-archive and selected-equation-image gaps. It does not replace the full scientific validation or implement the article's sampler.

Source: [author-hosted PDF](https://joseph.research.mcgill.ca/publications/Methodological/conddep_diag.pdf), DOI [10.1111/j.0006-341X.2001.00158.x](https://doi.org/10.1111/j.0006-341X.2001.00158.x). Ten pages, 1,026,048 bytes; SHA-256 `b1031169caf115ad7e2601db5233dfea70c7f215cae5cafd0c5a24899d73abff`. Archived privately as `work/dendukuri_joseph_2001_author.pdf`, outside the distributed application. HTTPS certificate validation remained enabled. Python's verified HTTPS request succeeded with authorized network access after the restricted socket attempt failed; earlier failed access records are retained.

## Visual checks and interpretation

Rendered printed pages 160, 161, 166 and 167 were inspected. Equations 1–2 confirm the covariance signs in the four conditional cells; equation 5 gives the positive covariance upper bound. Page 161 describes a scaled beta. Its printed joint posterior and page 166 accuracy conditionals do not display the margin-dependent scale normalization used by VetBLCM. No exact reproduction of the printed Gibbs algorithm is claimed. Page 167 concerns the unimplemented random-effects model.

## Independent mathematical consequence

For fixed margins, let the feasible positive covariance upper bound be U and let u ~ Beta(a,b), c=U*u. Change of variables gives

```
f(c | margins) = dbeta(c/U,a,b) / U
              = c^(a-1) * (U-c)^(b-1) / (B(a,b) * U^(a+b-1)).
```

The integral of the numerator alone is B(a,b)*U^(a+b-1). U depends on the sensitivity/specificity margins, so it is not a constant in their joint posterior. With a=b=1, the normalized conditional density is 1/U, while a constant-density kernel over the joint feasible region would instead weight the margins by the available width after integrating out covariance. These describe different joint priors. This is an independent mathematical derivation, not a claim about the authors' executed code or an erratum.

VetBLCM retains its explicit generative construction u ~ Beta(a,b), c=U*u (or c=L+(U-L)*u for signed dependence), which already supplies the normalized conditional distribution. No extra factor is added to JAGS, no probability code is changed, and no posterior is refit. The full signed lower bound remains independently derived; the article's positive restriction is not used as a universal signed bound.

Numerical quadrature at 12 combinations of U, a and b checked both integrals, with absolute error below 1e-10: `validation/covariance_normalization_20260921.csv` and `.log`. This checks the density derivation, not frequentist coverage or model identifiability.

Toft et al. (2005) full text remains pending. The follow-up search found an Aarhus bibliographic record and a similarly titled SVEPM conference item; neither was substituted for the requested journal full text. Existing statistical and browser limits remain in QA_STATUS.md.
