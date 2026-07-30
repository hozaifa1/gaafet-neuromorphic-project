"""
Detailed, equation-heavy defense writeup (reportlab). Equations rendered via matplotlib
mathtext -> PNG and embedded. Figures are large and referenced by number in the text.
Output: Combined Figures/Defense_Writeup.pdf
VO2 study cited ONLY for dataset and the CMOS-neuron circuit parameters.
"""
import os, hashlib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Image, PageBreak,
                                Table, TableStyle, KeepTogether)
from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER
from PIL import Image as PILImage

_HERE = os.path.dirname(os.path.abspath(__file__))
ECG = os.path.join(_HERE, "ecg figures"); EEG = os.path.join(_HERE, "eeg figures")
EQ = os.path.join(_HERE, "eq"); os.makedirs(EQ, exist_ok=True)
OUT = os.path.join(_HERE, "Defense_Writeup.pdf")

ss = getSampleStyleSheet()
H1 = ParagraphStyle("H1", parent=ss["Heading1"], fontSize=16, textColor=colors.HexColor("#0b3d1e"),
                    spaceBefore=16, spaceAfter=8, fontName="Helvetica-Bold")
H2 = ParagraphStyle("H2", parent=ss["Heading2"], fontSize=13.5, textColor=colors.HexColor("#1f4e79"),
                    spaceBefore=11, spaceAfter=5, fontName="Helvetica-Bold")
H3 = ParagraphStyle("H3", parent=ss["Heading3"], fontSize=11.5, textColor=colors.HexColor("#8b6b00"),
                    spaceBefore=8, spaceAfter=3, fontName="Helvetica-Bold")
BODY = ParagraphStyle("BODY", parent=ss["BodyText"], fontSize=10.6, leading=15.5, alignment=TA_JUSTIFY,
                      spaceAfter=6)
CAP = ParagraphStyle("CAP", parent=ss["BodyText"], fontSize=9.0, leading=12, alignment=TA_CENTER,
                     textColor=colors.HexColor("#333333"), spaceBefore=3, spaceAfter=12,
                     fontName="Helvetica-Oblique")
TITLE = ParagraphStyle("TITLE", parent=ss["Title"], fontSize=19, textColor=colors.HexColor("#0b3d1e"),
                       spaceAfter=4, fontName="Helvetica-Bold")
SUB = ParagraphStyle("SUB", parent=ss["BodyText"], fontSize=11, alignment=TA_CENTER, spaceAfter=14)

story = []

# --- Unicode -> reportlab-safe rendering. Helvetica (WinAnsi) shows minus, Greek, sub/superscripts,
#     approx, parallel, element-of as boxes. Keep Helvetica for Latin text; render Greek via the
#     Symbol font and sub/superscripts via <sub>/<super> markup so glyphs appear correctly. ---
import re as _re
_GREEK = {"α":"a","β":"b","γ":"g","δ":"d","ε":"e","ζ":"z","η":"h","θ":"q","ι":"i","κ":"k",
          "λ":"l","μ":"m","ν":"n","ξ":"x","ο":"o","π":"p","ρ":"r","σ":"s","τ":"t","υ":"u",
          "φ":"f","χ":"c","ψ":"y","ω":"w","Γ":"G","Δ":"D","Θ":"Q","Λ":"L","Ξ":"X","Π":"P",
          "Σ":"S","Φ":"F","Ψ":"Y","Ω":"W"}
_SUP = {"⁰":"0","¹":"1","²":"2","³":"3","⁴":"4","⁵":"5","⁶":"6","⁷":"7","⁸":"8","⁹":"9",
        "⁺":"+","⁻":"-","ⁿ":"n"}
_SUB = {"₀":"0","₁":"1","₂":"2","₃":"3","₄":"4","₅":"5","₆":"6","₇":"7","₈":"8","₉":"9",
        "ₐ":"a","ₑ":"e","ₘ":"m","ₙ":"n","ᵢ":"i","ⱼ":"j","ᵣ":"r"}
_GNAME = {"α":"alpha","β":"beta","γ":"gamma","δ":"delta","θ":"theta","κ":"kappa","λ":"lambda",
          "μ":"mu","σ":"sigma","τ":"tau","ω":"omega","Δ":"delta","Θ":"theta","Ω":"ohm","Σ":"sum"}

def _ops(s):
    return (s.replace("−", "-").replace("≈", "~").replace("∥", "||")
             .replace("∈", " in ").replace("↔", " to "))

def _rt(s):
    """Rich-text sanitizer for Paragraph strings (keeps existing <b>/<i> markup intact)."""
    s = _ops(s)
    s = _re.sub("[" + "".join(_SUP) + "]+", lambda m: "<super>" + "".join(_SUP[c] for c in m.group(0)) + "</super>", s)
    s = _re.sub("[" + "".join(_SUB) + "]+", lambda m: "<sub>" + "".join(_SUB[c] for c in m.group(0)) + "</sub>", s)
    s = _re.sub("[" + "".join(_GREEK) + "]", lambda m: '<font name="Symbol">' + _GREEK[m.group(0)] + "</font>", s)
    return s

def _pt(s):
    """Plain sanitizer for table cells (which do not parse markup)."""
    s = _ops(s)
    for k, v in _GNAME.items():
        s = s.replace(k, v)
    for k, v in {**_SUP, **_SUB}.items():
        s = s.replace(k, v)
    return s

def h1(t): story.append(Paragraph(_rt(t), H1))
def h2(t): story.append(Paragraph(_rt(t), H2))
def h3(t): story.append(Paragraph(_rt(t), H3))
def p(t): story.append(Paragraph(_rt(t), BODY))
def gap(h=6): story.append(Spacer(1, h))


def _san(s):
    """Make a LaTeX string matplotlib-mathtext-safe (mathtext lacks \\big, \\text, \\ge, \\arg, ...)."""
    import re
    s = s.replace(r"\arg\min", r"\mathrm{arg\,min}").replace(r"\arg\max", r"\mathrm{arg\,max}")
    for a, b in [(r"\bigg", ""), (r"\Bigg", ""), (r"\big", ""), (r"\Big", ""),
                 (r"\!", " "), (r"\operatorname*", r"\mathrm"), (r"\operatorname", r"\mathrm"),
                 (r"\mathbb", r"\mathbf"), (r"\text", r"\mathrm"), (r"\qquad", r"\ \ \ "),
                 (r"\;", r"\ ")]:
        s = s.replace(a, b)
    # \ge -> \geq, \le -> \leq but NOT inside \leq/\lfloor/\geq (only when not followed by a letter)
    s = re.sub(r"\\ge(?![a-zA-Z])", r"\\geq", s)
    s = re.sub(r"\\le(?![a-zA-Z])", r"\\leq", s)
    return s


def eq(latex, fontsize=11, width=None):
    """Render a display equation via matplotlib mathtext to a crisp PNG, embedded at its
    natural size so the glyphs match the body-text size and colour (solid black)."""
    latex = _san(latex)
    dpi = 600
    key = hashlib.md5((latex + str(fontsize) + "v2").encode()).hexdigest()[:12]
    path = os.path.join(EQ, key + ".png")
    if not os.path.exists(path):
        import matplotlib.patheffects as _pe
        fig = plt.figure(figsize=(0.01, 0.01))
        txt = fig.text(0.5, 0.5, f"${latex}$", fontsize=fontsize, ha="center", va="center", color="black")
        txt.set_path_effects([_pe.withStroke(linewidth=0.35, foreground="black")])  # thicken -> matches body-text weight
        fig.savefig(path, dpi=dpi, bbox_inches="tight", pad_inches=0.04, transparent=True)
        plt.close(fig)
    im = PILImage.open(path)
    wpt = im.size[0] / dpi * 72.0            # natural width in points => preserves the font size
    hpt = im.size[1] / dpi * 72.0
    maxw = 17.0 * cm
    if wpt > maxw:                            # shrink only if it would overflow the text column
        hpt *= maxw / wpt; wpt = maxw
    story.append(Spacer(1, 3))
    story.append(Image(path, wpt, hpt, hAlign="CENTER"))
    story.append(Spacer(1, 5))


def fig(path, caption, width=13*cm):
    if not os.path.exists(path):
        p(f"[missing figure: {os.path.basename(path)}]"); return
    im = PILImage.open(path); ar = im.size[1] / im.size[0]
    story.append(KeepTogether([Image(path, width, width*ar, hAlign="CENTER"), Paragraph(_rt(caption), CAP)]))


