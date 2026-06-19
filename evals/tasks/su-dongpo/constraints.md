# Variant: many constraints + a planted decision (does STRUCTURE beat a reminder?)

The `goal-shift` variant showed B≈C: re-injecting the goal helps, but a plain padded reminder did as
well as the structured anchor. That leaves the real question open — **does Lodestar's structured
schema (labeled Decision / Boundaries / Done-when) hold multiple constraints better than the same
constraints written as an undifferentiated reminder blob?**

This variant tests exactly that. Single fixed thesis (no shift); the variable is **structure**.

## The constraints (identical content for B and C; A loses them after chapter 1)
- **Thesis:** 苏轼以旷达超然消化贬谪 (keywords: 旷达 / 超然 / 豁达 / 随遇而安 / 从容 / 乐观).
- **Planted decision:** 全文正式称呼统一用「苏轼」;正文中不要用「苏东坡」「东坡居士」作为称呼
  (解释"东坡"别号来历时可一次性提及)。 — the 黄州 chapter material literally introduces 号"东坡居士",
  so this decision is tempting to violate.
- **Boundary 1:** 不展开御史台 / 弹劾等制度史 (the 乌台 chapter tempts it).
- **Boundary 2:** 不展开苏辙、苏洵的独立生平传记 (the 元祐 chapter tempts it).

## How each arm receives them (cold restart every chapter)
- **A (bare):** all constraints given **once** at chapter 1; later chapters run fresh → A should
  violate constraints it can no longer see.
- **B (Lodestar):** constraints re-injected every chapter as a **structured, labeled anchor**
  (Goal / Decision / Boundaries).
- **C (placebo):** the **same constraints**, re-injected every chapter as **one unstructured padded
  paragraph**. → **A vs (B,C) tests persistence; B vs C tests whether structure beats a blob.**

## What is measured (objective, on cleaned output)
- `naming_violations`: occurrences of 东坡居士 / 苏东坡 in the body (decision honored → ~0).
- `boundary_inst`: occurrences of 御史台 (institutional-history breach).
- `boundary_family`: occurrences of 苏辙 / 苏洵 (family-biography breach proxy).
- `thesis_tie`: fraction of chapters that keep the thesis.
- `leak_raw`: apparatus markers (Lodestar / 锚点 / 朝向 / Boundaries / 定向参考 …) in the **raw**
  chapter output, **before** cleaning and with a neutral essay title — the corrected T8 check
  (should be ~0 for B after the silent-anchor fix).

## Expected (pre-registered)
- `A` violates more (lost the constraints). `B ≤ C` on violations **if structure helps**; `B ≈ C`
  if it does not — in which case the honest conclusion is that the value is re-injection + hooks,
  not the schema, and `minimal` profile is the right default.
