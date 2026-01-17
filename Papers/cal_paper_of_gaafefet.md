\title{
Stacked Nanosheet Gate-All-Around Transistor to Enable Scaling Beyond FinFET
}

\author{
N. Loubet ${ }^{1}$, T. Hook ${ }^{1}$, P. Montanini ${ }^{1}$, C.-W. Yeung ${ }^{1}$, S. Kanakasabapathy ${ }^{1}$, M. Guillorn ${ }^{1}$, T. Yamashita ${ }^{1}$, J. Zhang ${ }^{1}$, X. Miao ${ }^{1}$, J. Wang ${ }^{1}$, A. Young ${ }^{1}$, R. Chao ${ }^{1}$, M. Kang ${ }^{2}$, Z. Liu ${ }^{1}$, S. Fan ${ }^{1}$, B. Hamieh ${ }^{1}$, S. Sieg ${ }^{1}$, Y. Mignot ${ }^{1}$, W. Xu ${ }^{1}$, S.-C. Seo ${ }^{1}$, J. Yoo ${ }^{2}$, S. Mochizuki ${ }^{1}$, M. Sankarapandian ${ }^{1}$, O. Kwon ${ }^{2}$, A. Carr ${ }^{1}$, A. Greene ${ }^{1}$, Y. Park ${ }^{2}$, J. Frougier ${ }^{3}$, R. Galatage ${ }^{3}$, R. Bao ${ }^{1}$, J. Shearer ${ }^{1}$, R. Conti ${ }^{1}$, H. Song ${ }^{2}$, D. Lee ${ }^{2}$, D. Kong ${ }^{1}$, Y. Xu ${ }^{1}$, A. Arceo ${ }^{1}$, Z. Bi ${ }^{1}$, P. Xu ${ }^{1}$, R. Muthinti ${ }^{1}$, J. Li ${ }^{1}$, R. Wong ${ }^{1}$, D. Brown ${ }^{3}$, P. Oldiges ${ }^{1}$, R. Robison ${ }^{1}$, J. Arnold ${ }^{1}$, N. Felix ${ }^{1}$, S. Skordas ${ }^{1}$, J. Gaudiello ${ }^{1}$, T. Standaert ${ }^{1}$, H. Jagannathan ${ }^{1}$, D. Corliss ${ }^{1}$, M.-H. Na ${ }^{1}$, A. Knorr ${ }^{3}$, T. Wu ${ }^{1}$, D. Gupta ${ }^{1}$, S. Lian ${ }^{2}$, R. Divakaruni ${ }^{1}$, T. Gow ${ }^{1}$, C. Labelle ${ }^{3}$, S. Lee ${ }^{2}$, V. Paruchuri ${ }^{1}$, H. Bu ${ }^{1}$, and M. Khare ${ }^{1}$ \\ IBM Research, 257 Fuller Road, Albany, NY 12203 \\ ${ }^{1}$ IBM, ${ }^{2}$ Samsung Electronics, ${ }^{3}$ GLOBALFOUNDRIES, email: njloubet@us.ibm.com
}

\begin{abstract}
In this paper, for the first time we demonstrate that horizontally stacked gate-all-around (GAA) Nanosheet structure is a good candidate for the replacement of FinFET at the 5 nm technology node and beyond. It offers increased $\mathrm{W}_{\text {eff }}$ per active footprint and better performance compared to FinFET, and with a less complex patterning strategy, leveraging EUV lithography. Good electrostatics are reported at $\mathrm{L}_{\mathrm{g}}=12 \mathrm{~nm}$ and aggressive 44/48nm CPP (Contacted Poly Pitch) ground rules. We demonstrate work function metal (WFM) replacement and multiple threshold voltages, compatible with aggressive sheet to sheet spacing for wide stacked sheets. Stiction of sheets in long-channel devices is eliminated. Dielectric isolation is shown on standard bulk substrate for sub-sheet leakage control. Wrap-around contact (WAC) is evaluated for extrinsic resistance reduction. Keywords: VLSI, Gate-All-Around, Nanosheet, FinFET.
\end{abstract}

\section*{Introduction}