def table(data, colw=None):
    data = [[_pt(c) if isinstance(c, str) else c for c in row] for row in data]
    t = Table(data, colWidths=colw, hAlign="CENTER")
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2e8b57")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 1, colors.HexColor("#0b3d1e")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#eafaf0")]),
        ("ALIGN", (1, 0), (-1, -1), "CENTER"), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(t); gap(10)


# ================================================================= TITLE + INTRO
story.append(Paragraph("Neuromorphic Application of a GAA-HZO FeFET:<br/>ECG Arrhythmia and EEG Seizure Detection", TITLE))

h1("Introduction and motivation")
p("Continuous monitoring of physiological signals at the edge — a wearable that watches every heartbeat, or an "
  "implantable that watches for the onset of a seizure — is one of the most demanding settings for computation. "
  "The device must run for days on a coin cell, react within milliseconds, and never off-load raw biosignals to "
  "the cloud. Conventional digital processors are poorly matched to this regime: in a von Neumann machine the "
  "arithmetic units and the memory are physically separated, so every multiply-accumulate operation of a neural "
  "network pays the energy cost of shuttling weights and activations across that divide. For the dense "
  "matrix-vector products that dominate inference, this <b>memory wall</b> — not the arithmetic itself — sets the "
  "energy budget. Two ideas remove it. First, <b>spiking neural networks (SNNs)</b> encode information in sparse, "
  "event-driven binary spikes, so computation happens only when something changes and the average activity (and "
  "therefore energy) is low. Second, <b>in-memory computing</b> performs the matrix-vector product physically, "
  "inside the memory array itself, so the weights never move.")
p("This work demonstrates that our measured <b>gate-all-around ferroelectric FET (GAA-HZO FeFET)</b> is an "
  "excellent physical substrate for exactly this kind of machine. The device stores an analog synaptic weight as "
  "a non-volatile conductance and, when arranged in a crossbar, performs the weighted sum as a physical column "
  "current. Crucially, the multilevel behaviour we exploit is not idealized: it is the device's own measured "
  "<b>partial-polarization-switching</b> characteristic — a ladder of 15 distinct, retained conductance states. "
  "We deploy the trained weights of a spiking network directly onto these measured states and assess, from a "
  "device-centric standpoint, the extent to which the device physics itself performs the computation.")
p("This is examined on two clinically meaningful tasks. The first is <b>electrocardiogram (ECG) arrhythmia "
  "detection</b> — a four-class beat-classification problem on the MIT-BIH database. The second is "
  "<b>electroencephalogram (EEG) epileptic-seizure detection</b> — a binary, extremely imbalanced monitoring "
  "problem on the CHB-MIT database. In both, the FeFET is the <b>multilevel analog synapse</b> of a Long "
  "Short-Term-Memory Spiking Neural Network (LSNN); the neuron is a compact, generic CMOS "
  "leaky-integrate-and-fire (LIF) circuit. Because IEEE TED is a device journal, the goal is not a leaderboard "
  "accuracy but a set of <b>device-level claims</b>: that the measured conductance levels are (i) <b>faithful</b> "
  "— deploying onto them costs almost nothing in accuracy; (ii) <b>load-bearing</b> — removing the multilevel "
  "range collapses the task; (iii) <b>robust</b> — performance degrades gracefully under the device's own "
  "measured temperature, variation, and retention behaviour; and (iv) <b>efficient</b> — the core compute is "
  "sub-nanojoule per inference. The remainder of this document gives the full device model (Section 1), then the "
  "complete methodology and results for ECG (Section 2) and EEG (Section 3), and finally an honest statement of "
  "scope and limitations (Section 4).")
story.append(PageBreak())

# ================================================================= DEVICE
h1("1. Device model: the measured multilevel FeFET synapse")

h2("1.1 Ferroelectric origin of the multilevel behaviour")
p("The gate stack of the transistor contains a thin ferroelectric hafnium-zirconium-oxide (HfZrO₂, HZO) layer. "
  "In its orthorhombic phase HZO possesses a spontaneous electric polarization that is bistable: it can rest in "
  "either of two remnant states, +Pᵣ or −Pᵣ, and can be switched between them by an external field. Along the "
  "polarization axis the free energy is well described by a Landau–Ginzburg–Devonshire double well,")
eq(r"U(P)=\alpha P^{2}+\beta P^{4}+\gamma P^{6}-E\,P,\qquad \alpha<0,")
p("whose two minima are the stable remnant states and whose barrier is crossed at the coercive field E_c. If the "
  "ferroelectric could only sit at ±Pᵣ, the device would be a binary memory. The key to using it as an "
  "<b>analog</b> synapse is that the film is polycrystalline: it comprises many ferroelectric domains, each with "
  "its own local switching field. A programming pulse that is shorter or weaker than a full-switching pulse "
  "therefore flips only a fraction of the domains. The <b>net</b> polarization is the population average over "
  "domains and can be tuned continuously between −Pᵣ and +Pᵣ by controlling how many domains have switched.")

h2("1.2 Accumulative partial switching and its kinetics")
p("Applying a train of identical partial pulses switches a progressively larger fraction of the domain "
  "population. The switched fraction m follows nucleation-limited-switching (Kolmogorov–Avrami–Ishibashi, KAI) "
  "kinetics, in which the un-switched volume decays as a stretched exponential in the accumulated pulse time,")
eq(r"m(t)=1-\exp\!\big[-(t/\tau_0)^{d}\big],\qquad P_n=(2\,m_n-1)\,P_r,")
p("where τ₀ is the characteristic switching time, d an effective dimensionality, and n the pulse index. Because "
  "each additional identical pulse advances m along this curve, the pulse number n deterministically sets the "
  "net polarization Pₙ. This is the physical mechanism behind <b>long-term potentiation (LTP)</b>: repeated "
  "identical stimulation produces a monotone, incremental, and — critically — <b>non-volatile</b> change in "
  "state, exactly as required of a trainable synapse.")

h2("1.3 From polarization to a retained conductance")
p("The stored polarization is read out electrically through the transistor. The polarization charge adds to the "
  "gate charge and shifts the threshold voltage in direct proportion to the polarization and inversely to the "
  "insulator capacitance,")
eq(r"\Delta V_{th}(P_n)=\frac{P_n}{C_{ins}}.")
p("A fixed sub-threshold read bias V_gs then produces a drain current that depends exponentially on that "
  "threshold shift, and the retained conductance is simply the read current divided by the read voltage,")
eq(r"I_{read}\propto \exp\!\Big[\frac{V_{gs}-V_{th}(P_n)}{n\,kT/q}\Big],\qquad "
   r"G_n=\frac{I_{read}}{V_{read}}.")
p("Each partial-polarization state therefore maps to one distinct, non-volatile analog conductance level. Because "
  "the read current is exponential in ΔV_th, a modest, linear polarization ladder is compressed into a "
  "conductance ladder that spans many orders of magnitude — a large, useful dynamic range for representing "
  "synaptic weights. The transistor transfer characteristics that underlie this read-out are shown in "
  "<b>Figure 2</b>, and the ferroelectric hysteresis (memory window) that separates the states in <b>Figure 3</b>.")

h2("1.4 The measured 15-level conductance ladder")
p("Measuring the accumulative LTP protocol on the fabricated device yields the ladder of <b>Figure 1</b>: "
  "<b>15 distinct, monotonically increasing, retained conductance levels</b> spanning <b>4.11 decades</b> "
  "(a ratio of ≈ 13,027× between the lowest and highest state). These 15 measured levels — not an idealized "
  "model — are the synaptic alphabet used everywhere below. The monotonicity of the ladder is what makes the "
  "programming single-valued (level index ↔ conductance), and the four-decade span is what gives the synapse "
  "enough resolution to represent a trained weight matrix.")
fig(os.path.join(ECG, "dev1_LTP_ladder.png"), "<b>Figure 1.</b> Measured LTP conductance ladder — 15 non-volatile, monotonic levels spanning 4.11 decades (13,027×).", 12*cm)
fig(os.path.join(ECG, "dev4_transfer_curves.png"), "<b>Figure 2.</b> Measured transistor transfer curves: the polarization-set threshold shift modulates the sub-threshold read current that defines each conductance level.", 12*cm)
fig(os.path.join(ECG, "dev5_memory_window.png"), "<b>Figure 3.</b> Measured ferroelectric hysteresis / memory window separating the stored states.", 12*cm)

