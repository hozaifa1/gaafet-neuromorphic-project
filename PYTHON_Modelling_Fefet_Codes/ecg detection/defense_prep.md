# Defense Prep — THE FULL STORY (in simple terms, in order)

## The one-sentence picture first
We built a small "brain-like" program that reads heartbeats and sorts them into 4 types. The "connection strengths" of that brain — the part that actually holds all the learned knowledge — are stored physically inside **our device**. We show the device holds that knowledge faithfully, that it genuinely does the work, that it survives real-world imperfections, and that our Gate-All-Around design beats a simpler flat (planar) design at this job.

## Step 1 — The data (what we feed it)
- **ECG (electrocardiogram)** = the electrical signal your heart makes with every beat — the familiar "blip" waveform.
- We use a standard public collection called **MIT-BIH**, taking **2000 heartbeats**.
- Each beat is one of **4 classes**:
  - **N (Normal):** an ordinary healthy beat.
  - **VEB (Ventricular ectopic beat):** a beat that starts in the wrong place (the lower heart chambers) — wide, odd-shaped, potentially dangerous.
  - **SVEB (Supraventricular ectopic beat):** an early beat from the upper chambers — looks almost normal, so it's the hardest to spot.
  - **F (Fusion):** a mix of a normal and an abnormal beat colliding.
- The counts are **1000 / 500 / 250 / 250** — mostly normal, like real life. This is called **class imbalance** (some types are rare).
- **Preprocessing:** each beat is cut to about half a second and its size is scaled into a small voltage range (0 to 0.6 volts) so the circuit can handle it.
- **Train/test split:** we teach the network on **1664** beats and hide **336** beats to test it later. Hiding the test beats is like giving a **fair exam on questions the student never saw** — it proves the network really learned, not memorized.

## Step 2 — Turning the wiggly beat into "spikes"
- Brain cells don't talk in smooth signals — they talk in **spikes** (tiny electrical blips). Our network is a **spiking** network, so we first convert each beat into spikes.
- We use a **delta / level-crossing encoder.** Simple idea: it only fires a spike **when the signal changes** by a set step — an **up-spike** when the beat rises, a **down-spike** when it falls. Like a **doorbell that only rings when something moves**, not continuously.
- Flat parts of the beat → almost no spikes. The sharp part of the heartbeat (the tall "QRS" spike) → a burst of spikes.
- We add a third channel called the **CUE** — a "**now make your decision**" signal that tells the network when the answer is due.
- Result: **3 spike channels**, and only about **3.6% of the time is anything firing** — very sparse. Sparse = little activity = **low energy**.

## Step 3 — The "software" part (this is what "software" means here)
- We build a small spiking neural network as a **computer program in Python first — no device yet.** This is the **software model**.
- A **neural network** = artificial neurons joined by connections, and each connection has a **weight** (a number saying how strong that connection is).
- **Training** = the program practices on the 1664 beats over and over, gradually adjusting all its weights until it classifies beats well. When training finishes, we have a **trained set of weights** — the network's "knowledge."
- Our network is an **LSNN (Long Short-Term-Memory Spiking Neural Network)** — a spiking network that also has **memory** of what happened earlier in the beat. Structure: **3 inputs → connections → a hidden layer of 160 neurons (100 of one kind + 60 of another) → smoothing → 4 output neurons (one per class).**

**Key point to say out loud:** at this stage everything is just numbers in a computer. The device hasn't entered yet.

## Step 4 — The neurons (the decision-makers) — these are NOT our device
- A **LIF neuron (Leaky Integrate-and-Fire)** is like a **leaky bucket:** incoming signal fills it; when it's full enough it "fires" a spike and empties; "leaky" means it slowly drains if no input arrives. So it responds to *bursts of input that arrive together*.
- An **ALIF neuron (Adaptive Leaky-Integrate-and-Fire)** is the same bucket but it gets **tired** after firing a lot — temporarily harder to fire again. This gives the network a **sense of time** (it can tell "I was very active a moment ago").
- **Important:** these neurons are made of **ordinary silicon transistor circuits (CMOS)** — the standard building block of all chips. **They are NOT our special device.** We deliberately keep the neuron ordinary so that any success is credited to **our device, which is the connection (the synapse).**

