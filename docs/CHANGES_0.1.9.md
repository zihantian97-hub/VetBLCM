# VetBLCM 0.1.9 changes

- Converted non-action, explanatory UI notes into compact `?` hover/focus help tips to reduce persistent text clutter. Errors, warnings, review advisories and sensitivity diagnostic warnings remain visible.
- `Load simulated example` now populates every prefillable study field: project metadata, latent-state definition, T1/T2 interpretation rules, missing/invalid/equivocal handling, sample-flow fields, guided population controls, complete population documentation, complete simulated prior-provenance metadata, model settings and narrative notes.
- Manual review checkboxes are deliberately not auto-checked, and no fit-dependent diagnostic/result values are fabricated before a model is run.
- Population-guidance detail selection is preserved when it remains valid after changing the definition-basis selector.
- No JAGS likelihood, probability, primary prior-resolution, MCMC fitting or posterior diagnostic formula was changed.
- Windows runtime regression remains pending.