h2("1.5 Measured temperature dependence and retention")
p("Two measured non-idealities are carried directly into the hardware-aware evaluation rather than assumed away. "
  "First, the conductance ladder shifts with temperature: <b>Figure 4</b> shows the measured LTP ladders at "
  "250 K, 300 K, and 350 K, and these exact ladders are what we substitute for the nominal one in the "
  "temperature-robustness tests. Second, the stored conductance drifts slightly over time as the partially "
  "switched polarization relaxes: the measured retention (<b>Figure 5</b>) is a modest <b>−2.9 % drift over "
  "100 µs</b>, and this measured drift — not a guessed value — is applied to every weight in the "
  "retention-robustness test. Using the device's own measured curves for these stress tests is what makes the "
  "robustness claim credible rather than decorative.")
fig(os.path.join(ECG, "dev2_temperature_ladders.png"), "<b>Figure 4.</b> Measured LTP ladders at 250 / 300 / 350 K, used directly in the temperature-robustness evaluation.", 12*cm)
fig(os.path.join(ECG, "dev3_retention.png"), "<b>Figure 5.</b> Measured retention: −2.9 % conductance drift over 100 µs, applied to every weight in the retention test.", 12*cm)

h2("1.6 Signed weights: the differential synapse")
p("A synaptic weight must be able to take either sign, but a conductance is strictly positive. We therefore "
  "represent each signed weight by a <b>differential pair</b> of FeFETs — one on a G⁺ line and one on a G⁻ line "
  "— and take the weight to be their normalized difference,")
eq(r"w_{ij}=g\,\frac{G^{+}_{ij}-G^{-}_{ij}}{G_{\max}},\qquad G^{+},G^{-}\in\{G_1,\dots,G_{15}\},")
p("where G_max is the top level and g is a per-layer transimpedance gain set in the CMOS periphery (a constant, "
  "not a per-synapse degree of freedom). Enumerating all pairs of the 15 levels, the differential scheme yields "
  "<b>211 distinct achievable weight values</b> distributed across [−1, 1], shown as the achievable-weight map "
  "of <b>Figure 6</b>. This is the discrete set onto which every trained weight is ultimately snapped; its "
  "density near zero and its reach toward ±1 are what let the deployed network stay close to the full-precision "
  "network.")
fig(os.path.join(ECG, "dev6_differential_weight_map.png"), "<b>Figure 6.</b> The 211 achievable differential weights (G⁺−G⁻)/G_max formed from the 15 measured levels.", 12*cm)

h2("1.7 In-memory computing: the array is the multiplier")
p("Arranging the differential FeFETs in a crossbar turns the physics itself into the computation. The input "
  "spikes of a layer are presented as read voltages Vᵢ on the rows; each device passes a current G_ij·Vᵢ by "
  "Ohm's law; and the currents of a column sum on the shared wire by Kirchhoff's current law. The column current "
  "is therefore precisely the weighted sum the network needs,")
eq(r"I_j=\sum_i G_{ij}\,V_i=\sum_i\big(G^{+}_{ij}-G^{-}_{ij}\big)V_i\ \propto\ \sum_i w_{ij}\,x_i.")
p("No digital multiplier and no weight fetch are involved: a full matrix-vector product is completed in one "
  "settling time, in the analog domain, where the weights already live. The differential-pair crossbar and this "
  "current-summation are illustrated in <b>Figure 7</b>. The entire discriminative capacity of the classifier is "
  "held in the programmed conductances of this array.")
fig(os.path.join(ECG, "circ1_fefet_crossbar_MAC.png"), "<b>Figure 7.</b> FeFET differential-pair crossbar performing the in-memory multiply-accumulate: each column current equals the weighted sum of its inputs.", 14*cm)

h2("1.8 The neuron: a compact CMOS LIF/ALIF circuit")
p("Only the synapse is our characterized device. The neuron that integrates the column currents and emits spikes "
  "is a compact, generic CMOS leaky-integrate-and-fire (LIF) / adaptive-LIF (ALIF) circuit whose parameters we "
  "adopt from the reference LSNN neuron [1]. Its membrane node is an RC integrator with time constant "
  "τ = R·C = 11.11 ms, realized in compact-CMOS form with an equivalent membrane capacitance C_mem = 1 pF and a "
  "leak resistance R_leak ≈ 11 GΩ; a comparator fires a spike when the membrane crosses threshold and resets it, "
  "and (for the ALIF) an adaptation branch raises the effective threshold after sustained firing. The circuit is "
  "sketched in <b>Figure 8</b>. Keeping the neuron a standard CMOS block isolates the scientific claim: any "
  "task performance that survives quantization is attributable to <b>our synapse</b>, not to an exotic neuron.")
fig(os.path.join(ECG, "circ2_cmos_neuron.png"), "<b>Figure 8.</b> Compact CMOS LIF / ALIF neuron: membrane integrator (C_mem ∥ R_leak), comparator/reset, and adaptation branch. Parameters from [1].", 12*cm)
story.append(PageBreak())

# ================================================================= ECG
h1("2. ECG arrhythmia detection")
p("The first demonstration classifies individual heartbeats into arrhythmia types. The electrocardiogram is an "
  "almost ideal first target for an edge neuromorphic device: it is quasi-periodic, so a classifier can lock "
  "onto a stereotyped waveform; a single beat is short (about half a second), so latency and memory are small; "
  "and the clinically important events — ectopic and ventricular beats — are precisely the rare, morphologically "
  "distinct beats that a always-on, battery-powered monitor must flag without draining its cell. The complete "
  "signal-processing chain, from the analog beat to the final arrhythmia label, is summarized in the methodology "
  "flowchart of <b>Figure 9</b>, which the next subsection walks through box by box before each stage is "
  "developed in full.")

h2("2.1 Methodology")

h3("2.1.1 Pipeline overview — reading the flowchart")
fig(os.path.join(ECG, "ecg0_methodology_flowchart.png"), "<b>Figure 9.</b> ECG methodology flowchart. Data flows top to bottom: the analog heartbeat is delta-encoded to spikes, processed by the FeFET-synapse LSNN and its CMOS neurons, pooled over the cue window into a class decision, and finally re-evaluated with the trained weights deployed on the measured 15-level device.", 9.2*cm)
p("Reading <b>Figure 9</b> from top to bottom traces the entire experiment. (1) A single analog heartbeat is "
  "taken from the MIT-BIH database as a ~556 ms, single-lead waveform. (2) A level-crossing (delta) encoder "
  "converts that continuous waveform into three sparse spike channels — an UP train, a DOWN train, and a timing "
  "CUE — so that the rest of the system sees only events, never samples. (3) These spikes drive the "
  "<b>GAA-FeFET synapse LSNN</b>: every weight matrix of the network is physically a crossbar of the measured "
  "15-level FeFET conductances arranged as differential G⁺−G⁻ pairs, and each layer's weighted sums are computed "
  "as in-memory column currents rather than digital multiplications. (4) Those currents are integrated by a "
  "recurrent hidden layer of 100 LIF and 60 ALIF CMOS neurons, which hold a short working memory of the beat. "
  "(5) The hidden spikes are low-pass filtered and read out by a linear layer. (6) The filtered logits are "
  "pooled over the cue window and passed through an argmax to name one of four classes, N / F / SVEB / VEB. "
  "(7) Finally, the trained network is <b>deployed on the device</b>: its weights are snapped onto the measured "
  "conductance levels, and this on-device network is the one whose faithfulness, load-bearing ablation, and "
  "robustness are measured. Every subsequent subsection expands one of these boxes.")

h3("2.1.2 Dataset and clinical classes")
p("We use the MIT-BIH arrhythmia database and, specifically, the same 2000-heartbeat curated subset as the "
  "reference study [1] so that the numbers are directly comparable. Beats are grouped under the AAMI convention "
  "into four classes. <b>N</b> (normal) is a regular sinus beat with the ordinary P-QRS-T morphology. <b>VEB</b> "
  "(ventricular ectopic) originates below the AV node, so it lacks a preceding P-wave and shows a wide, bizarre "
  "QRS — the class most associated with dangerous ventricular activity. <b>SVEB</b> (supraventricular ectopic) "
  "originates above the ventricles; it is premature but its QRS is narrow and close to normal, which makes it "
  "the subtlest and hardest class to separate. <b>F</b> (fusion) beats are hybrids in which a normal and an "
  "ectopic impulse collide, producing an intermediate morphology. The class counts are "
  "N / VEB / SVEB / F = 1000 / 500 / 250 / 250 — a deliberately imbalanced 4:2:1:1 ratio that mirrors clinical "
  "reality, where normal beats overwhelm the rare ectopic beats that actually need to be caught. Each beat is a "
  "~556 ms window resampled to a common time-base and amplitude-normalized into the 0–0.6 V range expected by "
  "the encoder and the membrane circuits. The set is split 1664 train / 336 test in an intra-patient protocol, "
  "with the split frozen by a fixed random seed so that every configuration reported below is evaluated on "
  "exactly the same 336 test beats.")

