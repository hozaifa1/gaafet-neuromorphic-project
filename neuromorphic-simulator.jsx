import { useState, useEffect, useRef, useCallback } from "react";

const PHASES = [
  {
    id: "resting",
    label: "RESTING",
    color: "#00e5ff",
    desc: "No input. HZO polarization fully UP (P↑). Vth at maximum. Channel depleted. Neuron silent.",
    vth: 1.0,
    ids: 0.02,
    pol: 0.05,
  },
  {
    id: "integrate1",
    label: "INTEGRATING (Pulse 1)",
    color: "#b2ff59",
    desc: "Sub-coercive pulse arrives. Partial domain flip in HZO. Vth drops slightly. I_DS rises — membrane potential building.",
    vth: 0.75,
    ids: 0.22,
    pol: 0.3,
  },
  {
    id: "integrate2",
    label: "INTEGRATING (Pulse 2)",
    color: "#ffeb3b",
    desc: "Second pulse. More domains switch. ΔP accumulates further. Vth continues to fall. Neuron closer to threshold.",
    vth: 0.5,
    ids: 0.45,
    pol: 0.58,
  },
  {
    id: "leak",
    label: "LEAKING",
    color: "#ff9800",
    desc: "No pulse arrives. HZO relaxes thermally. Partial domains flip back. Vth rises. I_DS drops — membrane potential decaying.",
    vth: 0.65,
    ids: 0.3,
    pol: 0.4,
  },
  {
    id: "integrate3",
    label: "INTEGRATING (Pulse 3)",
    color: "#ff5722",
    desc: "Pulses resume. Polarization accumulates past coercive field threshold. Avalanche domain switching imminent.",
    vth: 0.22,
    ids: 0.72,
    pol: 0.85,
  },
  {
    id: "fire",
    label: "FIRING! ⚡",
    color: "#ff1744",
    desc: "THRESHOLD CROSSED! Full domain avalanche in HZO. Vth collapses. I_DS spikes — OUTPUT ACTION POTENTIAL generated!",
    vth: 0.02,
    ids: 1.0,
    pol: 1.0,
  },
  {
    id: "refractory",
    label: "REFRACTORY / RESET",
    color: "#7c4dff",
    desc: "Negative reset pulse applied. HZO repolarized to P↑. Vth restored. Neuron enters absolute refractory period. Ready to integrate again.",
    vth: 1.0,
    ids: 0.02,
    pol: 0.05,
  },
];

const W = 900;
const H = 480;

function lerp(a, b, t) {
  return a + (b - a) * t;
}

// ── Waveform history ──────────────────────────────────────────────────────────
const MAX_HIST = 120;

function useWaveform(value, max = 1) {
  const hist = useRef(Array(MAX_HIST).fill(0));
  useEffect(() => {
    hist.current = [...hist.current.slice(1), value / max];
  }, [value, max]);
  return hist.current;
}

// ── SVG Waveform ──────────────────────────────────────────────────────────────
function Waveform({ data, color, label, unit, currentVal, width = 260, height = 70 }) {
  const pts = data
    .map((v, i) => `${(i / (MAX_HIST - 1)) * width},${height - 4 - v * (height - 8)}`)
    .join(" ");
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 2 }}>
        <span style={{ fontSize: 10, color: "#aaa", fontFamily: "monospace", letterSpacing: 1 }}>{label}</span>
        <span style={{ fontSize: 11, color, fontFamily: "monospace", fontWeight: 700 }}>
          {currentVal}
        </span>
      </div>
      <svg width={width} height={height} style={{ display: "block", background: "#0a0a0f", borderRadius: 4, border: "1px solid #1a1a2e" }}>
        <polyline points={pts} fill="none" stroke={color} strokeWidth={1.5} strokeLinejoin="round" />
        <line x1={0} y1={height - 4} x2={width} y2={height - 4} stroke="#222" strokeWidth={1} />
      </svg>
    </div>
  );
}

