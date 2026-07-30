"""
Reviewer-grade ECG metrics (fixes H1 in 00_CRITICAL_REVIEW). Report ALL of these
every run, not just top-1 accuracy, on a class-imbalanced AAMI task.

macro-F1 (primary), accuracy, Cohen's kappa, per-class sensitivity (Se=recall) and
positive predictivity (+P=precision), and the confusion matrix.

Uses sklearn (already a project dependency). Pure function; self-check at bottom.
"""
from __future__ import annotations
import numpy as np
from sklearn.metrics import (confusion_matrix, f1_score, cohen_kappa_score,
                             precision_score, recall_score, accuracy_score)

AAMI = ["N", "S", "V", "F"]   # SVEB=S, VEB=V


def ecg_report(y_true, y_pred, classes=AAMI) -> dict:
    y_true = np.asarray(y_true); y_pred = np.asarray(y_pred)
    labels = list(range(len(classes)))
    se = recall_score(y_true, y_pred, labels=labels, average=None, zero_division=0)     # per-class Se
    pp = precision_score(y_true, y_pred, labels=labels, average=None, zero_division=0)   # per-class +P
    f1 = f1_score(y_true, y_pred, labels=labels, average=None, zero_division=0)
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "macro_f1": float(f1_score(y_true, y_pred, labels=labels, average="macro", zero_division=0)),
        "kappa": float(cohen_kappa_score(y_true, y_pred, labels=labels)),
        "per_class": {c: {"Se": float(se[i]), "+P": float(pp[i]), "F1": float(f1[i])}
                      for i, c in enumerate(classes)},
        "confusion": confusion_matrix(y_true, y_pred, labels=labels).tolist(),
    }


def format_report(rep: dict) -> str:
    lines = [f"accuracy={rep['accuracy']:.4f}  macro_F1={rep['macro_f1']:.4f}  kappa={rep['kappa']:.4f}",
             "per-class  Se / +P / F1:"]
    for c, m in rep["per_class"].items():
        lines.append(f"  {c}: {m['Se']:.3f} / {m['+P']:.3f} / {m['F1']:.3f}")
    lines.append("confusion (rows=true, cols=pred): " + str(rep["confusion"]))
    return "\n".join(lines)


def _selfcheck():
    rng = np.random.default_rng(0)
    # imbalanced like AAMI: N dominates. A majority-class predictor must look BAD on macro-F1.
    y = np.concatenate([np.zeros(900), np.ones(40), np.full(40, 2), np.full(20, 3)]).astype(int)
    maj = np.zeros_like(y)                       # always predict N
    rep_maj = ecg_report(y, maj)
    assert rep_maj["accuracy"] > 0.85, "majority predictor should have high accuracy"
    assert rep_maj["macro_f1"] < 0.30, "macro-F1 must expose majority-class collapse"
    # a near-perfect predictor scores high on both
    good = y.copy(); good[rng.random(len(y)) < 0.02] = 0
    rep_good = ecg_report(y, good)
    assert rep_good["macro_f1"] > 0.8 and rep_good["kappa"] > 0.8
    print("metrics self-check OK  | majority-class: acc=%.3f but macro_F1=%.3f (correctly exposed)"
          % (rep_maj["accuracy"], rep_maj["macro_f1"]))


if __name__ == "__main__":
    _selfcheck()