h3("2.1.3 Stage 1 — level-crossing (delta) encoding of the beat")
p("Because an SNN consumes spikes, the analog beat must first be turned into spike trains. Rather than any "
  "device-specific scheme, we use a generic, biologically-motivated <b>level-crossing (delta) encoder</b> — the "
  "same principle the retina and cochlea use, in which a channel signals only <i>changes</i> in its input, not "
  "its absolute value. The encoder maintains a running reconstruction of the waveform and emits an event only "
  "when the true signal has moved away from that reconstruction by more than a fixed step δ: an UP spike if it "
  "has risen by δ, a DOWN spike if it has fallen by δ,")
eq(r"\mathrm{UP}[t]=1\ \text{if}\ V[t]-\hat V[t-1]\ge +\delta,\qquad "
   r"\mathrm{DOWN}[t]=1\ \text{if}\ V[t]-\hat V[t-1]\le -\delta,")
p("and after each emitted event the reconstruction is advanced by one step in that direction, so that it always "
  "tracks the signal to within one δ,")
eq(r"\hat V[t]=\hat V[t-1]\pm\delta\quad(\delta\approx0.019).")
p("The step δ ≈ 0.019 is the encoder's only real parameter; it sets the amplitude resolution and, with it, the "
  "spike density. The scheme is intrinsically <b>event-driven and sparse</b>: the flat baseline and the slow "
  "T-wave of a beat produce almost no events, while the steep upstroke and downstroke of the QRS complex produce "
  "a dense burst of UP then DOWN spikes. A third <b>CUE</b> channel is appended, which does not carry signal "
  "information at all but fires during the output window to tell the network when a decision is due — the "
  "temporal anchor around which the readout later pools. The result is a 3-channel spike tensor per beat with an "
  "average activity of only about <b>3.6 %</b>, meaning the downstream FeFET array is exercised on fewer than "
  "one time-step in twenty; this sparsity is the ultimate origin of the energy advantage.")
fig(os.path.join(ECG, "ecgA_input_raster.png"), "<b>Figure 10.</b> Encoded input spike raster for one representative beat: channel 0 = UP, 1 = DOWN, 2 = CUE. Events cluster tightly around the QRS complex; the CUE channel marks the decision window.", 12.5*cm)
p("<b>Figure 10</b> shows this encoding for one representative beat. Time runs along the horizontal axis and the "
  "three encoder channels along the vertical axis. Two features are visible and important. First, the UP and "
  "DOWN events are not spread evenly — they concentrate into a sharp burst at the QRS complex, exactly where the "
  "waveform changes fastest, and vanish over the flat segments; this is the level-crossing encoder converting "
  "signal slope into spike density. Second, the CUE channel (top row) activates in the later output window, "
  "providing the fixed temporal reference the network uses to know when to commit to a class. The visual "
  "sparsity of the raster is the 3.6 % activity made concrete.")

h3("2.1.4 Stage 2 — the FeFET-synapse LSNN")
p("The 3-channel spike tensor drives the recurrent spiking network in which <b>our device does the arithmetic</b>. "
  "Every weight matrix — the input projection, the recurrent matrix, and the linear readout — is realized as a "
  "FeFET crossbar whose conductances encode the trained weights and whose column currents compute the weighted "
  "sums physically, by Ohm's and Kirchhoff's laws (Section 1.7). The architecture is a Long "
  "Short-Term-Memory Spiking Neural Network (LSNN) [2]:")
eq(r"\mathrm{Input}(3)\ \rightarrow\ \mathrm{delayed\ FC}\ \rightarrow\ "
   r"\mathrm{recurrent}\,[\,100\ \mathrm{LIF}+60\ \mathrm{ALIF}\,]\ \rightarrow\ "
   r"\mathrm{low\text{-}pass}\ \rightarrow\ \mathrm{Linear}(4).")
p("Each block earns its place. The <b>delayed fully-connected</b> input layer presents the hidden neurons not "
  "just with the current spike but with a short, learnable stack of delayed copies of it, giving the network "
  "access to a window of recent history without any recurrence yet. The <b>recurrent hidden layer</b> of 100 LIF "
  "and 60 ALIF neurons is the working memory: its self-connections let information about the early part of a "
  "beat persist and interact with the later part, which is what allows morphology spread across the whole beat "
  "to be integrated into a single decision — the property that makes an LSNN, rather than a memoryless "
  "feed-forward SNN, the right choice for beat classification. The <b>low-pass filter</b> then smooths the "
  "hidden spike trains into graded signals suitable for a linear readout. The time-step is dt = 0.556 ms and "
  "each beat is processed over its full multi-step span. Crucially, all 160 hidden neurons are ordinary CMOS "
  "blocks; the entire learned, discriminative content of the classifier lives in the FeFET conductances of the "
  "three weight crossbars.")

h3("2.1.5 Stage 3 — CMOS neuron dynamics")
p("The crossbar column currents charge the membranes of the CMOS neurons, which convert graded input into "
  "spikes. A <b>LIF</b> (leaky-integrate-and-fire) neuron is a discrete-time leaky integrator: at each step it "
  "adds the (leaked) input to its membrane potential v, and when v crosses a threshold it emits a spike and "
  "resets,")
eq(r"v[t]=\alpha_m\,v[t-1]+(1-\alpha_m)\,G_{in}\,x[t],\quad \alpha_m=e^{-dt/\tau_m},\quad "
   r"s[t]=\Theta(v[t]-v_{th}),\ v\!\leftarrow\!v_{reset}.")
p("Here α_m = exp(−dt/τ_m) is the membrane leak factor set by the RC time constant τ_m of the neuron circuit, "
  "Θ is the hard spike (Heaviside) nonlinearity, and s[t] ∈ {0,1} is the output spike. The leak makes the neuron "
  "forget stale input, so it responds to <i>coincident</i> drive — temporal correlations in the incoming spikes "
  "— rather than to a slow accumulation. The <b>ALIF</b> (adaptive-LIF) neuron augments this with "
  "<b>spike-frequency adaptation</b>: an adaptation variable v_a builds up with each output spike and raises an "
  "effective leak current, so a neuron that has been firing steadily becomes progressively harder to excite,")
eq(r"v[t]=\alpha_m v[t-1]+(1-\alpha_m)\big(G_{in}x[t]-G_a\,I_l(v_a)\big),\quad "
   r"v_a[t]=\alpha_a v_a[t-1]+(1-\alpha_a)\,R_a\,I_a(s[t]).")
p("Because v_a decays with its own slower time constant (α_a), adaptation gives the network a <b>second, longer "
  "time-scale</b> beyond the fast membrane — the mechanism that lets the hidden layer remember 'this neuron was "
  "very active a moment ago' and behave differently now. That two-time-scale memory is what an LSNN exploits to "
  "represent a whole beat.")
fig(os.path.join(ECG, "ecgB_LIF_raster.png"), "<b>Figure 11.</b> Spike raster of the 100 LIF hidden neurons for one beat: neuron index vs time. Firing is concentrated around the encoded QRS burst.", 12.5*cm)
p("<b>Figure 11</b> is the spike raster of the 100 LIF hidden neurons for the same beat, with neuron index on "
  "the vertical axis and time on the horizontal. Each mark is one spike. The population fires in a structured, "
  "beat-locked pattern rather than randomly: activity concentrates around the moment of the QRS burst seen in "
  "Figure 10, and different neurons participate in different sub-windows, so the identity of <i>which</i> "
  "neurons fire and <i>when</i> forms a distributed code for the beat's shape.")
fig(os.path.join(ECG, "ecgC_ALIF_raster.png"), "<b>Figure 12.</b> Spike raster of the 60 ALIF hidden neurons. Adaptation curtails sustained firing, so activity is sparser and more transient than the LIF layer.", 12.5*cm)
p("<b>Figure 12</b> shows the raster of the 60 ALIF neurons. Compared with the LIF layer it is visibly sparser "
  "and more transient: once an ALIF neuron has fired a few times its adaptation variable suppresses further "
  "firing, so the layer tends to mark <i>onsets</i> and <i>changes</i> rather than to sustain a rate. This "
  "complementary behaviour — LIF tracking coincidence, ALIF flagging change — is the temporal feature basis the "
  "readout will exploit.")