// ── GAA Cross-section SVG ─────────────────────────────────────────────────────
function GAASection({ pol, phase }) {
  const firing = phase.id === "fire";
  const leaking = phase.id === "leak";
  const cx = 80, cy = 80, r = 42;
  const domainCount = 12;
  const polFrac = pol;

  return (
    <svg width={160} height={160} viewBox="0 0 160 160">
      {/* Gate metal ring */}
      <circle cx={cx} cy={cy} r={r + 18} fill="#1a1a2e" stroke="#4fc3f7" strokeWidth={2} />
      <text x={cx} y={cy - r - 10} textAnchor="middle" fill="#4fc3f7" fontSize={8} fontFamily="monospace">GATE (TiN)</text>

      {/* HZO ring */}
      <circle cx={cx} cy={cy} r={r + 10} fill="none" stroke={firing ? "#ff1744" : leaking ? "#ff9800" : "#7c4dff"} strokeWidth={8} opacity={0.7} />
      <text x={cx + r + 14} y={cy + 4} fill={firing ? "#ff1744" : "#b39ddb"} fontSize={7} fontFamily="monospace">HZO</text>

      {/* IL ring */}
      <circle cx={cx} cy={cy} r={r + 2} fill="none" stroke="#90caf9" strokeWidth={3} opacity={0.5} />

      {/* Channel */}
      <circle cx={cx} cy={cy} r={r} fill={firing ? "#ff572255" : "#0d47a1"} />
      <text x={cx} y={cy + 4} textAnchor="middle" fill="#fff" fontSize={9} fontFamily="monospace" fontWeight={700}>Si Ch</text>

      {/* Domain arrows */}
      {Array.from({ length: domainCount }).map((_, i) => {
        const angle = (i / domainCount) * Math.PI * 2;
        const rx = cx + (r + 6) * Math.cos(angle);
        const ry = cy + (r + 6) * Math.sin(angle);
        const flipped = i < Math.round(polFrac * domainCount);
        const arrowColor = flipped ? (firing ? "#ff1744" : "#b2ff59") : "#4fc3f7";
        const dy = flipped ? -5 : 5;
        return (
          <g key={i}>
            <circle cx={rx} cy={ry} r={4} fill={arrowColor} opacity={0.85} />
            <line
              x1={rx}
              y1={ry + (flipped ? 3 : -3)}
              x2={rx}
              y2={ry - (flipped ? 3 : -3)}
              stroke="#000"
              strokeWidth={1.2}
              markerEnd="url(#arr)"
            />
          </g>
        );
      })}

      {firing && (
        <>
          <circle cx={cx} cy={cy} r={r + 24} fill="none" stroke="#ff1744" strokeWidth={2} opacity={0.4}>
            <animate attributeName="r" values={`${r + 18};${r + 34};${r + 18}`} dur="0.6s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.5;0;0.5" dur="0.6s" repeatCount="indefinite" />
          </circle>
          <text x={cx} y={cy + r + 30} textAnchor="middle" fill="#ff1744" fontSize={10} fontFamily="monospace" fontWeight={700}>⚡ SPIKE!</text>
        </>
      )}

      <defs>
        <marker id="arr" markerWidth={4} markerHeight={4} refX={2} refY={2} orient="auto">
          <path d="M0,0 L4,2 L0,4 Z" fill="#000" />
        </marker>
      </defs>
    </svg>
  );
}

