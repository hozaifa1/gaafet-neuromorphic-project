# Full SNN parameter set — OPTIMIZED GAA-FeFET (drop-in for gaafefet\_params.py)

Every parameter the SNN code (`PYTHON\\\_Modelling\\\_Fefet\\\_Codes/`) reads, re-extracted
for the **optimized** device. Drop-in file: `gaafefet\\\_params\\\_optimized.py` (same
keys/structure — rename to `gaafefet\\\_params.py` to run the existing code unchanged).
Source for each value is the optimized-device characterization (mesh fe07).

## DEVICE

|key|prior (bad device)|**optimized**|source|
|-|-|-|-|
|Vth\_virgin (V)|0.263|**+0.018**|fine I-V, erased Vth @Icc=1e-2 µA/µm|
|Vth\_fire (V)|0.203|**−0.318**|fine I-V, programmed Vth|
|SS (V/dec)|60.8e-3|**62.3e-3**|fine I-V subthreshold (near-ideal, 5 nm body)|
|ID\_baseline (A)|9.525e-6|**7.0e-10**|erased read @ V\_G=0|
|ID\_fire (A)|1.938e-5|**2.14e-8**|after 9 pulses (LTP)|
|MW (V)|0.681|**0.336**|Vth\_virgin − Vth\_fire (T\_fe=7 nm)|
|AreaFactor|0.071|0.071|unchanged|

## OPERATING

|key|prior|**optimized**|
|-|-|-|
|VGS\_read (V)|0.20|**0.0** (electron channel; −0.5 V = GIDL)|
|Vpulse\_optimal (V)|6.0|**2.0**|
|Vreset (V)|−5.0|**−2.0**|
|pw (s)|100e-9|**0.3e-6** (gradual LTP; ≈0.3·tau\_E)|
|tau\_E (s)|1e-6|1e-6 (unchanged)|
|pw\_over\_tau\_E|0.1|0.3|

## LIF

|key|prior|**optimized**|note|
|-|-|-|-|
|N\_fire (pulses)|9|9|fire criterion kept at P9|
|fire\_ratio|2.035|**30.6**|ID(P9)/ID\_baseline — 15× better contrast|
|dVth\_per\_pulse (V)|−6.7e-3|**−18.3e-3**|−SS·0.294 dec/pulse (0.3 µs pulse)|
|leak\_drop\_ratio|0.20|**0.0**|NON-VOLATILE; no self-leak at V\_G=0|
|reset\_completeness (%)|77.2|\~100|clean erase (endurance drift = optional follow-up)|
|R\_on\_estimate (Ω)|2.58e3|**2.34e6**|VDS/ID\_fire|
|R\_off\_estimate (Ω)|5.25e3|**7.14e7**|VDS/ID\_baseline|

**Important (R re-scaling):** R values are \~10⁴× higher (optimized device draws far
less current → higher R, \~3140× full ON/OFF vs the prior 2×). The model's
`τ = C\\\_mem·(R\\\_h+R\\\_s)` and `gain = (R\\\_h+R\\\_s)·s` must be **re-tuned via C\_mem and
input\_scaling s**, exactly as the PDF §4 describes. For τ=11.11 ms keep:
`C\\\_mem = τ/(R\\\_off+R\\\_on) ≈ 11.11e-3 / 7.16e7 ≈ 155 pF`; pick `s` so
`(R\\\_off+R\\\_on)·s ≈ 77.5` → `s ≈ 1.08e-6`.

## POLARIZATION

|key|prior|**optimized**|note|
|-|-|-|-|
|P\_baseline (C/cm²)|−0.63e-6|+0.317e-6|sign = top-FE probe y-orientation|
|P\_fire (C/cm²)|+1.22e-6|−1.944e-6|(opposite sign convention to prior)|
|Delta\_P\_fire (C/cm²)|1.85e-6|−2.261e-6|\|ΔP\| ≈ 2.26 (comparable magnitude)|
|Ec\_estimate (V)|1.2|**0.98**|F\_c·T\_fe = 1.4 MV/cm · 7 nm|
|V\_HZO\_at\_Vpulse (V)|1.73 (@6 V)|**0.83** (@2 V)|\|E\|≈0.85 F\_c via probe|

## ENERGY / PENDING

|key|prior|**optimized**|
|-|-|-|
|tau\_leak|None|non-volatile (no decay/100 µs; leak = refresh/circuit)|
|E\_spike (J)|97e-15 (read est.)|**1.4e-17** (program/gate switching)|
|E\_per\_pulse (J)|None|**1.4e-17** (\~0.21 fJ for 15-pulse LTP)|

## CMOS adaptation peripheral (UNCHANGED — process-fixed, not the FeFET)

V\_dd=5 V, κ\_n,κ\_p=29,18 µA/V², V\_tn,V\_tp=0.745,0.973 V, W/L\_n,W/L\_p=16,8,
R\_a=100 kΩ, C\_a=5.56 µF. (These are the ALIF MOSFET adaptation circuit, independent
of the FeFET device — carry over verbatim.)

## Figures/data backing these values

`plots/transfer\\\_curves.png` (Vth/SS/MW), `plots/memwin\\\_fe07.png` (3140× window),
`plots/ltp\\\_potentiation.png` (15-level LTP), `plots/retention\\\_hold.png`,
`plots/ltp\\\_vs\\\_temperature.png`; raw CSVs in `csv\\\_export/raw/`.