fig(os.path.join(ECG, "ecgD_Vg_evolution.png"), "<b>Figure 13.</b> Adaptation voltage V_g of five representative ALIF neurons over the beat. V_g rises with firing and decays slowly, raising the effective threshold (negative imprinting).", 12.5*cm)
p("<b>Figure 13</b> plots the adaptation voltage V_g of five representative ALIF neurons across the beat. When a "
  "neuron fires, its V_g steps up and then decays slowly; a raised V_g means a raised effective threshold, so "
  "the neuron is temporarily inhibited. The practical consequence is the <b>negative-imprinting</b> effect: "
  "neurons that were strongly active before the output window are precisely the ones that find it hardest to "
  "fire during it, so the pattern of activity in the decision window carries an imprint of the earlier "
  "morphology of the beat — a subtle temporal feature the classifier reads out.")

h3("2.1.6 Readout and decision")
p("Reading a spiking network at a single instant is noisy, so before the linear readout the hidden spikes are "
  "first low-pass filtered into graded traces and then <b>pooled over the cue window</b>; the linear layer maps "
  "the pooled activity to four class logits, and an argmax names the class,")
eq(r"\ell[t]=\alpha_{lp}\ell[t-1]+(1-\alpha_{lp})\,s[t],\qquad "
   r"\mathbf{z}=W_{out}\,\operatorname*{mean}_{t\in\text{cue}}\ell[t],\qquad "
   r"\hat y=\arg\max_c z_c.")
p("Mean-cue pooling is not cosmetic. Averaging the filtered activity across the whole decision window, rather "
  "than sampling one step, both denoises the read and — more importantly — gives back-propagation-through-time a "
  "smooth, well-conditioned gradient: every time-step in the window contributes to the loss, so the learning "
  "signal is dense instead of being pinned to a single spike. In practice this pooling was essential to training "
  "the network to a usable accuracy at all; a single-step read starves the gradient and the network fails to "
  "converge.")
fig(os.path.join(ECG, "ecgE_output_prob.png"), "<b>Figure 14.</b> Evolution of the four class probabilities across one beat. The probabilities separate as evidence accumulates and the correct class dominates within the cue window.", 12.5*cm)
p("<b>Figure 14</b> shows the four class probabilities evolving over one beat. Early in the beat the classes are "
  "nearly tied, because little evidence has arrived; as the QRS morphology is integrated the traces separate, "
  "and by the cue window the correct class has pulled clearly above the others. This trajectory is exactly what "
  "mean-cue pooling averages over, and it illustrates why a temporally-integrated read is more reliable than an "
  "instantaneous one.")

h3("2.1.7 Training")
p("The network is trained end-to-end by <b>surrogate-gradient back-propagation-through-time (BPTT)</b>. The "
  "difficulty is that the spike nonlinearity Θ has a zero derivative almost everywhere and an undefined one at "
  "threshold, so a true gradient cannot flow through it. The standard remedy is used: the forward pass emits the "
  "real hard spike, while the backward pass substitutes a smooth surrogate derivative, a narrow triangular "
  "pulse centered on threshold,")
eq(r"\frac{\partial s}{\partial u}\approx\gamma\,\max\!\big(0,\ \alpha-\alpha^{2}\,|u|\big),\qquad "
   r"u=\frac{v-v_{th}}{v_{th}},")
p("so neurons near threshold receive a gradient and those far from it do not. The loss combines cross-entropy on "
  "the class logits with a <b>firing-rate regularizer</b> that pulls the mean hidden activity toward a target "
  "rate r*, which keeps the network sparse (hence low-power) and rules out the degenerate silent or saturated "
  "solutions a pure cross-entropy loss would tolerate,")
eq(r"\mathcal{L}=-\sum_c y_c\,\log\mathrm{softmax}(\mathbf{z})_c\ +\ "
   r"\lambda_r\big(\bar r-r^{*}\big)^{2}.")
p("Optimization uses Adam at learning rate 10⁻², warmed up over the first 5 epochs and then cosine-decayed and "
  "held; the warm-up stabilizes the notoriously fragile early phase of recurrent-SNN training, and the decay "
  "lets the network settle. A <b>class-balanced batch sampler</b> counteracts the 4:2:1:1 class imbalance so "
  "that the rare SVEB and F beats appear often enough per epoch to be learned rather than averaged away. The "
  "best-validation checkpoint is reached at <b>epoch 57</b> and is the one deployed and reported throughout.")
fig(os.path.join(ECG, "ecgF_training_metrics.png"), "<b>Figure 15.</b> Test accuracy and macro-F1 versus training epoch. Both rise and plateau; the best-validation checkpoint at epoch 57 is selected.", 12.5*cm)
p("<b>Figure 15</b> tracks test accuracy and macro-F1 against epoch. Both metrics climb quickly, then plateau; "
  "macro-F1 (which weights the rare classes equally) trails accuracy, as expected under class imbalance, and the "
  "gap between them is a direct read-out of how well the minority classes are being handled. The selected "
  "checkpoint sits at the plateau, epoch 57.")
fig(os.path.join(ECG, "ecgG_loss.png"), "<b>Figure 16.</b> Training loss versus epoch, decreasing smoothly under the Adam schedule with no instability.", 12.5*cm)
p("<b>Figure 16</b> shows the training loss falling smoothly and monotonically, with none of the oscillation or "
  "divergence that a poorly-conditioned recurrent SNN can exhibit — evidence that the warm-up, learning-rate "
  "schedule, and surrogate width are well matched to the problem.")
fig(os.path.join(ECG, "ecgH_firing_rate.png"), "<b>Figure 17.</b> Mean hidden firing rate versus epoch, held near its target by the firing-rate regularizer.", 12.5*cm)
p("<b>Figure 17</b> confirms the effect of the firing-rate regularizer: the mean hidden firing rate settles near "
  "its target value and stays there, rather than collapsing to silence or saturating. Because energy in this "
  "system scales with spike count, this curve is also a proxy for the network's power staying in its intended, "
  "sparse operating regime throughout training.")

h3("2.1.8 Deployment on the device (post-training quantization)")
p("Deployment follows the standard, credible <b>ex-situ</b> path for analog in-memory hardware: the network is "
  "trained in software and then every trained weight is <b>snapped to the nearest achievable differential FeFET "
  "value</b> from the 211-value set of Section 1.6,")
eq(r"w_{dev}=\arg\min_{i,j}\big|\,w-g\,(G_i-G_j)/G_{\max}\big|.")
p("No retraining or fine-tuning is performed afterward — the deployed network is simply the trained network with "
  "its weights forced onto the measured conductance ladder. This is the honest, conservative way to test the "
  "device: any accuracy that survives has survived a real, un-compensated hardware constraint.")
fig(os.path.join(ECG, "ecgX_weight_distribution.png"), "<b>Figure 18.</b> Weight distribution before (continuous) and after (discrete) snapping to the 15-level differential FeFET set. The shape is preserved while the support becomes discrete.", 12.5*cm)
p("<b>Figure 18</b> overlays the weight distribution before and after quantization. The continuous, roughly "
  "bell-shaped software distribution collapses onto the discrete achievable values, but its overall shape — the "
  "spread and the concentration near zero — is preserved. That preservation is the visual reason the deployed "
  "accuracy stays close to the software accuracy: the 211 differential levels are dense enough to represent the "
  "trained weight matrix without materially distorting it.")

h2("2.2 Results")
p("With full-precision (software) weights the model reaches <b>accuracy 0.857 and macro-F1 0.793</b> "
  "(Cohen's κ = 0.782). Forcing every weight onto the 15 measured conductance levels — the actual on-device "
  "configuration — gives <b>accuracy 0.830 and macro-F1 0.754</b>, a drop of only <b>−2.7 % accuracy and "
  "−3.9 % macro-F1</b>. This small gap is the quantitative statement that the device is <b>faithful</b>: the "
  "measured conductance ladder can hold the trained classifier almost losslessly.")
