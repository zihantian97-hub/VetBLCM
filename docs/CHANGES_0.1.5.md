# VetBLCM 0.1.5 candidate changes

Version 0.1.5 is a guided-entry usability update. It does **not** change any BLCM likelihood, JAGS model, prior mathematics, MCMC settings, diagnostic thresholds, sensitivity-analysis refits, posterior contrasts, or project-level pooling rules.

## Guided entry added

- Page 1 now offers presets for common specimen types, latent target-condition definitions, T1/T2 positivity rules, and equivocal/invalid/missing-result handling. Presets populate the auditable free-text fields; users may edit them.
- qPCR presets deliberately retain placeholders for the exact Ct cutoff and, when relevant, the replicate rule. Workflow validation blocks progression until those placeholders are replaced.
- Page 2 now offers presets for common exclusion descriptions and sample-size rationales. Precision/protocol templates retain placeholders for study-specific details and are blocked until completed.
- Page 4 now provides a bounded population-definition editor. Users choose the population, definition basis, descriptive expected-prevalence level, evidence/source type, and rationale mode. The tool generates Definition/Rationale/Prior_source text, while operational criteria and evidence citations remain user-controlled. Expected prevalence is descriptive only and does not impose ordering in the model.
- Page 5 now provides rationale/applicability presets for weak priors, directly comparable literature, partially transportable literature with ESS discounting, external data, expert elicitation, simulation, or custom rationale.
- Page 6 now provides conservative templates for documenting how latent-class labels are scientifically anchored. The templates explicitly state that external anchoring does not remove structural non-identifiability.

## Guardrails

Preset text is a reporting aid, not evidence. Fields containing explicit placeholders such as "请填写" / "provide specific" fail page validation. Population templates with missing reproducible criteria or missing evidence details also fail validation. A prespecified population stratification with no quantitative external evidence is allowed but generates a reporting warning.

The existing editable fields and editable population table remain available so unusual designs are not forced into presets.