## Step 5 — WHERE OUR DEVICE COMES IN (the heart of the paper)
The **weights** (connection strengths) are just numbers in software. **In hardware, we store each weight as the conductance of our FeFET device.** Here's the physics, simply:

- Our device is a **transistor** with a special layer in its gate called a **ferroelectric** (the material Hafnium-Zirconium-Oxide).
- **Ferroelectric** = a material that can be **electrically polarized and remembers that state even with the power off** (this is called **non-volatile** — it doesn't forget).
- The ferroelectric is made of many tiny regions ("domains"). When we apply **programming pulses**, we flip a *fraction* of these domains. **More pulses → more flipped → a different, higher setting.**
- The amount of flipped polarization shifts the transistor's **threshold voltage (Vth)** — that's the gate voltage at which the transistor **turns on**. (Think of Vth as the "**turn-on point**.")
- Now we read the device at a **fixed small voltage.** A shifted turn-on point means a **different amount of current flows** — which means a different **conductance** (conductance = how easily current flows = how "open the tap" is; it's the opposite of resistance).
- So the chain is: **programming pulses → polarization → threshold-voltage (Vth) shift → a distinct conductance level.** We measured **15 distinct, stable conductance levels** — a "**ladder**" spanning about **4 orders of magnitude** (a factor of ~13,000 from smallest to largest).
- **Memory window (MW)** = the total distance the threshold voltage moves between the fully-erased and fully-programmed states. In simple terms, **the memory window is how wide the whole ladder is.** Bigger memory window = wider range of possible conductances.
- Because a connection weight can be **positive or negative** but a conductance is only positive, we use **two devices per weight** and take their difference — this gives us positive and negative weights.

So: **your device physics (polarization → threshold-voltage shift → conductance level), sitting inside the memory window, is exactly what stores each learned weight.**

## Step 6 — How the device actually "detects" — the on/off question answered
This is the part to get exactly right, because it's a common misunderstanding.

**Your device is NOT switched on or off "for each of the 4 classes."** It's not "one device = one class." Instead:

1. The incoming spikes are applied as small **voltages on the rows** of a grid ("crossbar") of your devices.
2. Each device lets through a current equal to **its stored conductance × the input voltage.** (This is the "Ohm's-law" step — explained below.)
3. All the currents flowing into the **same column add up on the shared wire** (this is **Kirchhoff's current law** — currents joining a wire sum together).
4. That summed column current is **exactly the "weighted sum"** the neural network needs — the multiply-and-add is done **physically, by the device grid, all at once.** This is called **in-memory computing** (the weights never move; the math happens where the weights are stored).
5. These summed currents feed the neurons (Step 4), which fire spikes. Over the decision window, the **4 output neurons build up activity, and whichever output is highest is the predicted class** (this "pick the biggest" step is called **argmax**).

So detection works like this: the beat's spike pattern flows through the whole grid of thousands of device conductances; the collective result lights up the correct one of the 4 output neurons. **It's the *pattern* across many device conductances that computes the answer — not a single device toggling per class.** Your device's job is to hold the right conductance so the sums come out right.

## Step 7 — Going from software to the real device ("deployment")
- After training, the software weights are precise decimal numbers. The real device can only make **15 specific conductance levels.** So we **snap each trained weight to the nearest available level** — like **rounding every value to the nearest step on a staircase.** This is called **post-training quantization** ("quantization" = rounding to allowed levels).
- Then we run the network with these snapped weights on the hidden test beats and see if it still works. This tests **faithfulness.**

## Step 8 — The results (with each term explained)
- **Software (full precision):** accuracy **0.857** (85.7% of test beats classified correctly), macro-F1 **0.793**.
  - **Accuracy** = fraction correct overall.
  - **macro-F1** = a fairness score that treats each class equally (so the rare, important classes count as much as "Normal"). It's the honest number on imbalanced data, because a lazy "always say Normal" classifier would look good on accuracy but terrible on macro-F1.
- **On our device (15 levels):** **0.830 / 0.754** — a drop of only **−2.7% / −3.9%.** This tiny drop is called **faithfulness:** the real device holds the trained brain almost perfectly.
- **Load-bearing test ("ablation"):** if we cripple the device to only **2 levels** (like a plain on/off light switch), accuracy **crashes to 0.563 / 0.286.**
  - **Ablation** = deliberately removing a capability to see if it mattered.
  - **Load-bearing** = it was doing real work. This proves the **many analog levels are essential**, not decoration.

## Step 9 — Robustness (surviving real-world imperfections) — each test explained
Real devices aren't perfect, so we stress-test using the device's **own measured imperfections**:
- **Temperature:** we measured the device at three temperatures — **250, 300, and 350 Kelvin** (cold, room, hot). The conductance ladder shifts with temperature. We plug in the actual measured hot and cold ladders and re-test → it still works.
- **Retention:** after we program a level, the conductance **drifts very slightly over time.** We measured this as about **−2.9% over 100 microseconds** (a microsecond is a millionth of a second). We apply that measured drift → it still works (accuracy 0.824 / 0.754).
- **Device-to-device variation:** two "identical" devices are never exactly the same. We add that measured randomness → still works.
- **Cycle-to-cycle variation:** even the *same* device, programmed twice, lands slightly differently each time. We add that too → still works.
- All of these degrade **gracefully** — meaning **slowly and safely, with no sudden cliff.** That's what "robust" means here.

## Step 10 — Energy (why it's efficient)
- Because it's **spike-based (sparse)** and computes **in-memory (no shuttling data back and forth)**, the core computation costs only about **0.54 nanojoules per heartbeat** (a nanojoule is a billionth of a joule — extremely small). Measured, not assumed: only **1.94 %** of the hidden neurons fire in any given timestep, so the array is read event-driven, 103.9 pJ; the neuron membranes cost 432 pJ.
- **Writing the whole array once costs 69.6 picojoules** — about **one eighth of a single inference.** Because the FeFET is non-volatile, that is paid once and never again. This is the concrete answer to "why a ferroelectric weight."
- **Honest caveat, and it is a big one:** that 0.54 nJ is the **core computing** cost. The supporting circuits a full chip needs — mainly the analog-to-digital converters on each column — come to roughly **183 nanojoules per beat** under a standard 1 pJ-per-conversion assumption, i.e. **342× the core.** We put that in the figure rather than in a footnote. The device is not the bottleneck of a full system, and we do not claim it is.

## Step 11 — The comparison story (our Gate-All-Around device vs a planar device)
- We compare our **Gate-All-Around** device (the gate wraps all around the channel) to a **planar** device (a flat, single-gate version). We made them **identical in every way except we removed the bottom gate** — a fair, controlled comparison (an "ablation" at the device level).
- **The planar device actually WINS the basic transistor contest:**
  - bigger **memory window** (1.42 volts vs our 0.387 volts),
  - bigger **on/off current ratio** (how much more current flows on vs off),
  - similar or slightly better **subthreshold slope** (how sharply it switches on — sharper is better),
  - even slightly better **retention.**
- **BUT for the actual ECG job, our Gate-All-Around device WINS:**
  - accuracy **0.830 vs 0.804**, macro-F1 **0.754 vs 0.700**,
  - and on the **hardest class, SVEB**, F1 **0.585 vs 0.431** (our device catches 19 of 40 tricky beats; planar catches only 14).
- **Why?** The task depends on how many **fine, evenly-spaced conductance levels** the device can produce. Ours makes **15 smooth, well-spread levels**; the planar makes only **10 clumpy ones** (its level-building curve is an "S-shape" — flat, then a few big jumps, then flat, so many settings pile up and can't be told apart).
- **The punchline (a strong device-design insight):** the planar device wins almost every basic transistor metric, yet loses the neuromorphic task — because the task rewards the one thing our Gate-All-Around design does better: **fine analog conductance resolution.**

## Step 12 — THE parameter the whole ECG detection depends on
Say this clearly:

> **"The ECG detection depends on the device's multilevel ON-CURRENT resolution — that is, the number and even spacing of distinguishable read-current levels (equivalently conductance levels) on the potentiation curve. More, evenly-graded current levels improve detection; fewer, clumpier levels worsen it."**

Then connect it to the familiar terms:
- These current levels are **created by the threshold-voltage (Vth) shifts** (each level is one shifted turn-on point read as a current), and their total span is **bounded by the memory window (MW).** So Vth and memory window are the **physics behind** the levels.
- **But the task itself rides on the *resolution* of those on-current levels — not on the memory window or threshold-voltage size directly.** Proof: the planar device has a **bigger memory window and threshold-voltage shift and on/off ratio**, yet it **loses** — because it has **fewer, coarser current levels.**
- **One caution:** it's the **number and spacing of current levels**, not the raw current magnitude — so don't say "more current is better," say "**more distinguishable current levels** is better."

**Short version:** "It depends on the multilevel on-current (read-current) resolution — the number of distinguishable conductance levels — produced by the threshold-voltage shift within the memory window. Not the memory window itself, not the raw threshold voltage."

## Step 13 — Why EEG failed the comparison
- We also tried **EEG (electroencephalogram = brain electrical signal)** for **seizure detection**, which is a **2-choice (binary) problem: seizure or not.**
- On EEG, our device did **not** clearly beat the planar — they were comparable, and at some settings planar even edged ahead.
- **Why, simply:** a **2-choice decision is easy on the weights** — you don't need fine, precise connection strengths to separate just two options, so the planar's coarser levels don't hurt it. The **4-class ECG is much more demanding** — telling apart 4 similar heartbeat shapes (especially the near-normal SVEB) needs **fine weight precision**, which is exactly where our device's extra levels help.
- (There's also a technical reason: EEG uses a probability threshold, and rounding to device levels shifts each device's probabilities differently, which makes that particular comparison unreliable.)
- **Conclusion:** the device advantage only reveals itself when the task is **hard enough to need fine weight resolution.** The 4-class ECG is; the binary EEG isn't. **So we focus the comparison on ECG.**

## Step 14 — The Ohm's-law question (the honest answer)
A nanoscale ferroelectric transistor is a **very nonlinear device**, so it is **not** a simple resistor that obeys Ohm's law everywhere. The honest, correct way to say it:

- We **operate every device at a fixed, small read voltage** (about 50 millivolts, below the turn-on point). At that **one fixed, small operating point**, the current through each device is **proportional to its stored conductance** — a **local, small-signal linear approximation.** That's the only sense in which "Ohm's law" is used: **current ≈ conductance × (fixed read voltage).** We are not claiming the transistor is linear in general — just that, held at this small read point, current tracks the programmed conductance, which is all the multiply needs.
- **Simple analogy:** think of each device as a **tap (faucet) set to a certain openness (its conductance).** At a **fixed, gentle water pressure (the small read voltage)**, the flow through each tap is proportional to how open it is; the flows joining a shared pipe add up. As long as the pressure stays gentle and fixed, "flow ∝ openness" holds well enough to do the sum.
- **Honest caveats (say these, they strengthen you):** at nanoscale and in a real large grid, there are **non-idealities** — resistance in the wires causing voltage to droop along a line (called "IR-drop"), stray leakage currents through unselected paths, device nonlinearity if voltages get large, and device variability. That's exactly **why we keep the read voltage small**, and why we describe our energy and accuracy as **device-level, first-order estimates** — the full-grid non-idealities are outside this device-level study, and we state that openly in our limitations.

Correct line to the supervisor: *"We don't treat the transistor as ohmic in general — only as a fixed-small-read-bias linear element where current is proportional to the programmed conductance. The full nonlinearity and array non-idealities are acknowledged as out of scope for this device-level model."*

## If he asks "so what's the ONE headline?"
> *"We store a spiking network's weights in our measured Gate-All-Around ferroelectric device, run heart-beat classification, and show the device holds it faithfully, does the work (a 2-level version collapses), and survives temperature, drift, and variation. Crucially, our device beats an otherwise-identical planar device on the task even though the planar wins the basic transistor metrics — because the task depends on the multilevel on-current resolution, which our gate-all-around design provides. Binary EEG doesn't show this because it's too easy on the weights, so we focus on the 4-class ECG."*