// ── Main circuit SVG ──────────────────────────────────────────────────────────
function CircuitDiagram({ phase, animT }) {
  const firing = phase.id === "fire";
  const leaking = phase.id === "leak";
  const integrating = phase.id.startsWith("integrate");
  const resting = phase.id === "resting";
  const refractory = phase.id === "refractory";

  const wireColor = (active) => active ? phase.color : "#2a2a4a";
  const glowFilter = firing ? "url(#glow)" : "none";

  // Current flow animation offset
  const dashOffset = firing ? animT * -30 : integrating ? animT * -15 : 0;

  return (
    <svg width="100%" viewBox="0 0 520 340" style={{ fontFamily: "monospace" }}>
      <defs>
        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <filter id="softglow">
          <feGaussianBlur stdDeviation="1.5" result="blur" />
          <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
        </filter>
        <marker id="arrowB" markerWidth={6} markerHeight={6} refX={3} refY={3} orient="auto">
          <path d="M0,0 L6,3 L0,6 Z" fill={phase.color} />
        </marker>
        <marker id="arrowW" markerWidth={6} markerHeight={6} refX={3} refY={3} orient="auto">
          <path d="M0,0 L6,3 L0,6 Z" fill="#4fc3f7" />
        </marker>
      </defs>

      {/* Background grid */}
      <rect width={520} height={340} fill="#050510" rx={8} />
      {Array.from({ length: 26 }).map((_, i) => (
        <line key={`v${i}`} x1={i * 20} y1={0} x2={i * 20} y2={340} stroke="#0d0d20" strokeWidth={1} />
      ))}
      {Array.from({ length: 17 }).map((_, i) => (
        <line key={`h${i}`} x1={0} y1={i * 20} x2={520} y2={i * 20} stroke="#0d0d20" strokeWidth={1} />
      ))}

      {/* ── VDD Rail ── */}
      <line x1={260} y1={10} x2={260} y2={30} stroke="#ff5252" strokeWidth={2} />
      <text x={270} y={22} fill="#ff5252" fontSize={10} fontWeight={700}>VDD</text>
      <line x1={220} y1={30} x2={300} y2={30} stroke="#ff5252" strokeWidth={2} />

      {/* ── R_load ── */}
      <rect x={245} y={30} width={30} height={50} rx={3} fill="#1a1a3a" stroke="#4fc3f7" strokeWidth={1.5} />
      <text x={260} y={50} textAnchor="middle" fill="#4fc3f7" fontSize={8}>R</text>
      <text x={260} y={62} textAnchor="middle" fill="#4fc3f7" fontSize={7}>LOAD</text>
      <line x1={260} y1={80} x2={260} y2={100} stroke={wireColor(firing || integrating)} strokeWidth={2} />

      {/* ── DRAIN node ── */}
      <circle cx={260} cy={100} r={4} fill={wireColor(firing || integrating)} />
      <text x={275} y={104} fill="#aaa" fontSize={8}>DRAIN</text>
      {/* Drain → Output spike line */}
      <line x1={260} y1={100} x2={360} y2={100}
        stroke={wireColor(firing)}
        strokeWidth={firing ? 2.5 : 1.5}
        strokeDasharray={firing ? "6,3" : "none"}
        strokeDashoffset={dashOffset}
        markerEnd={firing ? "url(#arrowB)" : ""}
        filter={firing ? glowFilter : ""}
      />
      <text x={370} y={97} fill={firing ? phase.color : "#555"} fontSize={8}>SPIKE OUT</text>
      <rect x={368} y={101} width={60} height={20} rx={3}
        fill={firing ? "#1a0005" : "#0a0a14"}
        stroke={firing ? "#ff1744" : "#222"}
        strokeWidth={1} />
      <text x={398} y={114} textAnchor="middle" fill={firing ? "#ff1744" : "#444"} fontSize={8}>
        {firing ? "HIGH" : "LOW"}
      </text>

      {/* ── GAA FeFET Body ── */}
      {/* Source line */}
      <line x1={260} y1={100} x2={260} y2={115} stroke={wireColor(firing || integrating)} strokeWidth={2} />

      {/* FeFET box */}
      <rect x={200} y={115} width={120} height={110} rx={6}
        fill="#080818"
        stroke={phase.color}
        strokeWidth={firing ? 2.5 : 1.5}
        filter={firing ? glowFilter : ""}
      />
      <text x={260} y={132} textAnchor="middle" fill={phase.color} fontSize={9} fontWeight={700}>GAA FeFET</text>

      {/* Nanosheet channel inside box */}
      <rect x={230} y={140} width={60} height={30} rx={12} fill="#0d1b4a" stroke="#1565c0" strokeWidth={1.5} />
      <text x={260} y={158} textAnchor="middle" fill="#90caf9" fontSize={7}>NANOSHEET Ch</text>

      {/* HZO layer around nanosheet */}
      <rect x={222} y={136} width={76} height={38} rx={14} fill="none"
        stroke={leaking ? "#ff9800" : firing ? "#ff1744" : "#7c4dff"}
        strokeWidth={3}
        strokeDasharray={leaking ? "4,2" : "none"}
        opacity={0.8}
      />
      <text x={303} y={147} fill="#b39ddb" fontSize={6.5}>HZO</text>

      {/* Gate metal */}
      <rect x={214} y={130} width={92} height={52} rx={16} fill="none" stroke="#4fc3f7" strokeWidth={1} strokeDasharray="3,2" opacity={0.5} />
      <text x={310} y={160} fill="#4fc3f7" fontSize={6.5}>TiN Gate</text>

      {/* Polarization indicator */}
      <text x={260} y={182} textAnchor="middle" fill={leaking ? "#ff9800" : phase.color} fontSize={7}>
        P: {leaking ? "↓ relaxing" : firing ? "↑ FULL SWITCH" : `↑ ${Math.round(PHASES.find(p => p.id === phase.id)?.pol * 100)}%`}
      </text>

      {/* S/D labels */}
      <text x={205} y={126} fill="#4fc3f7" fontSize={7}>D</text>
      <text x={205} y={232} fill="#4fc3f7" fontSize={7}>S</text>

      {/* ── Gate input line ── */}
      <line x1={214} y1={155} x2={130} y2={155}
        stroke={wireColor(integrating || refractory)}
        strokeWidth={1.5}
        strokeDasharray={integrating ? "5,3" : "none"}
        strokeDashoffset={dashOffset}
        markerEnd={integrating ? "url(#arrowB)" : ""}
      />
      <text x={70} y={150} fill="#aaa" fontSize={7.5}>VIN PULSES</text>

      {/* Input pulse source */}
      <rect x={28} y={140} width={50} height={30} rx={4} fill="#0a1520" stroke={wireColor(integrating)} strokeWidth={1.5} />
      <text x={53} y={153} textAnchor="middle" fill={integrating ? phase.color : "#556"} fontSize={7}>SYN</text>
      <text x={53} y={163} textAnchor="middle" fill={integrating ? phase.color : "#556"} fontSize={7}>INPUT</text>

      {/* Sub-coercive pulse label */}
      {integrating && (
        <text x={130} y={167} fill={phase.color} fontSize={6.5}>sub-coercive Vg</text>
      )}

      {/* Reset pulse path */}
      <line x1={214} y1={155} x2={130} y2={155} stroke="#4fc3f7" strokeWidth={0.5} opacity={0.2} />
      {refractory && (
        <>
          <line x1={130} y1={155} x2={90} y2={155} stroke="#7c4dff" strokeWidth={2} markerEnd="url(#arrowB)" />
          <text x={55} y={148} fill="#7c4dff" fontSize={7}>−Vg RESET</text>
        </>
      )}

      {/* ── Source to GND ── */}
      <line x1={260} y1={225} x2={260} y2={250} stroke={wireColor(firing || integrating)} strokeWidth={2} />
      <circle cx={260} cy={225} r={3} fill={wireColor(firing || integrating)} />
      <text x={275} y={229} fill="#aaa" fontSize={8}>SOURCE</text>

      {/* GND symbol */}
      <line x1={240} y1={250} x2={280} y2={250} stroke="#4fc3f7" strokeWidth={2} />
      <line x1={246} y1={256} x2={274} y2={256} stroke="#4fc3f7" strokeWidth={1.5} />
      <line x1={252} y1={262} x2={268} y2={262} stroke="#4fc3f7" strokeWidth={1} />
      <text x={288} y={256} fill="#4fc3f7" fontSize={8}>GND</text>

      {/* ── Feedback cap (optional) ── */}
      <line x1={360} y1={100} x2={420} y2={100} stroke="#4fc3f7" strokeWidth={1} opacity={0.4} />
      <line x1={420} y1={90} x2={420} y2={160} stroke="#4fc3f7" strokeWidth={1} opacity={0.4} />
      <line x1={415} y1={160} x2={425} y2={160} stroke="#4fc3f7" strokeWidth={1.5} opacity={0.6} />
      <line x1={412} y1={165} x2={428} y2={165} stroke="#4fc3f7" strokeWidth={1.5} opacity={0.6} />
      <text x={430} y={164} fill="#4fc3f7" fontSize={7} opacity={0.7}>C_fb</text>
      <line x1={420} y1={165} x2={420} y2={210} stroke="#4fc3f7" strokeWidth={1} opacity={0.4} />
      <line x1={420} y1={210} x2={290} y2={210} stroke="#4fc3f7" strokeWidth={1} opacity={0.4} />
      <line x1={290} y1={210} x2={290} y2={250} stroke="#4fc3f7" strokeWidth={1} opacity={0.4} />
      <text x={340} y={208} fill="#4fc3f7" fontSize={6.5} opacity={0.6}>feedback loop</text>

      {/* ── Current flow animation ── */}
      {(firing || integrating) && (
        <line
          x1={260} y1={30}
          x2={260} y2={225}
          stroke={phase.color}
          strokeWidth={2}
          strokeDasharray="4,4"
          strokeDashoffset={dashOffset}
          opacity={0.4}
          markerEnd="url(#arrowB)"
        />
      )}

      {/* ── Phase label ── */}
      <rect x={10} y={275} width={500} height={55} rx={5} fill="#0a0a20" stroke={phase.color} strokeWidth={1} />
      <text x={20} y={291} fill={phase.color} fontSize={9} fontWeight={700}>{phase.label}</text>
      <text x={20} y={307} fill="#ccc" fontSize={7.5} style={{ whiteSpace: "pre" }}>
        {phase.desc.length > 90 ? phase.desc.slice(0, 90) + "…" : phase.desc}
      </text>
      <text x={20} y={321} fill="#888" fontSize={7}>
        {phase.desc.length > 90 ? phase.desc.slice(90) : ""}
      </text>
    </svg>
  );
}