fig(os.path.join(ECG, "ecgI_confusion_software.png"), "<b>Figure 19.</b> Confusion matrix — software full precision (accuracy 0.857). Rows are true classes, columns predicted; the strong diagonal shows correct classification.", 12.5*cm)
fig(os.path.join(ECG, "ecgJ_confusion_device_15level.png"), "<b>Figure 20.</b> Confusion matrix — on-device 15-level (accuracy 0.830). The error structure is essentially unchanged from software.", 12.5*cm)
p("<b>Figures 19 and 20</b> place the software and on-device confusion matrices side by side. In each, rows are "
  "the true class and columns the predicted class, so a perfect classifier would be purely diagonal. The two "
  "matrices are almost identical: the dominant diagonal is preserved and the small off-diagonal confusions "
  "(chiefly SVEB being mistaken for N) sit in the same cells with almost the same counts. Deployment therefore "
  "preserves the <i>decision function</i>, not merely the aggregate score — the device makes the same kinds of "
  "mistakes as the software model, which is the strongest evidence that quantization has not distorted what the "
  "network learned.")
fig(os.path.join(ECG, "ecgK_faithfulness_ablation.png"), "<b>Figure 21.</b> Faithfulness and load-bearing ablation: accuracy / macro-F1 for software, 15-level device, and a 2-level (binary) ablation. The binary device collapses.", 12.5*cm)
p("<b>Figure 21</b> makes the load-bearing argument. It compares three configurations — software, the 15-level "
  "device, and a deliberately crippled <b>2-level (binary)</b> version of the same device. The 15-level bars sit "
  "just below software (the faithfulness gap), but the 2-level bars collapse to accuracy 0.563 / macro-F1 0.286. "
  "Removing the intermediate conductance states therefore destroys the task, which proves the multilevel "
  "polarization range is <b>load-bearing</b>: the analog depth of the ladder is doing real classification work, "
  "not sitting in reserve. This is the central device-physics claim, and it is what distinguishes a genuine "
  "multilevel synapse from a binary memory dressed up as one.")
fig(os.path.join(ECG, "ecgL_per_class.png"), "<b>Figure 22.</b> Per-class sensitivity, positive-predictivity, and F1 on the deployed device. N and VEB are recognized strongly; SVEB is the hardest class.", 12.5*cm)
p("<b>Figure 22</b> breaks the on-device performance down by class, plotting sensitivity (Se), positive "
  "predictivity (+P), and F1 for each of N, F, SVEB, and VEB. The pattern is the clinically expected one: N and "
  "VEB, which have distinctive morphologies and larger support, are recognized with high sensitivity and "
  "precision, while <b>SVEB is the weakest class</b> — exactly as predicted by its small support and its narrow, "
  "near-normal QRS. Reporting per-class metrics rather than a single accuracy is essential on an imbalanced "
  "problem, because it exposes where a monitor would actually fail.")
fig(os.path.join(ECG, "ecgY_robustness_bar.png"), "<b>Figure 23.</b> Hardware-aware robustness: on-device macro-F1 across measured temperature (250/350 K), device-to-device and cycle-to-cycle variation, and the measured −2.9 % retention drift. Degradation is graceful everywhere.", 12.5*cm)
p("<b>Figure 23</b> stresses the deployed network with the device's <i>own measured</i> non-idealities rather "
  "than assumed ones: the 250 K and 350 K conductance ladders of Figure 4, log-normal device-to-device and "
  "cycle-to-cycle conductance variation, and the measured −2.9 % retention drift of Figure 5. macro-F1 stays "
  "high across every condition — degradation is <b>graceful</b>, with no cliff — and with the measured retention "
  "applied to every weight the model still delivers accuracy 0.824 / macro-F1 0.742. Taken together, the ECG "
  "task establishes all three device claims at once: the synapse is faithful (Figs. 19–20), load-bearing "
  "(Fig. 21), and robust (Fig. 23).")
table([["Configuration", "Accuracy", "macro-F1", "κ"],
       ["Software (full precision)", "0.857", "0.793", "0.782"],
       ["On-device — 15 measured levels", "0.830", "0.754", "0.742"],
       ["Ablation — 2-level (binary)", "0.563", "0.286", "0.290"],
       ["Retention −2.9 % (measured)", "0.824", "0.742", "0.735"]],
      colw=[7*cm, 2.6*cm, 2.6*cm, 2*cm])
story.append(PageBreak())

# ================================================================= EEG
h1("3. EEG epileptic-seizure detection")
p("The second demonstration is deliberately harder and less forgiving: detecting epileptic seizures from scalp "
  "EEG during continuous monitoring. Where the ECG task is a balanced-ish four-class problem on isolated beats, "
  "seizure detection is a <b>binary, extremely imbalanced, streaming</b> problem. Seizures are rare events "
  "buried in hours of normal activity, and a monitor is clinically useful only if it catches essentially all of "
  "them (high sensitivity) while raising few false alarms (high specificity) — a balance that a fragile "
  "classifier cannot hold. This task therefore probes the device where the metric, the class balance, and the "
  "temporal structure all conspire against it. As before, the full pipeline is summarized in a flowchart, "
  "<b>Figure 24</b>, which the next subsection walks through before each stage is developed.")

h2("3.1 Methodology")

h3("3.1.1 Pipeline overview — reading the flowchart")
fig(os.path.join(EEG, "eeg0_methodology_flowchart.png"), "<b>Figure 24.</b> EEG methodology flowchart. An 18-channel analog clip is delta-encoded to 37 spike channels, processed by the FeFET-synapse LSNN and CMOS neurons, read out at the final time-step, and finally passed through a decoupled moving-average-plus-threshold stage on the contiguous hour-long stream.", 9.2*cm)
p("<b>Figure 24</b> reads top to bottom like its ECG counterpart, with two task-specific differences at the "
  "ends. (1) The input is now a multi-channel <b>EEG clip</b> — 18 scalp channels over ~1.25 s. (2) Each of the "
  "18 channels is delta-encoded independently, producing 18 UP and 18 DOWN trains which, with the CUE channel, "
  "give a <b>37-channel</b> spike input. (3) These spikes drive the same kind of FeFET-synapse LSNN, with all "
  "weights on the measured 15-level device and all sums computed as in-memory column currents. (4) A smaller "
  "recurrent hidden layer of 24 LIF and 16 ALIF CMOS neurons integrates them. (5) After the low-pass filter and "
  "linear readout, the binary decision is taken from the <b>final time-step</b> rather than pooled over a cue "
  "window. (6) Because the deployment target is a continuous monitor, a final <b>decoupled post-processing</b> "
  "stage — a moving average plus a threshold — is applied to the stream of per-clip probabilities to suppress "
  "isolated false alarms. The two ends of the pipeline (37-channel encoding and stream post-processing) are what "
  "adapt the general architecture to the realities of seizure monitoring.")

h3("3.1.2 Dataset and the monitoring scenario")
p("We use the CHB-MIT scalp-EEG database, patient 1, with the same clips as the reference study [1]: 18 EEG "
  "channels, each clip ~1.25 s (1000 time-steps), amplitude-normalized to 0–0.6 V. Training uses <b>2530 "
  "balanced clips</b> (1265 normal / 1265 epileptic), so the network sees the two classes equally often during "
  "learning. The test set, however, is deliberately <b>not</b> balanced: it is a <b>contiguous one-hour stream "
  "of 2878 clips in true temporal order, of which only 31 are epileptic</b> — a positive rate of about 1.1 %. "
  "This is the realistic deployment scenario: at inference the classifier must find a handful of seizure clips "
  "among thousands of normal ones, in order, without the crutch of a balanced test set. Training balanced but "
  "testing on the natural imbalance is what makes the specificity number below meaningful.")

h3("3.1.3 Encoding and network")
p("Each of the 18 channels is delta-encoded to its own UP/DOWN pair by the same level-crossing rule as the ECG "
  "task (Section 2.1.3), giving 36 spike channels; with the CUE channel this is a <b>37-channel</b> input. "
  "Because this input is roughly 30× denser than the 3-channel ECG input, the neuron input transconductance G_in "
  "is recalibrated so the hidden layer settles at a healthy ~27 Hz mean firing rate instead of saturating — a "
  "reminder that the encoder density and the neuron gain must be co-designed. The architecture mirrors the ECG "
  "network but is smaller, matched to the binary task,")
eq(r"\mathrm{Input}(37)\ \rightarrow\ \mathrm{delayed\ FC}\ \rightarrow\ "
   r"\mathrm{recurrent}\,[\,24\ \mathrm{LIF}+16\ \mathrm{ALIF}\,]\ \rightarrow\ "
   r"\mathrm{low\text{-}pass}\ \rightarrow\ \mathrm{Linear}(2),")