Horizontally stacked GAA Nanowire/Nanosheet structures can answer logic device needs at 5 nm technology nodes and beyond. They offer excellent electrostatics and short channel control [1-4], can be fabricated with minimal deviation from FinFET, and circumvent some of the patterning challenges associated with scaled technologies. In the following, we will show the versatility of this technology in term of design, and the significant boost in performance with a better $\mathrm{W}_{\text {eff }} / \mathrm{C}_{\text {eff }}$ trade off and electrostatics than FinFET for the same footprint. CMOS integration and DC performance of stacked GAA Nanosheets in sub7 nm ground rules will be presented. We will show $\mathrm{nFET} / \mathrm{pFET}$ devices at aggressive 12 nm gate length with good electrostatics, featuring inner spacer and extremely thin silicon channel. Multiple threshold voltage by WFM patterning, dielectric isolation and WAC are evaluated.

\section*{Stacked Nanosheet Device Design for sub- 7 nm}

Figure 1 illustrates area scaling by technology node [5-8]. GAA Nanosheet devices are evaluated at the 7 nm ground rule [9] as a replacement of FinFET device architecture to enable further scaling down to the 5 nm and 3 nm nodes. The scaling benefits of using double and single stack Nanosheet structures is illustrated in Fig. 2. With a relaxed pitch, it is possible to match the effective width ( $\mathrm{W}_{\text {eff }}$ ) of aggressively scaled FinFETs and even get a $30 \%$ increase in $\mathrm{W}_{\text {eff }}$ when wide Nanosheets are used. The maximum gain in $\mathrm{W}_{\text {eff }}$ is obtained for the same footprint with a Nanosheet single stack. As shown in Fig. 3, extremely scaled FinFETs fall on the same curve as two stacks of Nanosheet structures with three sheets, as both are limited by the space between the active regions. A better paradigm is a single wide Nanosheet stack as the structure is defined across the entire active footprint, provided that wide sheets can be successfully fabricated as we show here. In our simulations and experiments, we consider stacked Nanosheets with three layers of 5 nm sheet thickness and 10 nm vertical sheet to sheet spacing. Some examples of optimized inverter and SRAM layouts using single stack Nanosheet structures with sheet widths from 15 nm to 45 nm are in Fig. 4, showing the opportunities for power/performance tuning in a given cell design, and cell height reduction using an optimized single Nanosheet stack. In term of AC performance, the relative speed of FinFET, stacked Nanowire and stacked Nanosheet are compared in Figs. 5 and 6. It is shown that single stack Nanosheet has superior intrinsic performance for any sheet width compared to FinFET or stacked Nanowires. This is due to reduced parasitic capacitance for a given active width, resulting a better $\mathrm{C}_{\text {eff-to- }} \mathrm{I}_{\text {eff }}$ relationship. Nanosheets also have more effective width in a given footprint, and therefore superior capability in driving a capacitive load. Additionally, the continuously variable sheet width, enabled by EUV single exposure, provides for fine-tuning of the necessary width to optimize power/performance on a product design. In contrast, FinFET and stacked Nanowire offer only crude granularity of one or two fins/stacks. Another specific feature of stacked Nanosheet devices is the inner spacer that functions as the effective device spacer for self-aligned junction formation [10]. This module is described in Fig. 7, and shows
optimization of the inner spacer thickness at 5 nm with no degradation of the $\mathrm{I}_{\text {eff }} / \mathrm{C}_{\text {eff }}$ electrical performance.

\section*{44/48nm CPP Device Fabrication \& Characteristics}

With respect to the process flow, it has only a few divergences compared to FinFET technologies. A simplified flow is reported in Fig. 8 with selected cross section TEM from critical steps. The specific elements compared to FinFET are: 1) multilayer channel epitaxy to form stacked sheets, 2) inner spacer formation 3) channel release and 4) multi-threshold voltage processing. Stacked Nanosheet channel release is performed after dummy gate removal in the standard replacement gate integration, using vapor phase HCl [11]. Regarding the multilayer channel epitaxy, we verified that all Si and SiGe layers were pseudomorphic with respect to Si and defect-free (Fig. 9), thanks to optimized surface preparation and epitaxy. In addition, a low thermal budget ( $<900^{\circ} \mathrm{C}$ ) was employed for shallow trench isolation (STI) formation, limiting Ge diffusion during the fabrication steps (Fig. 10). $\mathrm{Id} / \mathrm{Vg}$ characteristics for three-sheet nFET and pFET devices reported in Fig. 11a show good electrostatics for an aggressive $\mathrm{L}_{\mathrm{g}}=12 \mathrm{~nm}$ at $44 / 48 \mathrm{~nm}$ CPP with ultra-thin 5 nm Si channel. The best electrostatics at 44 nm CPP for nFET are SSat $=75 \mathrm{mV} / \mathrm{dec}$. with $\mathrm{DIBL}=32 \mathrm{mV}$, and for pFET SSat $=85 \mathrm{mV} / \mathrm{dec}$. with DIBL $=24 \mathrm{mV}$. A TEM micrograph of the final structure is in Fig. 11b, showing good uniformity in $\mathrm{L}_{\text {gate }}$, inner spacer thickness, and epitaxy formation throughout the stack.