// ── Polarization Bar ──────────────────────────────────────────────────────────
function PolarizationBar({ pol, color }) {
  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 3 }}>
        <span style={{ fontSize: 10, color: "#aaa", fontFamily: "monospace" }}>HZO POLARIZATION ΔP</span>
        <span style={{ fontSize: 10, color, fontFamily: "monospace" }}>{Math.round(pol * 100)}%</span>
      </div>
      <div style={{ background: "#0a0a1e", borderRadius: 4, height: 14, border: "1px solid #1a1a3e", overflow: "hidden" }}>
        <div style={{
          width: `${pol * 100}%`,
          height: "100%",
          background: `linear-gradient(90deg, #7c4dff, ${color})`,
          transition: "width 0.4s ease",
          borderRadius: 4,
          boxShadow: `0 0 8px ${color}88`,
        }} />
      </div>
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────────────────────
export default function App() {
  const [phaseIdx, setPhaseIdx] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [animT, setAnimT] = useState(0);
  const [displayVth, setDisplayVth] = useState(PHASES[0].vth);
  const [displayIds, setDisplayIds] = useState(PHASES[0].ids);
  const [displayPol, setDisplayPol] = useState(PHASES[0].pol);

  const animRef = useRef(null);
  const tRef = useRef(0);
  const interpRef = useRef({ vth: PHASES[0].vth, ids: PHASES[0].ids, pol: PHASES[0].pol });

  const phase = PHASES[phaseIdx];

  // Animate t
  useEffect(() => {
    const tick = () => {
      tRef.current += 0.016;
      setAnimT(tRef.current);
      const target = PHASES[phaseIdx];
      interpRef.current.vth = lerp(interpRef.current.vth, target.vth, 0.07);
      interpRef.current.ids = lerp(interpRef.current.ids, target.ids, 0.07);
      interpRef.current.pol = lerp(interpRef.current.pol, target.pol, 0.07);
      setDisplayVth(interpRef.current.vth);
      setDisplayIds(interpRef.current.ids);
      setDisplayPol(interpRef.current.pol);
      animRef.current = requestAnimationFrame(tick);
    };
    animRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animRef.current);
  }, [phaseIdx]);

  // Auto-play
  useEffect(() => {
    if (!playing) return;
    const timer = setTimeout(() => {
      setPhaseIdx((p) => (p + 1) % PHASES.length);
    }, 2800);
    return () => clearTimeout(timer);
  }, [playing, phaseIdx]);

  const vthHist = useWaveform(displayVth);
  const idsHist = useWaveform(displayIds);
  const polHist = useWaveform(displayPol);

  return (
    <div style={{
      minHeight: "100vh",
      background: "#030309",
      color: "#eee",
      fontFamily: "'Courier New', monospace",
      padding: "16px",
      boxSizing: "border-box",
    }}>
      {/* Header */}
      <div style={{ textAlign: "center", marginBottom: 16 }}>
        <div style={{ fontSize: 9, letterSpacing: 6, color: "#4fc3f7", textTransform: "uppercase", marginBottom: 4 }}>
          Neuromorphic Device Simulator
        </div>
        <h1 style={{
          fontSize: "clamp(16px, 3vw, 22px)",
          fontWeight: 900,
          margin: 0,
          letterSpacing: 2,
          background: "linear-gradient(90deg, #4fc3f7, #7c4dff, #ff1744)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
        }}>
          GAA FeFET — Leaky Integrate & Fire Neuron
        </h1>
        <div style={{ fontSize: 8, color: "#556", letterSpacing: 3, marginTop: 4 }}>
          HZO · NANOSHEET · 360° GATE WRAP · POLARIZATION DYNAMICS
        </div>
      </div>

      {/* Main grid */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 280px",
        gap: 12,
        maxWidth: 1100,
        margin: "0 auto",
      }}>
        {/* Left — circuit */}
        <div style={{
          background: "#070712",
          border: `1px solid ${phase.color}44`,
          borderRadius: 8,
          padding: 12,
          boxShadow: `0 0 20px ${phase.color}22`,
          transition: "box-shadow 0.3s",
        }}>
          <div style={{ fontSize: 8, color: "#4fc3f7", letterSpacing: 3, marginBottom: 8 }}>
            ◈ CIRCUIT SCHEMATIC
          </div>
          <CircuitDiagram phase={phase} animT={animT} />
        </div>

        {/* Right panel */}
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>

          {/* GAA cross section */}
          <div style={{
            background: "#070712",
            border: "1px solid #1a1a3a",
            borderRadius: 8,
            padding: 10,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
          }}>
            <div style={{ fontSize: 8, color: "#4fc3f7", letterSpacing: 3, marginBottom: 8 }}>
              ◈ DEVICE CROSS-SECTION
            </div>
            <GAASection pol={displayPol} phase={phase} />
          </div>

          {/* Waveforms */}
          <div style={{
            background: "#070712",
            border: "1px solid #1a1a3a",
            borderRadius: 8,
            padding: 10,
          }}>
            <div style={{ fontSize: 8, color: "#4fc3f7", letterSpacing: 3, marginBottom: 8 }}>
              ◈ REAL-TIME TELEMETRY
            </div>
            <Waveform data={vthHist} color={phase.color} label="VTH (V)" unit="V" currentVal={displayVth.toFixed(2)} />
            <Waveform data={idsHist} color={phase.color} label="IDS (μA)" unit="μA" currentVal={(displayIds * 1000).toFixed(0)} />
            <Waveform data={polHist} color={phase.color} label="ΔP (norm)" unit="" currentVal={displayPol.toFixed(2)} />
          </div>

          {/* Polarization bar */}
          <div style={{
            background: "#070712",
            border: "1px solid #1a1a3a",
            borderRadius: 8,
            padding: 10,
          }}>
            <PolarizationBar pol={displayPol} color={phase.color} />
          </div>

          {/* Controls */}
          <div style={{
            background: "#070712",
            border: "1px solid #1a1a3a",
            borderRadius: 8,
            padding: 10,
            display: "flex",
            flexDirection: "column",
            gap: 8,
          }}>
            <div style={{ fontSize: 8, color: "#4fc3f7", letterSpacing: 3, marginBottom: 4 }}>
              ◈ SIMULATION CONTROLS
            </div>
            
            <div style={{ display: "flex", gap: 8 }}>
              <button
                onClick={() => setPlaying(!playing)}
                style={{
                  flex: 1,
                  padding: "8px 12px",
                  background: playing ? phase.color : "#1a1a3a",
                  color: "#fff",
                  border: `1px solid ${phase.color}`,
                  borderRadius: 4,
                  fontFamily: "monospace",
                  fontSize: 10,
                  fontWeight: 700,
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                {playing ? "⏸ PAUSE" : "▶ PLAY"}
              </button>
              
              <button
                onClick={() => {
                  setPlaying(false);
                  setPhaseIdx(0);
                  tRef.current = 0;
                  interpRef.current = { vth: PHASES[0].vth, ids: PHASES[0].ids, pol: PHASES[0].pol };
                  setDisplayVth(PHASES[0].vth);
                  setDisplayIds(PHASES[0].ids);
                  setDisplayPol(PHASES[0].pol);
                }}
                style={{
                  padding: "8px 12px",
                  background: "#1a1a3a",
                  color: "#4fc3f7",
                  border: "1px solid #4fc3f7",
                  borderRadius: 4,
                  fontFamily: "monospace",
                  fontSize: 10,
                  fontWeight: 700,
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                ↺ RESET
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              <div style={{ fontSize: 8, color: "#aaa", marginBottom: 2 }}>PHASE SELECTOR</div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 4 }}>
                {PHASES.map((p, i) => (
                  <button
                    key={p.id}
                    onClick={() => {
                      setPhaseIdx(i);
                      setPlaying(false);
                    }}
                    style={{
                      padding: "6px 4px",
                      background: i === phaseIdx ? p.color : "#1a1a3a",
                      color: i === phaseIdx ? "#000" : "#666",
                      border: `1px solid ${i === phaseIdx ? p.color : "#2a2a4a"}`,
                      borderRadius: 3,
                      fontFamily: "monospace",
                      fontSize: 7,
                      fontWeight: 700,
                      cursor: "pointer",
                      transition: "all 0.2s",
                    }}
                  >
                    {p.label.split(' ')[0]}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
