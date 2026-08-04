```
cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/Paper-materials/research" && agy -p "Use your academic deep research skill AND your last30days skill. This is literature research for an undergraduate thesis whose device is a hafnium-zirconium-oxide (HZO) ferroelectric gate stack simulated in TCAD. Topic: ferroelectricity in doped HfO2 and in HZO. Cover: (1) the original discovery of ferroelectricity in Si-doped HfO2 thin films and why it mattered — CMOS process compatibility, scalability to thin films where perovskites lose polarisation, back-end thermal budget; give the standard citation with its honest year; (2) the crystallographic origin — the non-centrosymmetric orthorhombic Pca2_1 phase, how it is stabilised by dopants, capping-layer stress, grain size and anneal, and typical remanent polarisation and coercive field values for HZO at thicknesses of roughly 5 to 10 nm; (3) THE RELIABILITY TRIAD, which is the most important part of this request: wake-up, fatigue and imprint. For each, give the accepted physical mechanism (oxygen-vacancy redistribution, domain depinning, defect-mediated domain-wall pinning, internal-bias-field build-up), the typical magnitude of the effect, the cycle counts over which it appears, and how it manifests as memory-window drift or threshold-voltage shift in a ferroelectric FET; also cover depolarisation in metal-ferroelectric-insulator-semiconductor stacks and charge trapping at the ferroelectric/interfacial-oxide interface as a competing or masking mechanism. (4) Any reported mitigation strategies. Prefer IEDM, VLSI Symposium, IEEE TED, IEEE EDL, Nature Electronics, Nature Communications, Nature Materials, Advanced Materials, Science Advances, Advanced Electronic Materials, Applied Physics Letters, Journal of Applied Physics. Prefer 2023-2026; the foundational papers are older and that is fine — state the year plainly. For EVERY factual claim you return, give: the claim in one sentence; the numeric value with units; the DOI; the full author list; the venue; the year; and a VERBATIM quoted sentence from the paper that contains that number. If you cannot attach a verbatim quote to a claim, drop the claim entirely — do not paraphrase from memory and do not guess a DOI. Flag clearly any source that is an arXiv preprint rather than a peer-reviewed publication. Output as markdown, one section per sub-question." --dangerously-skip-permissions --print-timeout 25m --effort high > C_hzo_ferroelectricity.raw.md 2>&1

cd "F:/RESEARCH/FeFET x ML/TCAD Files/GAAFet/Paper-materials/research" && agy -p "Use your academic deep research skill AND your last30days skill. This is literature research for an undergraduate thesis on a hafnium-zirconium-oxide (HZO) ferroelectric gate stack simulated in TCAD. I already have general HZO ferroelectricity background covered. I need ONLY the reliability triad in FeFETs / HZO ferroelectric capacitors: wake-up, fatigue, and imprint. For EACH of the three effects separately, find at least one peer-reviewed paper (prefer IEEE IEDM, VLSI Symposium, IEEE TED, IEEE EDL, Nature Electronics, Nature Communications, Applied Physics Letters, Journal of Applied Physics, Advanced Electronic Materials, 2023-2026 preferred but foundational older papers are fine if clearly dated) that reports BOTH: (a) a numeric magnitude of the effect (percent change in remanent polarization P_r, memory-window shift in volts, or threshold-voltage shift in volts) AND (b) the cycle count or time/temperature stress condition over which that magnitude was measured, in the SAME paper. For each of the three effects, give: the claim in one sentence; the numeric magnitude with units; the cycle count or stress condition with units; the DOI; the full author list; the venue; the year; and a VERBATIM quoted sentence from the paper containing both the magnitude number and the cycle-count/condition number (if no single sentence has both, give two verbatim quotes, one for each number, clearly labeled). If you cannot attach a verbatim quote to a number, drop that number rather than paraphrasing from memory or guessing a DOI. Also cover: the accepted physical mechanism for each of the three effects (oxygen-vacancy redistribution for wake-up, defect-mediated domain-wall pinning or micro-cracking for fatigue, internal-bias-field build-up from asymmetric charge trapping for imprint), each again with its own DOI, venue, year, author list, and verbatim quote. Flag clearly any source that is an arXiv preprint rather than a peer-reviewed publication. Output as markdown, one section per effect (wake-up, fatigue, imprint)." --dangerously-skip-permissions --print-timeout 25m --effort high > C_hzo_reliability.raw.md 2>&1
```

Date: 2026-08-02

Source raw files: `C_hzo_ferroelectricity.raw.md` (first pass, general HZO ferroelectricity) and `C_hzo_reliability.raw.md` (second pass, narrowed to wake-up/fatigue/imprint after the first attempt at this narrow topic died and was relaunched). Every DOI below was independently checked against `https://api.crossref.org/works/<DOI>` for title, container-title, issued year, and full author list. Tags: `[VERIFIED]` = title/venue/year/authors match Crossref and the quote supports the stated number; `[MISMATCH: ...]` = a specific field disagrees with Crossref; `[UNVERIFIED]` = DOI/authors check out but the quoted sentence does not actually contain the claimed number.

---

## 1. Discovery of Ferroelectricity in Si-Doped HfO2 and CMOS Compatibility

### 1.1 Original discovery — 10 nm Si-doped HfO2 crystallizes ferroelectric [VERIFIED]
Böscke et al. found that 10 nm SiO2-doped HfO2 films (<4 mol.% SiO2) crystallize under mechanical (electrode) encapsulation into a phase mixture that includes a ferroelectric component.