\section*{Multi-Vt, Long Channel \& Performance Improvement}

The deformation or bending of the sheets can be of great concern especially for long channel when the sheets are suspended across long distances after channel release. Stiction between Nanosheets can be suppressed with optimized interface layer (IL) dielectric formation; devices with $\mathrm{Lg}=150 \mathrm{~nm}$ show no observable bending or stiction in the TEM cross-section (Fig. 12). As shown in Fig. 13, replacement of Pmetal with N-metal for multiple threshold voltages is also possible, even for structures of width in excess of 40 nm ; there are no residues or damage visible after P-metal replacement when optimized $\mathrm{H}_{2} \mathrm{O}_{2}$-based chemistry is employed; this was electrically verified by comparing the threshold voltage of devices with and without the removal process. Figure 14 reports nFET Vt modulation with respect to N-metal WFM thickness, showing a sensitivity in the range $13-14 \mathrm{mV} / \AA$, suitable for multi-Vt solutions. The benefits of dielectric isolation are particularly important for Nanosheets on bulk substrates, as shown in Fig. 15. An additional $8 \%$ performance improvement is also expected using conformal silicide in a wrap-around contact configuration as described in Fig. 16 [12, results from IBM/Applied Materials].

\section*{Conclusion}

For the first time, we fabricated and characterized horizontally stacked Nanosheet devices with $\mathrm{L}_{\mathrm{g}}=12 \mathrm{~nm}$ and aggressive 44/48nm CPP. We showed that stacked Nanosheet offers versatile design options for performance and power management thanks to the benefits of large $\mathrm{W}_{\text {eff }}$. It has superior electrostatics and dynamic performance compared to extremely scaled FinFETs with multiple threshold and isolation solutions inherited from FinFET technologies. All these advantages make stacked Nanosheet devices an attractive solution as a replacement of FinFETs, scalable to the 5 nm device node and beyond, and with less complexity in the patterning strategy.
Acknowledgements: This work was performed by the Research Alliance teams at various IBM Research and Development Facilities. We want to thank for their executive support: T.C. Chen, D.W. Kim, M. Rodder, and G. Gomba.