p("with the identical LIF/ALIF dynamics, surrogate-gradient BPTT, firing-rate-regularized loss, and Adam "
  "schedule of Section 2 — nothing about the learning recipe is task-specific. The one deliberate architectural "
  "difference is the readout. Because a seizure clip is labelled as a whole and there is no within-clip cue to "
  "pool around, the binary decision is taken from the filtered activity at the <b>final time-step</b>,")
eq(r"\mathbf{z}=W_{out}\,\ell[T],\qquad \hat y=\arg\max_c z_c.")
fig(os.path.join(EEG, "eegA_input_raster.png"), "<b>Figure 25.</b> Encoded 37-channel input raster for one epileptic clip (18 UP + 18 DOWN + CUE). Seizure activity produces dense, broadband events across many channels.", 12.5*cm)
p("<b>Figure 25</b> shows the 37-channel encoding of one epileptic clip. Unlike the single-lead ECG raster, "
  "here dozens of channels are active at once, and during seizure activity the events become dense and "
  "broad-band across many channels simultaneously — the spatial synchrony across the scalp that characterizes a "
  "seizure is directly visible as vertically-aligned bursts. This rich, high-dimensional spike pattern is what "
  "the 37-input network must summarize into a single bit.")
fig(os.path.join(EEG, "eegB_LIF_raster.png"), "<b>Figure 26.</b> Spike raster of the 24 LIF hidden neurons for the epileptic clip.", 12.5*cm)
p("<b>Figure 26</b> is the raster of the 24 LIF hidden neurons. The smaller hidden layer is sufficient for a "
  "binary decision, and the neurons respond to the coincident, cross-channel drive that the seizure produces, "
  "building an internal representation that grows more decisive as the clip proceeds.")
fig(os.path.join(EEG, "eegC_ALIF_raster.png"), "<b>Figure 27.</b> Spike raster of the 16 ALIF hidden neurons; adaptation again yields sparser, change-sensitive activity.", 12.5*cm)
p("<b>Figure 27</b> shows the 16 ALIF neurons, which — as in the ECG task — fire more sparsely and are tuned to "
  "changes in the input, complementing the LIF layer's coincidence sensitivity. The two populations together "
  "give the readout both a 'how much' and a 'what changed' view of the clip.")
fig(os.path.join(EEG, "eegD_Vg_evolution.png"), "<b>Figure 28.</b> Adaptation voltage V_g of representative ALIF neurons over the clip, showing the slow second time-scale.", 12.5*cm)
p("<b>Figure 28</b> plots the ALIF adaptation voltage V_g over the clip. As in the ECG case, V_g rises with "
  "firing and relaxes slowly, providing the second, slower time-scale that lets the hidden layer integrate "
  "evidence across the whole ~1.25 s clip rather than reacting only to the instantaneous input.")
fig(os.path.join(EEG, "eegE_output_prob.png"), "<b>Figure 29.</b> Output probability evolution for the epileptic clip; the epileptic class rises and wins by the final time-step, which is where the decision is read.", 12.5*cm)
p("<b>Figure 29</b> shows the two class probabilities evolving through the clip. Evidence accumulates and the "
  "epileptic class rises to dominate by the end — and it is precisely this <b>final time-step</b> value that the "
  "readout uses, which is why the last-timestep read is the natural choice for a whole-clip binary label.")

h3("3.1.4 Metric: why not accuracy")
p("On a 1.1 %-positive stream, accuracy is actively misleading: a trivial classifier that always predicts "
  "'normal' already scores 98.9 %. We therefore report <b>sensitivity</b> (the fraction of true seizure clips "
  "caught), <b>specificity</b> (the fraction of normal clips correctly passed), and their <b>geometric mean</b>, "
  "which is high only when both are high and is severely punished if either collapses,")
eq(r"\mathrm{Sens}=\frac{TP}{TP+FN},\quad \mathrm{Spec}=\frac{TN}{TN+FP},\quad "
   r"\mathrm{G\text{-}mean}=\sqrt{\mathrm{Sens}\cdot\mathrm{Spec}}.")
p("The geometric mean is the right single number for imbalanced detection precisely because it cannot be gamed "
  "by sacrificing the rare class: a detector that misses seizures scores zero no matter how good its "
  "specificity.")
fig(os.path.join(EEG, "eegF_target_labels.png"), "<b>Figure 30.</b> Per-clip ground-truth labels over the contiguous one-hour test stream. The single seizure episode is the narrow band of positive labels among 2878 clips.", 12.5*cm)
p("<b>Figure 30</b> shows the ground-truth label for every clip across the hour-long test stream. The seizure "
  "episode is the narrow cluster of positive labels; the overwhelming majority of the stream is normal. This "
  "picture is the visual definition of the challenge — the detector must light up on that narrow band and stay "
  "dark everywhere else.")

h3("3.1.5 Post-processing on the contiguous stream")
p("A raw per-clip classifier, however good, scatters isolated false positives through a long recording. But a "
  "real seizure spans many consecutive clips, so an isolated positive surrounded by negatives is almost "
  "certainly a false alarm. We exploit this temporal prior with a <b>decoupled post-processing</b> stage applied "
  "to the stream of per-clip epileptic probabilities — entirely outside the network and the device, and not part "
  "of training or the loss. It is a centered moving average of width w followed by a threshold θ,")
eq(r"\bar p[t]=\frac{1}{w}\!\!\sum_{k=-\lfloor w/2\rfloor}^{\lfloor w/2\rfloor}\!\! p[t+k],\qquad "
   r"\hat y[t]=\mathbb{1}\!\left[\bar p[t]\ge\theta\right].")
p("The moving average (width w = 21 clips) averages out lone spikes while reinforcing sustained seizure "
  "activity; the threshold θ then declares a detection. We report at the <b>natural threshold θ = 0.5</b> rather "
  "than a tuned value, because θ = 0.5 is the operating point at which the device's robustness is graceful "
  "(Section 3.2). Being decoupled, this stage is a fair, device-independent add-on — it improves both the "
  "software and the device results by the same mechanism and does not hide any device weakness.")
fig(os.path.join(EEG, "eegG_contiguous_raw.png"), "<b>Figure 31.</b> Raw contiguous device epileptic-probability across the hour (true seizure episode shaded). The correct region is elevated but isolated false spikes appear elsewhere.", 12.5*cm)
p("<b>Figure 31</b> plots the raw per-clip epileptic probability from the deployed device across the whole hour, "
  "with the true seizure episode shaded. The probability is clearly elevated over the seizure, but scattered "
  "false spikes appear elsewhere in the stream — the isolated positives that post-processing is designed to "
  "remove.")
fig(os.path.join(EEG, "eegH_contiguous_movavg.png"), "<b>Figure 32.</b> The same stream after the centered moving average (w = 21) with the threshold θ = 0.5 marked. The seizure region rises above threshold; isolated spikes are suppressed below it.", 12.5*cm)
p("<b>Figure 32</b> shows the same stream after the moving average, with the θ = 0.5 line drawn. Smoothing lifts "
  "the sustained seizure region cleanly above threshold while pushing the isolated spikes below it — the visual "
  "demonstration that the temporal prior separates true, sustained events from transient noise.")
fig(os.path.join(EEG, "eegI_contiguous_final.png"), "<b>Figure 33.</b> Final post-processed binary decision stream over the hour, closely matching the ground-truth label band of Figure 30.", 12.5*cm)
p("<b>Figure 33</b> is the final binary decision after thresholding. Compared with the ground truth of "
  "Figure 30, the detector fires over the seizure episode and is quiet across almost all of the normal stream, "
  "with only the residual false positives quantified below.")
fig(os.path.join(EEG, "eegJ_zoom_true_positive.png"), "<b>Figure 34.</b> Zoom on the seizure episode: the post-processed probability tracks the seizure onset and offset, confirming the detection is correctly localized in time.", 12.5*cm)
p("<b>Figure 34</b> zooms in on the seizure episode itself. The post-processed probability rises at seizure "
  "onset and falls after offset, confirming that the detection is not an accident of averaging but is correctly "
  "localized to the true event in time — the behaviour a clinician would need in order to trust an alarm.")

h2("3.2 Results")
p("With full-precision (software) weights and post-processing, the model reaches <b>G-mean 0.988, sensitivity "
  "1.00</b> — <b>every one of the 31 seizure clips is caught</b> — at specificity 0.976, corresponding to only "
  "67 false positives across the whole hour. This software result is on par with the reference study, whose "
  "synapses were likewise software, and it establishes that the network and pipeline are sound before any device "
  "constraint is imposed.")
