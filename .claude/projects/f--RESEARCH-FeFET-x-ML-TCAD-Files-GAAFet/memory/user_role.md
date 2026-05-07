---
name: User role
description: Thesis student doing GAA-FeFET LIF neuron — TCAD (Sentaurus 2023.12) + Python SNN (PyTorch). Strong on physics and numerical setup, expects deep technical reasoning.
type: user
---

The user is doing a thesis on GAA-FeFET-based LIF neurons for spiking neural networks. They:

- Run **Sentaurus 2023.12** (sdevice / SWB) on a remote server for TCAD.
- Develop the SNN in **PyTorch** with surrogate-gradient BPTT (snnTorch-style).
- Have completed device calibration (16 runs), Phase 1A/1B characterization, and Step 2 v1 SNN training.
- Care about *physical fidelity* (don't accept "rough estimates" — they want true power integration, true τ_leak from τ_P > 0 runs, true C_gg from AC).
- Expect deep reasoning before code (they explicitly asked: documenting/decision-making first, then files).
- Trust working in-repo references over training data; remind them to grep the references when proposing syntax.

How to apply: When proposing TCAD work, lead with the *measurement design* (what's being extracted, why, how to interpret the .plt output) before showing the .cmd block. When proposing Python work, distinguish what's already at 90.18% (don't break it) vs new exploratory branches.