References: [1] S. Bangsaruntip et al, IEDM, p.1-4, 2009 [2] I. Lauer et al., VLSI, p.140-141, 2015 [3] S.D. Kim et al., S3S Conference, p. 1-3, 2015 [4] H. Mertens et al., IEDM, p.19-7, 2016 [5] C. Auth, et al, VLSI, p.131-133, 2012 [6] S. Wu, et. al., IEDM, p. 254-257, 2013 [7] "Intel 14 nm Technology", Intel.com, 2014 [8] K. Seo et al., VLSI, p.14-15, 2014 [9] R. Xie et al., IEDM, p. 2-7, 2016 [10] S. Barraud et al., IEDM, p.17-6, 2016 [11] N. Loubet et al., Thin Solid Films, 517(1), p.93-97 [12] N. Breil, A.Carr et al., accepted VLSI 2017.

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=391&width=573&top_left_y=182&top_left_x=117}
\captionsetup{labelformat=empty}
\caption{Fig. 1: GAA Nanosheet structures can be a replacement of existing FinFET in sub $7-\mathrm{nm}$ ground rule.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=304&width=623&top_left_y=191&top_left_x=696}
\captionsetup{labelformat=empty}
\caption{Fig. 2: Increase in $\mathrm{W}_{\text {eff }}$ going from aggressively scaled FinFET to double and single stack Nanosheets structures. Best improvement is obtained using a single wide Nanosheet stack at constant active width (RX.W).}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=395&width=573&top_left_y=182&top_left_x=1352}
\captionsetup{labelformat=empty}
\caption{Fig. 3: Improvement in $\mathrm{W}_{\text {eff }}$ at same footprint going from extremely scaled FinFET to a single wide stack Nanosheet.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=378&width=386&top_left_y=687&top_left_x=117}
\captionsetup{labelformat=empty}
\caption{Fig. 4: For a given cell height, the Nanosheet (RX) width can be varied to optimize powerperformance trade-offs in logic (a-c) and SRAM (d).}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=382&width=514&top_left_y=687&top_left_x=509}
\captionsetup{labelformat=empty}
\caption{Fig. 5: Relative Frequency for several device options: FinFET, Nanosheet 5 nm (Nanowire), and various widths single stack Nanosheets. Inset: $\mathrm{C}_{\text {eff }}$ and $\mathrm{I}_{\text {eff }}$ for the same devices.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=377&width=425&top_left_y=692&top_left_x=1053}
\captionsetup{labelformat=empty}
\caption{Fig. 6: Inverter driving a capacitive load. Performance of a single wide Nanosheet stack is superior. Note: improved granularity for power optimization.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=290&width=387&top_left_y=2233&top_left_x=132}
\captionsetup{labelformat=empty}
\caption{Fig. 14: nFET long channel Vt modulation with N-metal}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=508&width=887&top_left_y=1236&top_left_x=117}
\captionsetup{labelformat=empty}
\caption{Fig. 8: Stacked Nanosheet Process Sequence \& TEM gallery.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=382&width=882&top_left_y=1789&top_left_x=124}
\captionsetup{labelformat=empty}
\caption{Fig. 11: Stacked Nanosheet $44 / 48 \mathrm{~nm}$ CPP $\mathrm{nFET} / \mathrm{pFET}$ devices $\mathrm{I}_{\mathrm{D}} / \mathrm{V}_{\mathrm{G}}-$ Structures feature 3 sheets, inner spacer, $\mathrm{L}_{\mathrm{g}}=12 \mathrm{~nm}$, and $\mathrm{T}_{\mathrm{Si}}=5 \mathrm{~nm}$}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=290&width=469&top_left_y=1236&top_left_x=1027}
\captionsetup{labelformat=empty}
\caption{Fig. 9: XRD RSM [113] scan (a), Precession Electron Diffraction (b), and EELS (c) confirm a defect-free pseudomorphic stack}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=469&width=347&top_left_y=1667&top_left_x=1014}
\captionsetup{labelformat=empty}
\caption{Fig.12: Stiction between Nanosheets is suppressed with optimized IL formation}
\end{figure}
![](https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=258&width=433&top_left_y=2248&top_left_x=567)

Fig. 15: Sub-sheet leakage suppression when a dielectric is inserted under the source/drain, comparable to fully isolated.

\begin{figure}
\captionsetup{labelformat=empty}
\caption{inserted under the source/drain, comparable to fully isolated.}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=290&width=342&top_left_y=2237&top_left_x=977}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=406&width=560&top_left_y=1667&top_left_x=1384}
\captionsetup{labelformat=empty}
\caption{Fig.13: P-metal can be fully removed in wide Nanosheet structures using $\mathrm{H}_{2} \mathrm{O}_{2}$-based chemistry with no impact on the structure and gate stack properties}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=282&width=580&top_left_y=2204&top_left_x=1362}
\captionsetup{labelformat=empty}
\caption{Fig. 16: Wrap-Around Contact scheme for Nanosheet - 8\% performance improvement is expected with this technique.
Fig. 16: Wrap-Around Contact scheme for
Nanosheet $-8 \%$ performance improvement is expected with this technique.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=362&width=435&top_left_y=692&top_left_x=1514}
\captionsetup{labelformat=empty}
\caption{Fig. 7: Normalized Ieff \& Ceff Inner spacer formation is required for integrity of the epitaxy.}
\end{figure}

\begin{figure}
\includegraphics[max width=\textwidth]{https://cdn.mathpix.com/cropped/8932271e-de69-48bf-861c-b1bdc73188f6-2.jpg?height=364&width=439&top_left_y=1162&top_left_x=1514}
\captionsetup{labelformat=empty}
\caption{Fig. 10: Ge concentration profiles after different STI anneal temperatures. A small diffusion of Ge is observed at $\mathrm{T}<900^{\circ} \mathrm{C}$}
\end{figure}