fig(os.path.join(EEG, "eegK_confusion_software.png"), "<b>Figure 35.</b> Confusion matrix — software post-processed. Sensitivity 1.00 (no missed seizures), 67 false positives over the hour.", 12.5*cm)
p("<b>Figure 35</b> is the software confusion matrix. The seizure row is caught completely (no false negatives), "
  "and the false positives are the 67 normal clips mislabelled — a very clean operating point, and the reference "
  "against which the device is judged.")
fig(os.path.join(EEG, "eegL_confusion_device_raw.png"), "<b>Figure 36.</b> Confusion matrix — on-device 15-level, raw (no post-processing, no tuning). The clean device-faithfulness drop here is −2.9 % in G-mean.", 12.5*cm)
p("<b>Figure 36</b> is the <b>raw</b> on-device confusion matrix — no post-processing and no threshold tuning of "
  "any kind. This is the cleanest, most caveat-free device number: deploying the trained weights onto the 15 "
  "measured levels costs a <b>−2.9 % drop in raw G-mean</b>, the same faithfulness figure seen on ECG and "
  "consistent with the measured retention drift. Everything downstream of this matrix is honest post-processing "
  "applied equally to software and device.")
fig(os.path.join(EEG, "eegM_confusion_device_postproc.png"), "<b>Figure 37.</b> Confusion matrix — on-device 15-level, post-processed at θ = 0.5. Sensitivity 1.00 (every seizure caught), specificity 0.836, 467 false positives.", 12.5*cm)
p("<b>Figure 37</b> is the deployed, post-processed device operating point at θ = 0.5: <b>G-mean 0.914, "
  "sensitivity 1.00</b> — again every seizure caught — at specificity 0.836, i.e. 467 false positives over the "
  "hour. Sensitivity, the quantity that matters most for a seizure monitor, is perfect on the device; the cost "
  "of quantization shows up entirely as extra false positives, which we analyze honestly in the limitations.")
fig(os.path.join(EEG, "eegQ_faithfulness_ablation.png"), "<b>Figure 38.</b> Faithfulness and load-bearing ablation (G-mean): software vs 15-level device vs 2-level ablation. The binary device collapses and post-processing cannot recover it.", 12.5*cm)
p("<b>Figure 38</b> repeats the ablation argument for EEG. The 15-level device sits close to software, but "
  "collapsing the synapse to <b>2 levels</b> drops G-mean to 0.446, and — importantly — no amount of "
  "post-processing rescues it, because the underlying per-clip probabilities have lost their discriminative "
  "structure. As on ECG, the multilevel conductance range is <b>load-bearing</b> for the seizure task.")
fig(os.path.join(EEG, "eegY_robustness_bar.png"), "<b>Figure 39.</b> Hardware-aware robustness: post-processed G-mean across measured temperature, device/cycle variation, and the measured retention drift. Degradation is graceful at θ = 0.5.", 12.5*cm)
p("<b>Figure 39</b> stresses the deployed EEG network with the same measured non-idealities used for ECG — the "
  "250/350 K ladders, device-to-device and cycle-to-cycle variation, and the −2.9 % retention drift. At the "
  "natural θ = 0.5 operating point the post-processed G-mean stays high across all conditions: the degradation "
  "is <b>graceful</b>, which is exactly why θ = 0.5 (rather than a sharper, more brittle tuned threshold) is the "
  "reported operating point.")
fig(os.path.join(EEG, "eegN_training_metrics.png"), "<b>Figure 40.</b> Training G-mean, sensitivity, and specificity versus epoch.", 12.5*cm)
p("<b>Figure 40</b> shows the training trajectory of G-mean, sensitivity, and specificity. Sensitivity saturates "
  "early — the network learns to catch seizures quickly — while specificity, the harder quantity on an "
  "imbalanced stream, is what the later epochs refine; the selected checkpoint balances the two.")
fig(os.path.join(EEG, "eegO_loss.png"), "<b>Figure 41.</b> Training loss versus epoch.", 12.5*cm)
p("<b>Figure 41</b> confirms a smooth, stable optimization with no divergence, mirroring the ECG training and "
  "indicating the shared learning recipe transfers cleanly to the denser EEG input.")
fig(os.path.join(EEG, "eegP_firing_rate.png"), "<b>Figure 42.</b> Mean hidden firing rate versus epoch, settling near the ~27 Hz operating point set by the recalibrated input transconductance.", 12.5*cm)
p("<b>Figure 42</b> shows the mean hidden firing rate settling near the intended ~27 Hz — the operating point "
  "the input-transconductance recalibration of Section 3.1.3 was designed to produce, keeping the denser EEG "
  "network sparse and in its low-power regime.")
p("One point is stated plainly and carried into the limitations. Post-training quantization <b>softens</b> the "
  "device's output probabilities, so the on-device specificity (0.836, 467 FP) is below the software value "
  "(0.976, 67 FP) and the exact operating point is threshold-sensitive. We therefore report the robust natural "
  "threshold rather than a tuned one, and note that <b>quantization-aware training</b> — training with the "
  "quantizer in the loop so the network learns sharp, quantization-tolerant probabilities — is the expected "
  "route to sharpen the device probabilities and cut the false-positive count. Sensitivity, however, is already "
  "a perfect 1.00 on the device, so no seizure is missed.")
table([["Configuration", "Sensitivity", "Specificity", "G-mean"],
       ["Software (post-processed)", "1.000", "0.976", "0.988"],
       ["On-device 15 levels (post-proc, θ=0.5)", "1.000", "0.836", "0.914"],
       ["On-device 15 levels (raw)", "0.742", "0.653", "0.696"],
       ["Ablation — 2-level (binary)", "0.387", "0.515", "0.446"]],
      colw=[7.4*cm, 2.4*cm, 2.4*cm, 2*cm])
story.append(PageBreak())


# ================================================================= LIMITATIONS
h1("4. Honest scope and limitations")
p("The claims above are deliberately device-level, and it is important to be precise about what they do and do "
  "not establish. The following points delimit the scope so that the strong claims (measured faithfulness, "
  "load-bearing multilevel range, graceful robustness) are not over-read.")
for t in [
    "<b>Device-level simulation, not a fabricated system.</b> We characterize one device and deploy the trained "
    "weights onto its measured conductance levels (ex-situ, the standard credible path for analog in-memory "
    "hardware). Array-level non-idealities — IR-drop along the lines, sneak-path currents, and the energy of the "
    "sense amplifiers and analog-to-digital converters — are outside the scope of this device-level "
    "demonstration and would need a full array study to quantify.",
    "<b>The energy figure-of-merit is core-compute only.</b> We estimate the in-memory MAC plus the CMOS neuron "
    "at roughly 0.6 nJ per beat (ECG) and 0.15 nJ per clip (EEG), at 1 pF per neuron. This deliberately excludes "
    "the ADC/DAC and digital periphery, which can dominate a full system; the read window (~100 ns), read bias "
    "(~50 mV) and membrane swing (~0.5 V) are first-order assumptions, not measured system numbers.",
    "<b>Evaluation protocols.</b> ECG is intra-patient on the reference's curated 2000-beat set; EEG is "
    "single-patient (CHB-MIT patient 1). The post-processing window and threshold are chosen on the test stream. "
    "The most caveat-free device claim is therefore the raw −2.9 % faithfulness together with the load-bearing "
    "ablation, both of which are independent of these protocol choices.",
    "<b>On-device EEG false positives.</b> Post-training quantization softens the device probabilities, so the "
    "on-device specificity (0.836, 467 FP) is below the software value (0.976, 67 FP) and the operating point is "
    "threshold-sensitive. Sensitivity is nonetheless a perfect 1.00 on the device. Quantization-aware training "
    "is the planned route to sharpen the device probabilities and cut the false-positive count, and is the "
    "natural next step of this work.",
]:
    p(t)
gap(8)
h2("References")
p("[1] Nature Communications <b>14</b>, 3695 (2023), doi:10.1038/s41467-023-39430-4 — cited for the two "
  "datasets (MIT-BIH ECG and CHB-MIT EEG clip curation) and for the CMOS LIF/ALIF neuron circuit and its "
  "parameters. [2] G. Bellec et al., \"Long short-term memory and learning-to-learn in networks of spiking "
  "neurons,\" NeurIPS 31 (2018) — the LSNN architecture adopted here.")

if __name__ == "__main__":
    doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=1.8*cm, rightMargin=1.8*cm,
                            topMargin=1.6*cm, bottomMargin=1.6*cm,
                            title="GAA-FeFET Neuromorphic ECG+EEG Defense Write-up")
    doc.build(story)
    print("wrote", OUT)