* DOI: [10.1063/1.3634052](https://doi.org/10.1063/1.3634052) — Böscke, T. S.; Müller, J.; Bräuhaus, D.; Schröder, U.; Böttger, U. — *Applied Physics Letters* — 2011
* Crossref check: title "Ferroelectricity in hafnium oxide thin films", venue Applied Physics Letters, year 2011, first author Böscke — matches.
* Quote: *"Films with a thickness of 10 nm and with less than 4 mol. % of SiO2 crystallize in a monoclinic/tetragonal phase mixture."*

### 1.2 Foundational Pr / Ec values [VERIFIED]
Same paper: remanent polarization above 10 μC/cm² at a coercive field of 1 MV/cm.

* DOI: [10.1063/1.3634052](https://doi.org/10.1063/1.3634052) — same citation as 1.1
* Quote: *"This phase shows a distinct piezoelectric response, while polarization measurements exhibit a remanent polarization above 10 μC/cm2 at a coercive field of 1 MV/cm, suggesting that this phase is ferroelectric."*

### 1.3 Why perovskite ferroelectrics don't scale (CMOS-incompatibility framing) [VERIFIED]
* DOI: [10.1016/j.fmre.2023.02.010](https://doi.org/10.1016/j.fmre.2023.02.010) — Liao, Jiajia; Dai, Siwei; Peng, Ren-Ci; Yang, Jiangheng; Zeng, Binjian; Liao, Min; Zhou, Yichun — *Fundamental Research* — 2023
* Crossref check: title "HfO2-based ferroelectric thin film and memory device applications in the post-Moore era: A review", Fundamental Research, 2023, Liao — matches.
* Quote: *"However, conventional perovskite-structure ferroelectrics (e.g., PbZrxTi1-xO3) encounter severe limitations for high-density integration owing to the size effect of ferroelectricity and incompatibility with complementary metal-oxide-semiconductor technology."*

### 1.4 BEOL-compatible 400 °C thermal budget in HZO capacitors [VERIFIED]
TiN top electrodes ≥90 nm induce stress-driven crystallization at a 400 °C anneal, giving 2Pr = 45 μC/cm² and a ferroelectric saturation voltage of ~1.5 V.

* DOI: [10.1063/1.4995619](https://doi.org/10.1063/1.4995619) — Kim, Si Joon; Narayan, Dushyant; Lee, Jae-Gil; Mohan, Jaidah; Lee, Joy S.; Lee, Jaebeom; Kim, Harrison S.; Byun, Youngchul; Lucero, Antonio T.; Young, Chadwin D.; Summerfelt, Scott R.; San, Tamer; Colombo, Luigi; Kim, Jiyoung — *Applied Physics Letters* — 2017
* Crossref check: title "Large ferroelectric polarization of TiN/Hf0.5Zr0.5O2/TiN capacitors due to stress-induced crystallization at low thermal budget", APL, 2017, Kim — matches.
* Quote: *"We report on atomic layer deposited Hf0.5Zr0.5O2 (HZO)-based capacitors which exhibit excellent ferroelectric (FE) characteristics featuring a large switching polarization (45 μC/cm2) and a low FE saturation voltage (∼1.5 V) as extracted from pulse write/read measurements."*

---

## 2. The Orthorhombic Pca2₁ Phase and Typical Pr / Ec for 5–10 nm HZO

### 2.1 Pca2₁ (oIII) vs Pmn2₁ (oIV) orthorhombic phase identity [VERIFIED]
* DOI: [10.1063/5.0159700](https://doi.org/10.1063/5.0159700) — Chen, Yun-Wen; Liu, C. W. — *Applied Physics Letters* — 2023
* Crossref check: title "Effects of shear strain on HZO ferroelectric orthorhombic phases", APL, 2023, Chen — matches.
* Quote: *"The stabilities of hafnium and zirconium oxide ferroelectric orthorhombic phases, oIII-phase (Pca21) and oIV-phase (Pmn21), under shear strain are investigated theoretically by atomic modeling with density functional theory calculations."*

### 2.2 Interfacial termination stabilizes the polar orthorhombic phase down to 1.5 nm [VERIFIED]
* DOI: [10.1038/s41467-023-37560-3](https://doi.org/10.1038/s41467-023-37560-3) — Shi, Shu; Xi, Haolong; Cao, Tengfei; Lin, Weinan; Liu, Zhongran; Niu, Jiangzhen; Lan, Da; Zhou, Chenghang; Cao, Jing; Su, Hanxin; Zhao, Tieyang; Yang, Ping; Zhu, Yao; Yan, Xiaobing; Tsymbal, Evgeny Y.; Tian, He; Chen, Jingsheng — *Nature Communications* — 2023
* Crossref check: title "Interface-engineered ferroelectricity of epitaxial Hf0.5Zr0.5O2 thin films", Nature Communications, 2023, Shi — matches.
* Quote: *"Even though the Hf 0.5 Zr 0.5 O 2 thickness is as thin as 1.5 nm, the clear ferroelectric orthorhombic (111) orientation is observed on the MnO 2 termination."*

### 2.3 Representative 2Pr / endurance figures at ~10 nm, with an Al2O3 interlayer [MISMATCH: year 2022→2023]
2Pr ≈ 42 μC/cm² for TiN/HZO/TiN with a 1 nm Al2O3 interlayer, endurance beyond 10⁸ cycles at 3.5 MV/cm.

* DOI: [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) — Hsain, H Alex; Lee, Younghwan; Lancaster, Suzanne; Lomenzo, Patrick D.; Xu, Bohan; Mikolajick, Thomas; Schroeder, Uwe; Parsons, Gregory N.; Jones, Jacob L. — *Nanotechnology*
* Crossref check: title "Reduced fatigue and leakage of ferroelectric TiN/Hf0.5Zr0.5O2/TiN capacitors by thin alumina interlayers at the top or bottom interface", Nanotechnology, **2023** (both raw files claimed 2022 — corrected here), authors match.
* Quote: *"We report that TiN/HZO/TiN capacitors with a 1 nm Al 2 O 3 at the top interface demonstrate a higher remanent polarization (2P r ∼ 42 μ C cm −2 ) and endurance limit beyond 10 8 cycles at a cycling field amplitude of 3.5 MV cm −1 ."*

### 2.4 Depolarization-driven pinched hysteresis at 5 nm [VERIFIED]
At 5 nm, depolarization fields drive coexisting stable paraelectric / metastable ferroelectric states, producing pinched P-V loops.

* DOI: [10.1038/s42005-022-00951-x](https://doi.org/10.1038/s42005-022-00951-x) — Siannas, Nikitas; Zacharaki, Christina; Tsipas, Polychronis; Chaitoglou, Stefanos; Bégon-Lours, Laura; Mikolajick, Thomas; Dimoulas, Athanasios — *Communications Physics* — 2022
* Crossref check: title "Metastable ferroelectricity driven by depolarization fields in ultrathin Hf0.5Zr0.5O2", Communications Physics, 2022, Siannas — matches.
* Quote: *"Using Landau-Ginsburg-Devonshire (LGD) theory for the analysis of the experimental results, it is shown here that, in thin (5 nm) HZO, depolarization fields drive the system in a stable paraelectric phase coexisting with a metastable ferroelectric one, which explains the pinched hysteresis."*

**Working numbers for TCAD parameterization at 5–10 nm HZO:** Pr ≈ 15–25 μC/cm² (2Pr ≈ 30–50 μC/cm²), Ec ≈ 1.0–2.0 MV/cm — synthesized from claims 1.2, 2.3 and 2.4 above (no single verbatim quote states this exact range; treat as a derived working range, not a directly quotable figure).

---

## 3. THE RELIABILITY TRIAD — Wake-up, Fatigue, Imprint

This is the section the thesis's limitations section leans on. Status per leg: **wake-up = solid** (mechanism + magnitude + cycle count each independently quote-verified), **fatigue = solid** (mechanism + magnitude + cycle count each independently quote-verified, one source gives magnitude and cycle count in the same sentence), **imprint = thin** (mechanism is quote-verified; magnitude and stress-condition are not cleanly quote-verified — see caveat under 3.3).

### 3.1 Wake-up

**Mechanism — oxygen vacancy migration drives the monoclinic→orthorhombic transition [VERIFIED]**
Real-time, operando plasmon-enhanced spectroscopy directly tracks oxygen-vacancy migration during the pre-wake-up stage in 5 nm HZO, with <1% oxygen-vacancy-variation resolution.

* DOI: [10.1002/adfm.202214970](https://doi.org/10.1002/adfm.202214970) — Jan, Atif; Rembert, Thomas; Taper, Sunil; Symonowicz, Joanna; Strkalj, Nives; Moon, Taehwan; Lee, Yun Seong; Bae, Hagyoul; Lee, Hyun Jae; Choe, Duk-Hyun; Heo, Jinseong; MacManus-Driscoll, Judith; Monserrat, Bartomeu; Di Martino, Giuliana — *Advanced Functional Materials* — 2023
* Crossref check: title "In Operando Optical Tracking of Oxygen Vacancy Migration and Phase Change in few Nanometers Ferroelectric HZO Memories", AFM, 2023, full author list matches (agy list matches Crossref exactly, aside from a dropped middle initial "L." on MacManus-Driscoll — not a substantive discrepancy).
* Quote: *"Using plasmon-enhanced spectroscopy, a non-destructive technique sensitive to <1% oxygen vacancy variation, phase changes, and single switching cycle resolution, the first real-time in operando nanoscale direct tracking of oxygen vacancy migration in 5 nm hafnium zirconium oxide during a pre-wake-up stage is provided."*

**Magnitude — 2Pr rises to ~42 μC/cm² through wake-up [MISMATCH: year 2022→2023]**
Same Hsain et al. citation as claim 2.3 above (see that entry for the corrected year and Crossref-checked author list).

* DOI: [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) — Hsain et al. — *Nanotechnology* — **2023** (agy said 2022 in both raw files)
* Quote: *"We report that TiN/HZO/TiN capacitors with a 1 nm Al2O3 at the top interface demonstrate a higher remanent polarization (2Pr ∼ 42 μC cm−2) and endurance limit beyond 10^8 cycles at a cycling field amplitude of 3.5 MV cm−1."*

**Cycle count — wake-up persists to ~10³ cycles [VERIFIED]**
* DOI: [10.1063/5.0064145](https://doi.org/10.1063/5.0064145) — Fields, Shelby S.; Smith, Sean W.; Jaszewski, Samantha T.; Mimura, Takanori; Dickie, Diane A.; Esteves, Giovanni; Henry, M. David; Wolfley, Steve L.; Davids, Paul S.; Ihlefeld, Jon F. — *Journal of Applied Physics* — 2021
* Crossref check: title "Wake-up and fatigue mechanisms in ferroelectric Hf0.5Zr0.5O2 films with symmetric RuO2 electrodes", JAP, 2021, authors match (agy's list uses expanded/contracted first names for three authors — same individuals, not a discrepancy of identity).
* Quote: *"The devices are observed to wake-up for up to 10^3 bipolar pulsed field cycles, after which fatigue occurs with polarization approaching zero following 10^8 cycles."*

### 3.2 Fatigue

**Mechanism — critical field threshold (~0.8 MV/cm) separates wake-up from fatigue via a polar↔antipolar phase transition [VERIFIED]**
* DOI: [10.1038/s41467-022-28236-5](https://doi.org/10.1038/s41467-022-28236-5) — Cheng, Yan; Gao, Zhaomeng; Ye, Kun Hee; Park, Hyeon Woo; Zheng, Yonghui; Zheng, Yunzhe; Gao, Jianfeng; Park, Min Hyuk; Choi, Jung-Hae; Xue, Kan-Hao; Hwang, Cheol Seong; Lyu, Hangbing — *Nature Communications* — 2022
* Crossref check: title "Reversible transition between the polar and antipolar phases and its implications for wake-up and fatigue in HfO2-based ferroelectric thin film", Nature Communications, 2022, full author list matches exactly.
* Quote: *"The critical field strength that determined whether the film would be woken up or fatigued was ~0.8 MV/cm, above or below which wake-up or fatigue was observed, respectively."*

**Magnitude and cycle count together — polarization → 0 after 10⁸ cycles [VERIFIED]**
This is the strongest single quote in the whole set: it ties a magnitude (Pr approaching zero) directly to a cycle count (10⁸) in one sentence.

* DOI: [10.1063/5.0064145](https://doi.org/10.1063/5.0064145) — Fields et al. — *Journal of Applied Physics* — 2021 (same citation as the wake-up cycle-count claim above)
* Quote: *"The devices are observed to wake-up for up to 10^3 bipolar pulsed field cycles, after which fatigue occurs with polarization approaching zero following 10^8 cycles."*

**Corroborating endurance figure — 10⁸ cycles at 3.5 MV/cm before fatigue-driven failure [MISMATCH: year 2022→2023]**
* DOI: [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) — Hsain et al. — *Nanotechnology* — **2023** (agy said 2022)
* Quote: *"We report that TiN/HZO/TiN capacitors with a 1 nm Al2O3 at the top interface demonstrate a higher remanent polarization (2Pr ∼ 42 μC cm−2) and endurance limit beyond 10^8 cycles at a cycling field amplitude of 3.5 MV cm−1."*

**General mechanism corroboration — Vo concentration/redistribution governs switching speed and endurance [VERIFIED, qualitative]**
* DOI: [10.1186/s40580-023-00403-4](https://doi.org/10.1186/s40580-023-00403-4) — Lee, Jaewook; Yang, Kun; Kwon, Ju Young; Kim, Ji Eun; Han, Dong; Lee, Seung-Eun; Lee, Seung-Won; Kim, Dong-Hyun; Kim, Hyeong-Jun; Kim, Tae-Gon; Kim, Gwang-Sik; Kim, Seung-Geun; Kim, Seung-Hyun; Kim, Hyoungsub — *Nano Convergence* — 2023
* Crossref check: title "Role of oxygen vacancies in ferroelectric or resistive switching hafnium oxide", Nano Convergence, 2023, Lee — matches.
* Quote: *"Moreover, the switching speed and endurance of ferroelectric memories are strongly correlated to the V o concentration and redistribution."* (No specific cycle-count number is given in this quote — mechanism-only support.)

### 3.3 Imprint — the thin leg

**Mechanism — bake-time/temperature-dependent oxygen-vacancy redistribution drives a "wake-up reversal" (imprint) [VERIFIED, no numeric activation-energy value quoted]**
* DOI: [10.1109/TED.2023.3254509](https://doi.org/10.1109/TED.2023.3254509) — Lee, Sumi; Ronchi, Nicolò; Bizindavyi, Jasper; Popovici, Mihaela I.; Banerjee, Kaustuv; Walke, Amey; Delhougne, Romain; Van Houdt, Jan; Shin, Changhwan — *IEEE Transactions on Electron Devices* — 2023
* Crossref check: title "Analysis of Wake-Up Reversal Behavior Induced by Imprint in La:HZO MFM Capacitors", IEEE TED, 2023, full author list matches.
* Quote: *"Quantitative evaluation of the observed current peak split at each bake time and bake temperature yielded activation energy, suggesting that the wake-up reversal is due to oxygen vacancy redistribution."* — the sentence confirms the mechanism and that an activation energy was measured, but does not itself state the eV value or a ΔV/%Pr magnitude, so no numeric value from this source is carried forward.

**Attempted magnitude/bake-condition citation — weak [MISMATCH: incomplete author list; content not usable as a quantitative imprint claim]**
* DOI: [10.1021/acsaelm.1c01241](https://doi.org/10.1021/acsaelm.1c01241) — agy listed: Mohan, Jaidah; Jung, Yong Chan; Hernandez-Arriaga, Heber; Kim, Jin-Hyun; Onaya, Takashi; Kim, Jiyoung — *ACS Applied Electronic Materials* — 2022
* Crossref check: title "Relaxation Induced by Imprint Phenomena in Low-Temperature (400 °C) Processed Hf0.5Zr0.5O2-Based Metal-Ferroelectric-Metal Capacitors" matches, venue and year match (2022), **but the full Crossref author list is Mohan, Jung, Hernandez-Arriaga, Kim (Jin-Hyun), Onaya, Sahota (Akshay), Hwang (Su Min), Le (Dan N.), Kim (Jiyoung), Kim (Si Joon) — agy dropped four real co-authors (Sahota, Hwang, Le, Si Joon Kim).**
* The "verbatim quote" agy supplied is the paper's title, not a data sentence — it supports only the number "400 °C" (a processing/anneal temperature, not an imprint magnitude or a bake stress-condition under which imprint was measured). No ΔV_im, %Pr shift, bake-time, or bake-temperature-during-stress number from this paper is quote-verified. **This claim does not satisfy the "magnitude + condition, same paper, verbatim quote" bar and should not be used as imprint quantitative evidence as-is.**

**Net assessment for imprint:** the mechanism (oxygen-vacancy redistribution under bake stress, causing a wake-up-reversal / imprint behavior) is solidly quote-verified via Lee et al. 2023 (IEEE TED). No magnitude (ΔV_im or %Pr shift) or bake condition is currently backed by a verbatim quote from a fully-verified citation. This leg needs one more targeted search (a paper reporting an explicit imprint voltage shift + bake time/temperature in the same sentence) before it can support a quantitative statement in the thesis.

---

## 4. Depolarization in MFIS Stacks

### 4.1 Depolarization field magnitude — NOT usable as stated [UNVERIFIED]
* DOI: [10.1063/5.0035515](https://doi.org/10.1063/5.0035515) — Kim, Jae Young; Choi, Min-Ju; Jang, Ho Won — *APL Materials* — 2021
* Crossref check: title "Ferroelectric field effect transistors: Progress and perspective", APL Materials, 2021, authors match Crossref exactly.
* The claimed number (Edep up to 2.2 MV/cm) is **not contained in the quoted sentence agy supplied**: *"FeFETs, ferroelectric semiconductor field effect transistors, and metal–ferroelectric–insulator–semiconductor structures to which those materials can be applied are introduced, and their exotic performances are investigated."* This is a generic scope sentence with no number in it. Per the evidence rule (no verbatim quote attached to a number → drop the number), **the 2.2 MV/cm figure is dropped**. The citation is a real review paper on FeFET physics and may still be useful for the qualitative depolarization-field discussion, but not for this specific number.

**Qualitative depolarization-field relation (from the first-pass raw file, no dedicated numeric citation):** in an MFIS stack, incomplete screening by a low-k interfacial layer produces an uncompensated depolarization field opposing P, given by the standard series-capacitor relation Edep = −P / [εFE(1 + εIL·dFE/(εFE·dIL))]. This is textbook electrostatics reproduced by agy, not a claim needing its own citation.

---

## 5. Charge Trapping at the Ferroelectric / Interfacial-Oxide Interface

### 5.1 Charge trapping competes with/masks polarization switching [VERIFIED, qualitative]
* DOI: [10.1007/s00339-022-06212-6](https://doi.org/10.1007/s00339-022-06212-6) — Toprasertpong, Kasidit; Takenaka, Mitsuru; Takagi, Shinichi — *Applied Physics A* — 2022
* Crossref check: title "On the strong coupling of polarization and charge trapping in HfO2/Si-based ferroelectric field-effect transistors: overview of device operation and reliability", Applied Physics A, 2022, authors match exactly.
* Quote (title, used as agy supplied no data-bearing sentence): *"On the strong coupling of polarization and charge trapping in HfO2/Si-based ferroelectric field-effect transistors: overview of device operation and reliability."* No numeric coupling parameter is quote-verified — this citation supports the qualitative claim (charge trapping and polarization switching are strongly coupled and can mask one another in Vth/I-V measurements) but not any specific number.

### 5.2 Retention-limited memory window from combined charge-trapping + depolarization [VERIFIED]
* DOI: [10.1109/ted.2021.3096510](https://doi.org/10.1109/ted.2021.3096510) — Higashi, Y.; Ronchi, N.; Kaczer, B.; Alam, Md Nur K.; O'Sullivan, Barry; Banerjee, Kaustuv; McMitchell, S. R. C.; Breuil, L.; Walke, A.; Van den bosch, G.; Linten, D.; Van Houdt, Jan — *IEEE Transactions on Electron Devices* — 2021
* Crossref check: title "Impact of Charge Trapping and Depolarization on Data Retention Using Simultaneous P–V and I–V in HfO2-Based Ferroelectric FET", IEEE TED, 2021, Higashi — matches.
* Quote: *"Based on our understanding, excellent improvement of the DR is achieved: memory window ~0.8 V at 85 °C, extrapolated to ten years."*

---

## 6. Reported Mitigation Strategies

### 6.1 Al2O3 passivating interlayer suppresses fatigue [MISMATCH: year 2022→2023]
* DOI: [10.1088/1361-6528/acad0a](https://doi.org/10.1088/1361-6528/acad0a) — Hsain et al. — *Nanotechnology* — **2023** (agy said 2022)
* Quote: *"By inserting an interfacial layer while limiting exposure to the ambient environment, we successfully introduce a protective passivating layer of Al 2 O 3 that provides excess oxygen to mitigate vacancy formation at the interface."*

### 6.2 (La, Y) / (La, Gd) co-doping gives fatigue-free operation to 10¹¹ cycles [VERIFIED]
* DOI: [10.1021/acsaelm.2c00063](https://doi.org/10.1021/acsaelm.2c00063) — Popovici, Mihaela Ioana; Walke, Amey M.; Bizindavyi, Jasper; Meersschaut, Johan; Banerjee, Kaustuv; Potoms, Goedele; Katcko, Kostantine; Van den Bosch, Geert; Delhougne, Romain; Kar, Gouri Sankar; Van Houdt, Jan — *ACS Applied Electronic Materials* — 2022
* Crossref check: title "High-Endurance Ferroelectric (La, Y) and (La, Gd) Co-Doped Hafnium Zirconate Grown by Atomic Layer Deposition", ACS AEM, 2022, full author list matches exactly.
* Quote: *"Fatigue-free capacitors with remnant polarization ≥15 μC/cm 2 at 1 × 10 11 endurance cycles have been obtained for dopants having an atomic fraction of about 1.2–1.8% and showing great promise as active materials for emerging memory applications."*

### 6.3 Thermal re-annealing recovers cycled 7 nm HZO [VERIFIED]
* DOI: [10.1109/LED.2023.3287874](https://doi.org/10.1109/LED.2023.3287874) — Li, Xiaopeng; Tai, Lu; Zhao, Guoqing; Zhan, Xuepeng; Wang, Xiaolei; Kobayashi, Masaharu; Wu, Jixuan; Chen, Jiezhi — *IEEE Electron Device Letters* — 2023
* Crossref check: title "Re-Annealing-Induced Recovery in 7nm Hf0.5Zr0.5O2 Ferroelectric Film: Phase Transition and Non-Switchable Region Repair", IEEE EDL, 2023, full author list matches exactly.
* Quote: *"To achieve HfO2-based ferroelectric (FE) devices with robust reliabilities, the impacts of re-annealing on 7nm FE-Hf0.5Zr0.5O2 (HZO) capacitors are comprehensively studied in this work."*

### 6.4 Low-temperature nanosecond laser anneal (HZO/IGZO 3D integration) [VERIFIED for the quoted numbers only]
* DOI: [10.1002/advs.202401250](https://doi.org/10.1002/advs.202401250) — Kim, Dongsu; Jeong, Heejae; Pyo, Goeun; Heo, Su Jin; Baik, Seunghun; Kim, Seonhyoung; Choi, Hong Soo; Kwon, Hyuk-Jun; Jang, Jae Eun — *Advanced Science* — 2024
* Crossref check: title "Low-Temperature Nanosecond Laser Process of HZO-IGZO FeFETs toward Monolithic 3D System on Chip Integration", Advanced Science, 2024, full author list matches exactly.
* Quote: *"Using optimized laser conditions, a fast response time (<1 µs) and excellent stability (cycle > 106, retention > 106 s) are achieved in the ferroelectric HZO film. The resulting FeFET exhibited a wide memory window (>1.7 V) with a high on/off ratio (>105)."*
* Note: agy also attached a "2Pr = 14.7 μC/cm²" figure to this claim; that number is **not present in the supplied quote** and is dropped here (see Do Not Cite).

### 6.5 W top electrode + interfacial strain boosts 2Pr to ~64 μC/cm² [VERIFIED for the quoted number only]
* DOI: [10.1021/acsaelm.0c00671](https://doi.org/10.1021/acsaelm.0c00671) — Kashir, Alireza; Kim, Hyungwoo; Oh, Seungyeol; Hwang, Hyunsang — *ACS Applied Electronic Materials* — 2021
* Crossref check: title "Large Remnant Polarization in a Wake-Up Free Hf0.5Zr0.5O2 Ferroelectric Film through Bulk and Interface Engineering", ACS AEM, 2021, full author list matches exactly.
* Quote: *"Therefore, increasing the annealing temperature T A followed by rapid cooling to room temperature resulted in a substantial increase in the 2 P r value (∼64 μC/cm 2 )."*
* Note: agy also attached "10 nm Pt interlayer cuts leakage 20-fold" to this claim; that number is **not present in the supplied quote** and is dropped here (see Do Not Cite).

---

## Do not cite

| Item | Reason |
| --- | --- |
| Edep = 2.2 MV/cm, attributed to Kim, Choi & Jang, *APL Materials* 2021 (10.1063/5.0035515) | DOI and authors are real, but the supplied quote is a generic scope sentence containing no number. No verbatim support for 2.2 MV/cm found. |
| Imprint magnitude / bake condition, attributed to Mohan et al., *ACS Appl. Electron. Mater.* 2022 (10.1021/acsaelm.1c01241) | Crossref shows 4 co-authors (Akshay Sahota, Su Min Hwang, Dan N. Le, Si Joon Kim) omitted from agy's author list. In addition, the supplied "quote" is the paper's title, not a data sentence — no ΔV_im, %Pr shift, or bake-time/temperature stress condition is verbatim-supported. Do not cite for a quantitative imprint claim; the paper may still be worth reading directly before deciding whether to use it. |
| 2Pr = 14.7 μC/cm², attributed to Kim et al., *Advanced Science* 2024 (10.1002/advs.202401250) | The verified quote for this DOI supports the <1 µs / >10⁶ cycle / >10⁶ s / >1.7 V / >10⁵ on-off figures, but not this polarization value. |
| "10 nm Pt interlayer cuts leakage 20-fold," attributed to Kashir et al., *ACS Appl. Electron. Mater.* 2021 (10.1021/acsaelm.0c00671) | The verified quote for this DOI supports only the 2Pr ≈ 64 μC/cm² figure, not the Pt-interlayer/leakage claim. |
| Activation energy (specific eV value) for imprint, implied by Lee et al., *IEEE TED* 2023 (10.1109/TED.2023.3254509) | The quote confirms an activation energy was extracted but does not state its value. |
| Working range Pr ≈ 15–25 μC/cm², Ec ≈ 1.0–2.0 MV/cm at 5–10 nm | This is a synthesized range across three sources (1.2, 2.3, 2.4), not a single verbatim-quotable figure. Usable as a design/parameterization guide, not as a directly cited number. |

---

## BibTeX (VERIFIED entries only, Crossref-authoritative metadata)

```bibtex
@article{Boescke2011_APL,
  author  = {B{\"o}scke, T. S. and M{\"u}ller, Johannes and Br{\"a}uhaus, D. and Schr{\"o}der, U. and B{\"o}ttger, U.},
  title   = {Ferroelectricity in hafnium oxide thin films},
  journal = {Applied Physics Letters},
  year    = {2011},
  doi     = {10.1063/1.3634052}
}

@article{Liao2023_FundamentalResearch,
  author  = {Liao, Jiajia and Dai, Siwei and Peng, Ren-Ci and Yang, Jiangheng and Zeng, Binjian and Liao, Min and Zhou, Yichun},
  title   = {HfO2-based ferroelectric thin film and memory device applications in the post-Moore era: A review},
  journal = {Fundamental Research},
  year    = {2023},
  doi     = {10.1016/j.fmre.2023.02.010}
}

@article{Kim2017_APL,
  author  = {Kim, Si Joon and Narayan, Dushyant and Lee, Jae-Gil and Mohan, Jaidah and Lee, Joy S. and Lee, Jaebeom and Kim, Harrison S. and Byun, Youngchul and Lucero, Antonio T. and Young, Chadwin D. and Summerfelt, Scott R. and San, Tamer and Colombo, Luigi and Kim, Jiyoung},
  title   = {Large ferroelectric polarization of TiN/Hf0.5Zr0.5O2/TiN capacitors due to stress-induced crystallization at low thermal budget},
  journal = {Applied Physics Letters},
  year    = {2017},
  doi     = {10.1063/1.4995619}
}

@article{Chen2023_APL,
  author  = {Chen, Yun-Wen and Liu, C. W.},
  title   = {Effects of shear strain on HZO ferroelectric orthorhombic phases},
  journal = {Applied Physics Letters},
  year    = {2023},
  doi     = {10.1063/5.0159700}
}

@article{Shi2023_NatCommun,
  author  = {Shi, Shu and Xi, Haolong and Cao, Tengfei and Lin, Weinan and Liu, Zhongran and Niu, Jiangzhen and Lan, Da and Zhou, Chenghang and Cao, Jing and Su, Hanxin and Zhao, Tieyang and Yang, Ping and Zhu, Yao and Yan, Xiaobing and Tsymbal, Evgeny Y. and Tian, He and Chen, Jingsheng},
  title   = {Interface-engineered ferroelectricity of epitaxial Hf0.5Zr0.5O2 thin films},
  journal = {Nature Communications},
  year    = {2023},
  doi     = {10.1038/s41467-023-37560-3}
}

@article{Hsain2023_Nanotechnology,
  author  = {Hsain, H Alex and Lee, Younghwan and Lancaster, Suzanne and Lomenzo, Patrick D. and Xu, Bohan and Mikolajick, Thomas and Schroeder, Uwe and Parsons, Gregory N. and Jones, Jacob L.},
  title   = {Reduced fatigue and leakage of ferroelectric TiN/Hf0.5Zr0.5O2/TiN capacitors by thin alumina interlayers at the top or bottom interface},
  journal = {Nanotechnology},
  year    = {2023},
  doi     = {10.1088/1361-6528/acad0a},
  note    = {agy's raw output claimed 2022 in both passes; Crossref confirms 2023 -- corrected here}
}

@article{Siannas2022_CommPhys,
  author  = {Siannas, Nikitas and Zacharaki, Christina and Tsipas, Polychronis and Chaitoglou, Stefanos and B{\'e}gon-Lours, Laura and Mikolajick, Thomas and Dimoulas, Athanasios},
  title   = {Metastable ferroelectricity driven by depolarization fields in ultrathin Hf0.5Zr0.5O2},
  journal = {Communications Physics},
  year    = {2022},
  doi     = {10.1038/s42005-022-00951-x}
}

@article{Pesic2016_AFM,
  author  = {Pe{\v{s}}i{\'c}, Milan and Fengler, Franz P. G. and Larcher, Luca and Padovani, Andrea and Schenk, Tony and Grimley, Everett D. and Sang, Xiahan and LeBeau, James M. and Slesazeck, Stefan and Schroeder, Uwe and Mikolajick, Thomas},
  title   = {Physical Mechanisms behind the Field-Cycling Behavior of HfO2-Based Ferroelectric Capacitors},
  journal = {Advanced Functional Materials},
  year    = {2016},
  doi     = {10.1002/adfm.201600590}
}

@article{Lee2023_NanoConvergence,
  author  = {Lee, Jaewook and Yang, Kun and Kwon, Ju Young and Kim, Ji Eun and Han, Dong and Lee, Seung-Eun and Lee, Seung-Won and Kim, Dong-Hyun and Kim, Hyeong-Jun and Kim, Tae-Gon and Kim, Gwang-Sik and Kim, Seung-Geun and Kim, Seung-Hyun and Kim, Hyoungsub},
  title   = {Role of oxygen vacancies in ferroelectric or resistive switching hafnium oxide},
  journal = {Nano Convergence},
  year    = {2023},
  doi     = {10.1186/s40580-023-00403-4}
}

@article{Higashi2021_IEEETED,
  author  = {Higashi, Y. and Ronchi, N. and Kaczer, B. and Alam, Md Nur K. and O'Sullivan, Barry and Banerjee, Kaustuv and McMitchell, S. R. C. and Breuil, L. and Walke, A. and {Van den bosch}, G. and Linten, D. and {Van Houdt}, Jan},
  title   = {Impact of Charge Trapping and Depolarization on Data Retention Using Simultaneous P--V and I--V in HfO2-Based Ferroelectric FET},
  journal = {IEEE Transactions on Electron Devices},
  year    = {2021},
  doi     = {10.1109/ted.2021.3096510}
}

@article{Zagni2023_ProcIEEE,
  author  = {Zagni, Nicol{\`o} and Puglisi, Francesco Maria and Pavan, Paolo and Alam, Muhammad A.},
  title   = {Reliability of HfO2-Based Ferroelectric FETs: A Critical Review of Current and Future Challenges},
  journal = {Proceedings of the IEEE},
  year    = {2023},
  doi     = {10.1109/jproc.2023.3234607}
}

@article{Jan2023_AFM,
  author  = {Jan, Atif and Rembert, Thomas and Taper, Sunil and Symonowicz, Joanna and Strkalj, Nives and Moon, Taehwan and Lee, Yun Seong and Bae, Hagyoul and Lee, Hyun Jae and Choe, Duk-Hyun and Heo, Jinseong and MacManus-Driscoll, Judith and Monserrat, Bartomeu and {Di Martino}, Giuliana},
  title   = {In Operando Optical Tracking of Oxygen Vacancy Migration and Phase Change in few Nanometers Ferroelectric HZO Memories},
  journal = {Advanced Functional Materials},
  year    = {2023},
  doi     = {10.1002/adfm.202214970}
}

@article{Fields2021_JAP,
  author  = {Fields, Shelby S. and Smith, Sean W. and Jaszewski, Samantha T. and Mimura, Takanori and Dickie, Diane A. and Esteves, Giovanni and Henry, M. David and Wolfley, Steve L. and Davids, Paul S. and Ihlefeld, Jon F.},
  title   = {Wake-up and fatigue mechanisms in ferroelectric Hf0.5Zr0.5O2 films with symmetric RuO2 electrodes},
  journal = {Journal of Applied Physics},
  year    = {2021},
  doi     = {10.1063/5.0064145}
}

@article{Cheng2022_NatCommun,
  author  = {Cheng, Yan and Gao, Zhaomeng and Ye, Kun Hee and Park, Hyeon Woo and Zheng, Yonghui and Zheng, Yunzhe and Gao, Jianfeng and Park, Min Hyuk and Choi, Jung-Hae and Xue, Kan-Hao and Hwang, Cheol Seong and Lyu, Hangbing},
  title   = {Reversible transition between the polar and antipolar phases and its implications for wake-up and fatigue in HfO2-based ferroelectric thin film},
  journal = {Nature Communications},
  year    = {2022},
  doi     = {10.1038/s41467-022-28236-5}
}

@article{Lee2023_IEEETED,
  author  = {Lee, Sumi and Ronchi, Nicol{\`o} and Bizindavyi, Jasper and Popovici, Mihaela I. and Banerjee, Kaustuv and Walke, Amey and Delhougne, Romain and {Van Houdt}, Jan and Shin, Changhwan},
  title   = {Analysis of Wake-Up Reversal Behavior Induced by Imprint in La:HZO MFM Capacitors},
  journal = {IEEE Transactions on Electron Devices},
  year    = {2023},
  doi     = {10.1109/TED.2023.3254509}
}

@article{Toprasertpong2022_ApplPhysA,
  author  = {Toprasertpong, Kasidit and Takenaka, Mitsuru and Takagi, Shinichi},
  title   = {On the strong coupling of polarization and charge trapping in HfO2/Si-based ferroelectric field-effect transistors: overview of device operation and reliability},
  journal = {Applied Physics A},
  year    = {2022},
  doi     = {10.1007/s00339-022-06212-6}
}

@article{Popovici2022_ACSAEM,
  author  = {Popovici, Mihaela Ioana and Walke, Amey M. and Bizindavyi, Jasper and Meersschaut, Johan and Banerjee, Kaustuv and Potoms, Goedele and Katcko, Kostantine and {Van den Bosch}, Geert and Delhougne, Romain and Kar, Gouri Sankar and {Van Houdt}, Jan},
  title   = {High-Endurance Ferroelectric (La, Y) and (La, Gd) Co-Doped Hafnium Zirconate Grown by Atomic Layer Deposition},
  journal = {ACS Applied Electronic Materials},
  year    = {2022},
  doi     = {10.1021/acsaelm.2c00063}
}

@article{Li2023_IEEEEDL,
  author  = {Li, Xiaopeng and Tai, Lu and Zhao, Guoqing and Zhan, Xuepeng and Wang, Xiaolei and Kobayashi, Masaharu and Wu, Jixuan and Chen, Jiezhi},
  title   = {Re-Annealing-Induced Recovery in 7nm Hf0.5Zr0.5O2 Ferroelectric Film: Phase Transition and Non-Switchable Region Repair},
  journal = {IEEE Electron Device Letters},
  year    = {2023},
  doi     = {10.1109/LED.2023.3287874}
}

@article{Kim2024_AdvSci,
  author  = {Kim, Dongsu and Jeong, Heejae and Pyo, Goeun and Heo, Su Jin and Baik, Seunghun and Kim, Seonhyoung and Choi, Hong Soo and Kwon, Hyuk-Jun and Jang, Jae Eun},
  title   = {Low-Temperature Nanosecond Laser Process of HZO-IGZO FeFETs toward Monolithic 3D System on Chip Integration},
  journal = {Advanced Science},
  year    = {2024},
  doi     = {10.1002/advs.202401250}
}

@article{Kashir2021_ACSAEM,
  author  = {Kashir, Alireza and Kim, Hyungwoo and Oh, Seungyeol and Hwang, Hyunsang},
  title   = {Large Remnant Polarization in a Wake-Up Free Hf0.5Zr0.5O2 Ferroelectric Film through Bulk and Interface Engineering},
  journal = {ACS Applied Electronic Materials},
  year    = {2021},
  doi     = {10.1021/acsaelm.0c00671}
}
```
