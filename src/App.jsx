import React, { useState, useEffect, useRef, useCallback } from 'react';

/* ──────────────────────────────────────────────────────────
   ErrandBoy — Investor Demo, v2
   Design rules for this file (deliberate, non-default):
   · One typeface. Hierarchy from size & weight only.
   · No borders. Surfaces separate by background, not lines.
   · One accent (#0E6B4F) reserved for money & proof.
   · No emoji, no badges, no uppercase tracking labels.
   · One delight: drawn checkmark + counting numerals.
   ────────────────────────────────────────────────────────── */

const ink = '#161617';
const sub = '#86868B';
const canvas = '#F5F4F2';
const surface = '#FFFFFF';
const pine = '#0E6B4F';
const press = '#0B0B0C';

const css = `
@import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700;800&display=swap');

.eb * { box-sizing:border-box; -webkit-font-smoothing:antialiased; }
.eb { font-family:'Hanken Grotesk',-apple-system,sans-serif; background:#E9E8E5; min-height:100vh; color:${ink}; }
.eb button { font-family:inherit; color:inherit; border:none; background:none; padding:0; cursor:pointer; text-align:left; }
.eb .num { font-variant-numeric: tabular-nums; }

.eb-stage { display:flex; gap:64px; max-width:1100px; margin:0 auto; padding:56px 32px 72px; align-items:flex-start; justify-content:center; }
@media (max-width:900px){ .eb-stage{ flex-direction:column; align-items:center; gap:36px; } .eb-rail{ max-width:400px; width:100%; position:static; } }

.eb-rail { width:320px; flex-shrink:0; position:sticky; top:56px; }

.eb-seg { display:flex; background:rgba(0,0,0,.055); border-radius:12px; padding:3px; }
.eb-seg button { flex:1; text-align:center; font-size:13.5px; font-weight:600; padding:9px 0; border-radius:9px; color:${sub}; transition:all .2s ease; }
.eb-seg button.on { background:#fff; color:${ink}; box-shadow:0 1px 4px rgba(0,0,0,.10); }

.eb-phone { width:384px; flex-shrink:0; background:#3C3C3E; border-radius:54px; padding:10px; box-shadow:0 24px 64px rgba(0,0,0,.22); }
@media (max-width:430px){ .eb-phone{ width:100%; } }
.eb-screen { background:${canvas}; border-radius:45px; overflow:hidden; height:792px; display:flex; flex-direction:column; position:relative; }

.eb-group { background:${surface}; border-radius:18px; box-shadow:0 1px 2px rgba(0,0,0,.03); }
.eb-row { display:flex; justify-content:space-between; align-items:center; padding:15px 18px; }
.eb-row + .eb-row { border-top:1px solid ${canvas}; }

.eb-cta { display:block; width:100%; text-align:center; background:${ink}; color:#fff; font-size:16px; font-weight:600; padding:16px; border-radius:16px; transition:transform .12s ease, background .15s; }
.eb-cta:active { transform:scale(.975); background:${press}; }
.eb-cta:disabled { opacity:.3; }
.eb-quiet { display:block; width:100%; text-align:center; color:${sub}; font-size:14px; font-weight:500; padding:12px; }

.eb button:focus-visible { outline:2px solid ${pine}; outline-offset:3px; border-radius:8px; }

.fade { animation:fd .4s ease both; }
@keyframes fd { from{opacity:0; transform:translateY(6px)} to{opacity:1; transform:none} }
@keyframes breathe { 0%,100%{opacity:1} 50%{opacity:.35} }
@keyframes drawC { to { stroke-dashoffset:0; } }
@keyframes route { to { stroke-dashoffset:-24; } }
@media (prefers-reduced-motion:reduce){ .fade{animation:none} .eb *{animation-duration:.001s !important; transition-duration:.001s !important} }
`;

/* ── Minimal stroke icons (hand-drawn, 1.5px) ──────────── */
const I = ({ d, s = 20, c = 'currentColor', sw = 1.6 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
    <path d={d} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
const ic = {
  chevR: 'M9 5l7 7-7 7',
  chevL: 'M15 19l-7-7 7-7',
  camera: 'M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V8z M12 16a3.5 3.5 0 100-7 3.5 3.5 0 000 7z',
  box: 'M4 8l8-4 8 4v8l-8 4-8-4V8z M4 8l8 4m0 0l8-4m-8 4v8',
  check: 'M5 12.5l5 5L19 7',
  clock: 'M12 21a9 9 0 100-18 9 9 0 000 18z M12 8v4.5l3 2',
  doc: 'M7 3h7l4 4v14H7V3z M14 3v4h4',
  card: 'M3 7a2 2 0 012-2h14a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V7z M3 10h18',
};

/* ── Hooks ─────────────────────────────────────────────── */
const useCount = (target, run, dur = 1400) => {
  const [v, setV] = useState(0);
  useEffect(() => {
    if (!run) { setV(0); return; }
    let start, raf;
    const step = t => {
      if (!start) start = t;
      const p = Math.min((t - start) / dur, 1);
      setV(target * (1 - Math.pow(1 - p, 3)));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [run, target, dur]);
  return v;
};

/* ── Shared ────────────────────────────────────────────── */
const Status = () => (
  <div className="num" style={{ display:'flex', justifyContent:'space-between', padding:'16px 28px 0', fontSize:14, fontWeight:600 }}>
    <span>2:04</span><span style={{ letterSpacing:2, fontSize:11 }}>●●●</span>
  </div>
);

const Nav = ({ title, back, trailing }) => (
  <div style={{ display:'flex', alignItems:'center', padding:'12px 20px 4px', minHeight:48 }}>
    {back ? <button onClick={back} aria-label="Back" style={{ padding:6, marginLeft:-6, color:ink }}><I d={ic.chevL} /></button> : <span style={{ width:32 }} />}
    <div style={{ flex:1, textAlign:'center', fontSize:16, fontWeight:600 }}>{title}</div>
    <span style={{ width:32, display:'flex', justifyContent:'flex-end' }}>{trailing}</span>
  </div>
);

const DrawnCheck = ({ size = 88 }) => (
  <svg width={size} height={size} viewBox="0 0 88 88" aria-hidden>
    <circle cx="44" cy="44" r="40" fill="none" stroke={pine} strokeWidth="3"
      strokeDasharray="252" strokeDashoffset="252" style={{ animation:'drawC .55s ease-out forwards' }} />
    <path d="M28 45l11 11 21-24" fill="none" stroke={pine} strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"
      strokeDasharray="50" strokeDashoffset="50" style={{ animation:'drawC .4s .45s ease-out forwards' }} />
  </svg>
);

/* ── Data ──────────────────────────────────────────────── */
const ITEM = { retailer:'Nordstrom', item:'On Cloudmonster, W 8.5', order:'NORD-448291', refund:149.95 };
const STEPS = [
  { t:'2:04', title:'Runner matched', sub:'Maya · 4.97 · 612 returns' },
  { t:'2:21', title:'Maya is on the way', sub:'Arriving in your 2–4 pm window' },
  { t:'2:38', title:'Picked up at your door', sub:'Item and label photographed', proof:true },
  { t:'3:02', title:'En route to UPS', sub:'Sealed bag 8841 · 1.8 mi' },
  { t:'3:19', title:'Dropped off, receipt in hand', sub:'UPS acceptance scan confirmed', proof:true },
  { t:'3:20', title:'Refund initiated', sub:'$149.95 from Nordstrom, 3–5 days', money:true },
];

const NOTES = {
  'c-home':   ['Customer · Home', 'Open on the only number that matters to her: hours back. We sell time, not logistics.'],
  'c-snap':   ['Customer · New return', 'The entire ask is two photos. We read the label — she types nothing. Friction is the competitor.'],
  'c-window': ['Customer · Schedule', 'One flat price, stated once. No surge, no tipping screen, no upsell. Trust is priced in.'],
  'c-pay':    ['Customer · Confirm', 'Point at what isn\u2019t here: no cart, no account setup wall. Thirty seconds, door to done.'],
  'c-track':  ['Customer · Tracking', 'The moat: every handoff timestamped with photo proof. This custody record is what a retailer or carrier acquires.'],
  'c-done':   ['Customer · Complete', 'We close the loop on her refund, not our dropoff. The counted minutes are the brand.'],
  'r-feed':   ['Runner · Offers', 'Supply economics: four returns batch into one UPS run. Density, not hustle, sets the wage.'],
  'r-job':    ['Runner · Pickup', 'Three taps, no typing, no training. Quality is enforced by the flow itself.'],
  'founder':  ['Founder · The case', 'Contribution margin per order, cohort retention, the ask, and the three risks — before they ask.'],
};

/* ══ CUSTOMER ══════════════════════════════════════════ */

const Home = ({ go, active }) => {
  const hrs = useCount(11.5, true, 1600);
  return (
    <div className="fade" style={{ flex:1, overflow:'auto' }}>
      <Status />
      <div style={{ padding:'26px 24px 8px' }}>
        <div style={{ fontSize:14, fontWeight:600, color:sub }}>Returned to you</div>
        <div className="num" style={{ fontSize:64, fontWeight:800, letterSpacing:-2.5, lineHeight:1.05, marginTop:2 }}>
          {hrs.toFixed(1)}<span style={{ fontSize:28, fontWeight:700, letterSpacing:0, marginLeft:6, color:sub }}>hours</span>
        </div>
        <div style={{ fontSize:14, color:sub, marginTop:6 }}>14 returns this year · <span style={{ color:pine, fontWeight:600 }}>$1,872 refunded</span></div>
      </div>

      <div style={{ padding:'20px 20px 28px' }}>
        {active ? (
          <button className="eb-group" onClick={() => go('c-track')} style={{ width:'100%', padding:'17px 18px', display:'flex', alignItems:'center', gap:14 }}>
            <span style={{ width:9, height:9, borderRadius:9, background:pine, animation:'breathe 1.8s infinite', flexShrink:0 }} />
            <span style={{ flex:1 }}>
              <span style={{ display:'block', fontWeight:600, fontSize:15 }}>Nordstrom return in progress</span>
              <span style={{ display:'block', fontSize:13, color:sub, marginTop:1 }}>Maya picks up 2–4 pm today</span>
            </span>
            <I d={ic.chevR} s={18} c={sub} />
          </button>
        ) : (
          <button className="eb-cta" onClick={() => go('c-snap')}>Return something</button>
        )}

        <div style={{ fontSize:13, fontWeight:600, color:sub, margin:'26px 4px 10px' }}>Past returns</div>
        <div className="eb-group">
          {[['Amazon', 'USB-C hub', 42.99], ['Zara', 'Linen blazer', 89.90], ['REI', 'Trail poles', 129.00]].map(([r, it, amt]) => (
            <div className="eb-row" key={it}>
              <div>
                <div style={{ fontWeight:600, fontSize:15 }}>{r}</div>
                <div style={{ fontSize:13, color:sub, marginTop:1 }}>{it}</div>
              </div>
              <div className="num" style={{ fontSize:15, fontWeight:600, color:pine }}>${amt.toFixed(2)}</div>
            </div>
          ))}
        </div>
        <div style={{ textAlign:'center', fontSize:12.5, color:sub, marginTop:18 }}>Every refund above arrived. We track them until they do.</div>
      </div>
    </div>
  );
};

const Snap = ({ go }) => {
  const [shots, setShots] = useState(0);
  const [read, setRead] = useState(false);
  useEffect(() => {
    if (shots === 2) { const t = setTimeout(() => setRead(true), 1100); return () => clearTimeout(t); }
  }, [shots]);

  const Frame = ({ i, label }) => {
    const done = shots > i;
    const activeF = shots === i;
    return (
      <button onClick={() => activeF && setShots(i + 1)} aria-label={label}
        style={{ flex:1, height:170, borderRadius:18, position:'relative', overflow:'hidden',
          background: done ? 'linear-gradient(150deg,#2A2A2C,#1A1A1B)' : surface,
          boxShadow: activeF ? `inset 0 0 0 2px ${ink}` : '0 1px 2px rgba(0,0,0,.03)',
          display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:10,
          transition:'all .25s ease' }}>
        {done ? (
          <>
            <span style={{ position:'absolute', inset:0, background:'radial-gradient(120px 80px at 35% 30%, rgba(255,255,255,.14), transparent)' }} />
            <span style={{ position:'absolute', top:12, right:12, width:24, height:24, borderRadius:12, background:'#fff', display:'grid', placeItems:'center' }}>
              <I d={ic.check} s={14} c={pine} sw={2.4} />
            </span>
            <span style={{ color:'rgba(255,255,255,.85)', fontSize:13, fontWeight:600 }}>{label}</span>
          </>
        ) : (
          <>
            <I d={ic.camera} s={26} c={activeF ? ink : '#C9C9CE'} />
            <span style={{ fontSize:13.5, fontWeight:600, color: activeF ? ink : '#C9C9CE' }}>{label}</span>
            {activeF && <span style={{ fontSize:12, color:sub }}>Tap to capture</span>}
          </>
        )}
      </button>
    );
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="New return" back={() => go('c-home')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div style={{ fontSize:22, fontWeight:700, letterSpacing:-.4, padding:'4px 4px 16px' }}>Two photos.<br />We handle the rest.</div>
        <div style={{ display:'flex', gap:12 }}>
          <Frame i={0} label="The item" />
          <Frame i={1} label="The label" />
        </div>

        {shots === 2 && !read && (
          <div className="fade" style={{ marginTop:20, fontSize:14, color:sub, textAlign:'center' }}>Reading label…</div>
        )}

        {read && (
          <div className="eb-group fade" style={{ marginTop:20 }}>
            {[['Retailer', ITEM.retailer], ['Item', ITEM.item], ['Order', ITEM.order], ['Refund due', `$${ITEM.refund}`]].map(([k, v], i) => (
              <div className="eb-row" key={k} style={{ padding:'13px 18px' }}>
                <span style={{ fontSize:14.5, color:sub }}>{k}</span>
                <span className="num" style={{ fontSize:14.5, fontWeight:600, color: i === 3 ? pine : ink }}>{v}</span>
              </div>
            ))}
          </div>
        )}

        <div style={{ flex:1 }} />
        <button className="eb-cta" disabled={!read} onClick={() => read && go('c-window')}>Continue</button>
      </div>
    </div>
  );
};

const Window = ({ go }) => {
  const [win, setWin] = useState(1);
  const [pack, setPack] = useState(true);
  const windows = ['12–2 pm', '2–4 pm', '4–6 pm', 'Tomorrow am'];
  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="Pickup" back={() => go('c-snap')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div style={{ fontSize:13, fontWeight:600, color:sub, margin:'4px 4px 10px' }}>Today</div>
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
          {windows.map((w, i) => (
            <button key={w} onClick={() => setWin(i)}
              style={{ textAlign:'center', padding:'15px 0', borderRadius:14, fontSize:15, fontWeight:600,
                background: win === i ? ink : surface, color: win === i ? '#fff' : ink,
                boxShadow:'0 1px 2px rgba(0,0,0,.03)', transition:'all .18s ease' }}>{w}</button>
          ))}
        </div>

        <button className="eb-group" onClick={() => setPack(!pack)} style={{ width:'100%', marginTop:14, padding:'15px 18px', display:'flex', gap:14, alignItems:'center' }}>
          <span style={{ width:24, height:24, borderRadius:12, flexShrink:0, display:'grid', placeItems:'center',
            background: pack ? pine : '#E8E8EA', transition:'background .2s' }}>
            {pack && <I d={ic.check} s={14} c="#fff" sw={2.6} />}
          </span>
          <span>
            <span style={{ display:'block', fontWeight:600, fontSize:15 }}>No box? Maya brings one.</span>
            <span style={{ display:'block', fontSize:13, color:sub, marginTop:1 }}>Hand it over as-is · adds $2</span>
          </span>
        </button>

        <div style={{ flex:1 }} />
        <div style={{ textAlign:'center', marginBottom:18 }}>
          <span className="num" style={{ fontSize:44, fontWeight:800, letterSpacing:-1.5 }}>${pack ? '14.50' : '12.50'}</span>
          <div style={{ fontSize:13.5, color:sub, marginTop:2 }}>Flat. Door to refund. About 50 minutes of your day, kept.</div>
        </div>
        <button className="eb-cta" onClick={() => go('c-pay')}>Continue</button>
      </div>
    </div>
  );
};

const Pay = ({ go, onConfirm }) => {
  const [paying, setPaying] = useState(false);
  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="Confirm" back={() => go('c-window')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div className="eb-group">
          {[['Return', `${ITEM.retailer} · ${ITEM.item}`], ['Pickup', 'Today, 2–4 pm · your door'], ['Drop-off', 'UPS, Midtown'], ['Refund tracked', `$${ITEM.refund}`]].map(([k, v], i) => (
            <div className="eb-row" key={k} style={{ padding:'14px 18px' }}>
              <span style={{ fontSize:14.5, color:sub, flexShrink:0 }}>{k}</span>
              <span className="num" style={{ fontSize:14.5, fontWeight:600, textAlign:'right', color: i === 3 ? pine : ink }}>{v}</span>
            </div>
          ))}
        </div>
        <div className="eb-group eb-row" style={{ marginTop:12, padding:'14px 18px' }}>
          <span style={{ display:'flex', alignItems:'center', gap:10, fontSize:14.5, fontWeight:600 }}><I d={ic.card} s={18} c={sub} /> Visa 4421</span>
          <span style={{ fontSize:13.5, color:sub }}>Change</span>
        </div>

        <div style={{ flex:1 }} />
        <button className="eb-cta" disabled={paying} onClick={() => { setPaying(true); setTimeout(() => { onConfirm(); go('c-track'); }, 1000); }}>
          {paying ? 'Finding your runner…' : 'Pay $14.50'}
        </button>
        <div className="eb-quiet" style={{ cursor:'default' }}>Cancel free until Maya is en route</div>
      </div>
    </div>
  );
};

const Track = ({ go, stage }) => {
  const seen = STEPS.slice(0, stage);
  const done = stage >= STEPS.length;
  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title={done ? 'Returned' : 'In progress'} back={() => go('c-home')} />

      <div style={{ margin:'4px 20px 0', borderRadius:18, overflow:'hidden', background:surface, boxShadow:'0 1px 2px rgba(0,0,0,.03)' }}>
        <svg viewBox="0 0 344 132" width="100%" aria-hidden style={{ display:'block' }}>
          {[24,56,88,120].map(y => <line key={y} x1="0" y1={y} x2="344" y2={y} stroke={canvas} strokeWidth="5" />)}
          {[58,138,218,298].map(x => <line key={x} x1={x} y1="0" x2={x} y2="132" stroke={canvas} strokeWidth="5" />)}
          <path d="M58 108 L58 56 L218 56 L218 24 L298 24" fill="none" stroke={ink} strokeWidth="2.5"
            strokeLinecap="round" strokeDasharray="9 15" style={{ animation: done ? 'none' : 'route 1.4s linear infinite' }} />
          <circle cx="58" cy="108" r="5.5" fill={ink} />
          <circle cx="298" cy="24" r="5.5" fill="none" stroke={ink} strokeWidth="2.5" />
          {!done && (
            <circle r="7" fill={pine} style={{
              transform:`translate(${stage < 3 ? 58 : stage < 5 ? 178 : 298}px, ${stage < 3 ? 86 : stage < 5 ? 56 : 24}px)`,
              transition:'transform 1.4s ease' }} />
          )}
          <text x="58" y="126" textAnchor="middle" fontSize="10" fontWeight="600" fill={sub} fontFamily="inherit">Home</text>
          <text x="298" y="14" textAnchor="middle" fontSize="10" fontWeight="600" fill={sub} fontFamily="inherit">UPS</text>
        </svg>
      </div>

      <div style={{ padding:'22px 28px 28px' }}>
        {seen.map((s, i) => {
          const last = i === seen.length - 1;
          return (
            <div key={s.title} className="fade" style={{ display:'flex', gap:16, position:'relative', paddingBottom: last ? 0 : 22 }}>
              {!last && <span style={{ position:'absolute', left:4.5, top:18, bottom:2, width:1.5, background:'#E3E2DF' }} />}
              <span style={{ width:11, height:11, borderRadius:11, marginTop:4, flexShrink:0,
                background: s.money ? pine : last && !done ? ink : '#C9C8C5',
                outline: last && !done ? `4px solid rgba(22,22,23,.08)` : 'none' }} />
              <div style={{ flex:1 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
                  <span style={{ fontSize:15.5, fontWeight: last ? 700 : 600, color: s.money ? pine : ink }}>{s.title}</span>
                  <span className="num" style={{ fontSize:13, color:sub }}>{s.t}</span>
                </div>
                <div style={{ fontSize:13.5, color:sub, marginTop:2 }}>{s.sub}</div>
                {s.proof && <button style={{ fontSize:13.5, fontWeight:600, color:pine, marginTop:6 }}>View photo proof</button>}
              </div>
            </div>
          );
        })}
        {!done && <div style={{ fontSize:13, color:sub, paddingLeft:27, paddingTop:14, animation:'breathe 1.8s infinite' }}>Updating…</div>}
        {done && <button className="eb-cta fade" style={{ marginTop:26 }} onClick={() => go('c-done')}>Done</button>}
      </div>
    </div>
  );
};

const Done = ({ go, onReset }) => {
  const mins = useCount(52, true, 1500);
  const [stars, setStars] = useState(5);
  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto', textAlign:'center' }}>
      <Status />
      <div style={{ padding:'52px 28px 28px', flex:1, display:'flex', flexDirection:'column', alignItems:'center' }}>
        <DrawnCheck />
        <div className="num" style={{ fontSize:58, fontWeight:800, letterSpacing:-2, marginTop:26, lineHeight:1 }}>{Math.round(mins)} min</div>
        <div style={{ fontSize:17, fontWeight:600, marginTop:8 }}>returned to your day.</div>
        <div style={{ fontSize:14, color:sub, marginTop:14, lineHeight:1.55 }}>
          Nordstrom has your sneakers.<br />
          <span style={{ color:pine, fontWeight:600 }}>$149.95</span> is on its way back — we'll tell you when it lands.
        </div>

        <div style={{ marginTop:40 }}>
          <div style={{ fontSize:14, fontWeight:600 }}>How was Maya?</div>
          <div style={{ display:'flex', gap:4, marginTop:10, justifyContent:'center' }} role="radiogroup" aria-label="Rate Maya">
            {[1,2,3,4,5].map(n => (
              <button key={n} onClick={() => setStars(n)} aria-label={`${n} of 5`} style={{ padding:4 }}>
                <svg width="26" height="26" viewBox="0 0 24 24" fill={n <= stars ? ink : 'none'}>
                  <path d="M12 3l2.7 5.8 6.3.7-4.7 4.3 1.3 6.2L12 16.9 6.4 20l1.3-6.2L3 9.5l6.3-.7L12 3z" stroke={n <= stars ? ink : '#C9C8C5'} strokeWidth="1.5" strokeLinejoin="round" />
                </svg>
              </button>
            ))}
          </div>
        </div>

        <div style={{ flex:1 }} />
        <button className="eb-cta" style={{ width:'100%' }} onClick={() => { onReset(); go('c-home'); }}>Done</button>
      </div>
    </div>
  );
};

/* ══ RUNNER ════════════════════════════════════════════ */

const Feed = ({ go }) => {
  const earn = useCount(86, true, 1200);
  return (
    <div className="fade" style={{ flex:1, overflow:'auto' }}>
      <Status />
      <div style={{ padding:'24px 24px 8px', display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
        <div>
          <div style={{ fontSize:14, color:sub, fontWeight:600 }}>Today, Chelsea zone</div>
          <div className="num" style={{ fontSize:46, fontWeight:800, letterSpacing:-1.5, lineHeight:1.1 }}>${Math.round(earn)}</div>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:7, fontSize:13.5, fontWeight:600, color:pine, paddingBottom:8 }}>
          <span style={{ width:8, height:8, borderRadius:8, background:pine, animation:'breathe 1.8s infinite' }} />Online
        </div>
      </div>

      <div style={{ padding:'14px 20px 28px' }}>
        <div className="eb-group" style={{ padding:'20px 20px 18px' }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
            <div style={{ fontSize:17, fontWeight:700 }}>Batch of 4 · one UPS run</div>
            <div className="num" style={{ fontSize:20, fontWeight:800 }}>$38.40</div>
          </div>
          <div style={{ fontSize:13.5, color:sub, marginTop:3 }}>2.6 mi loop · about 55 min · <span style={{ color:pine, fontWeight:600 }}>$42/hr</span></div>
          <div style={{ marginTop:16 }}>
            {['412 W 23rd — sneakers, bring a box', '388 W 21st — blazer, labeled', '301 W 19th — two parcels, ready', 'Drop all at UPS, Midtown'].map((s, i, a) => (
              <div key={s} style={{ display:'flex', gap:12, alignItems:'center', position:'relative', paddingBottom: i === a.length - 1 ? 0 : 14 }}>
                {i !== a.length - 1 && <span style={{ position:'absolute', left:3.5, top:14, bottom:0, width:1.5, background:'#E8E8EA' }} />}
                <span style={{ width:9, height:9, borderRadius:9, flexShrink:0, background: i === a.length - 1 ? pine : '#C9C8C5' }} />
                <span style={{ fontSize:14, fontWeight: i === a.length - 1 ? 600 : 500, color: i === a.length - 1 ? ink : '#48484C' }}>{s}</span>
              </div>
            ))}
          </div>
          <button className="eb-cta" style={{ marginTop:18 }} onClick={() => go('r-job')}>Accept batch</button>
        </div>

        <div className="eb-group" style={{ marginTop:12 }}>
          {[['Single, Flatiron', '0.9 mi · 1 return', '$9.75'], ['Batch of 3, West Village', '3.1 mi loop', '$29.10']].map(([t, s, p]) => (
            <div className="eb-row" key={t}>
              <div><div style={{ fontWeight:600, fontSize:15 }}>{t}</div><div style={{ fontSize:13, color:sub, marginTop:1 }}>{s}</div></div>
              <span className="num" style={{ fontWeight:700, fontSize:15 }}>{p}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const Job = ({ go }) => {
  const [step, setStep] = useState(0);
  const tasks = [
    ['Photograph the item at the door', ic.camera],
    ['Scan the return label', ic.doc],
    ['Seal in bag 8841', ic.box],
  ];
  const all = step >= 3;
  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="Stop 1 of 4" back={() => go('r-feed')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div style={{ padding:'4px 4px 18px' }}>
          <div style={{ fontSize:21, fontWeight:700, letterSpacing:-.3 }}>412 W 23rd · Elliot</div>
          <div style={{ fontSize:14, color:sub, marginTop:3 }}>{ITEM.retailer} sneakers · bring a box, he chose packaging</div>
        </div>

        <div className="eb-group">
          {tasks.map(([t, icon], i) => {
            const doneT = i < step;
            const activeT = i === step;
            return (
              <button key={t} className="eb-row" onClick={() => activeT && setStep(step + 1)}
                style={{ width:'100%', gap:14, opacity: i > step ? .35 : 1, transition:'opacity .25s' }}>
                <span style={{ width:34, height:34, borderRadius:17, flexShrink:0, display:'grid', placeItems:'center',
                  background: doneT ? pine : canvas, transition:'background .25s' }}>
                  {doneT ? <I d={ic.check} s={16} c="#fff" sw={2.4} /> : <I d={icon} s={17} c={activeT ? ink : sub} />}
                </span>
                <span style={{ flex:1, fontSize:15, fontWeight:600 }}>{t}</span>
                {doneT && <span className="num" style={{ fontSize:12.5, color:sub }}>2:38</span>}
                {activeT && <span style={{ fontSize:13, color:sub }}>Tap</span>}
              </button>
            );
          })}
        </div>

        {all && (
          <div className="fade" style={{ marginTop:18, textAlign:'center' }}>
            <div style={{ fontSize:15, fontWeight:600 }}>Custody is yours.</div>
            <div style={{ fontSize:13.5, color:sub, marginTop:3 }}>Elliot just got your photos. Next: 388 W 21st.</div>
          </div>
        )}
        <div style={{ flex:1 }} />
        <button className="eb-cta" disabled={!all} onClick={() => go('r-feed')}>{all ? 'Navigate to stop 2' : 'Complete the three steps'}</button>
      </div>
    </div>
  );
};

/* ══ FOUNDER ═══════════════════════════════════════════ */

const Founder = () => {
  const Stat = ({ k, v, s }) => (
    <div style={{ flex:1, minWidth:140 }}>
      <div className="num" style={{ fontSize:30, fontWeight:800, letterSpacing:-1 }}>{v}</div>
      <div style={{ fontSize:13, fontWeight:600, marginTop:2 }}>{k}</div>
      {s && <div style={{ fontSize:12, color:sub, marginTop:1 }}>{s}</div>}
    </div>
  );
  const margin = [
    ['Customer pays', 14.50, ink],
    ['Runner (batched)', -8.90, '#A5A4A1'],
    ['Support, insurance, payments', -1.11, '#C9C8C5'],
    ['Contribution per order', 4.49, pine],
  ];
  const cohorts = [
    ['Feb', [100, 64, 51, 47]],
    ['Mar', [100, 62, 49, null]],
    ['Apr', [100, 61, null, null]],
    ['May', [100, null, null, null]],
  ];
  return (
    <div className="fade" style={{ flex:1, overflow:'auto' }}>
      <Status />
      <div style={{ padding:'22px 24px 32px' }}>
        <div style={{ fontSize:13.5, fontWeight:600, color:sub }}>Chelsea pilot · week 8</div>
        <div style={{ fontSize:25, fontWeight:800, letterSpacing:-.6, marginTop:2 }}>The case, in one screen.</div>

        <div style={{ display:'flex', gap:12, marginTop:22, flexWrap:'wrap' }}>
          <Stat k="Returns done" v="509" s="+34% wk over wk" />
          <Stat k="Repeat in 30 days" v="61%" s="of paying customers" />
        </div>

        {/* Contribution margin — the slide that survives diligence */}
        <div style={{ marginTop:28 }}>
          <div style={{ fontSize:14, fontWeight:700 }}>Every order makes money</div>
          <div style={{ marginTop:12 }}>
            {margin.map(([k, v, c]) => (
              <div key={k} style={{ display:'flex', alignItems:'center', gap:12, marginBottom:9 }}>
                <span style={{ width:118, fontSize:12.5, color: c === pine ? pine : sub, fontWeight: c === pine ? 700 : 500, flexShrink:0 }}>{k}</span>
                <span style={{ height:22, borderRadius:6, background:c, width:`${(Math.abs(v) / 14.5) * 100}%`, minWidth:8, transition:'width .6s' }} />
                <span className="num" style={{ fontSize:13, fontWeight:700, color: c === pine ? pine : ink }}>{v < 0 ? '−' : ''}${Math.abs(v).toFixed(2)}</span>
              </div>
            ))}
          </div>
          <div style={{ fontSize:12.5, color:sub, lineHeight:1.5, marginTop:6 }}>
            Batching is the unlock: four returns share one trip, so the runner earns $42/hr while we keep 31%. Single-task gig apps can't replicate the route density.
          </div>
        </div>

        {/* Cohorts */}
        <div style={{ marginTop:26 }}>
          <div style={{ fontSize:14, fontWeight:700 }}>They come back</div>
          <div style={{ fontSize:12.5, color:sub, marginTop:2 }}>Monthly retention by cohort, % still ordering</div>
          <div style={{ marginTop:12 }}>
            <div style={{ display:'flex', gap:6, marginBottom:6 }}>
              <span style={{ width:34 }} />
              {['M0','M1','M2','M3'].map(m => <span key={m} className="num" style={{ flex:1, textAlign:'center', fontSize:11, color:sub, fontWeight:600 }}>{m}</span>)}
            </div>
            {cohorts.map(([m, row]) => (
              <div key={m} style={{ display:'flex', gap:6, marginBottom:6 }}>
                <span style={{ width:34, fontSize:11.5, color:sub, fontWeight:600, alignSelf:'center' }}>{m}</span>
                {row.map((v, i) => (
                  <span key={i} className="num" style={{ flex:1, textAlign:'center', fontSize:12.5, fontWeight:700, padding:'9px 0', borderRadius:8,
                    background: v == null ? 'transparent' : `rgba(14,107,79,${0.06 + (v / 100) * 0.5})`,
                    color: v == null ? 'transparent' : v > 70 ? '#fff' : pine }}>{v ?? '·'}</span>
                ))}
              </div>
            ))}
          </div>
        </div>

        {/* The ask */}
        <div style={{ marginTop:26, background:ink, borderRadius:18, padding:'20px', color:'#fff' }}>
          <div style={{ fontSize:14, fontWeight:700 }}>The ask: $300K</div>
          <div style={{ fontSize:13, color:'rgba(255,255,255,.65)', marginTop:8, lineHeight:1.65 }}>
            Buys 12 months and four milestones: three NYC zones live, 2,500 returns a week, contribution-positive at the order level, and one signed retailer pilot. Hit those and the seed prices itself.
          </div>
        </div>

        {/* Risks, named first */}
        <div style={{ marginTop:24 }}>
          <div style={{ fontSize:14, fontWeight:700 }}>What kills this, and our answer</div>
          {[
            ['Density cold start', 'Launch one zip at a time; batch from day one; seed demand through doorman buildings.'],
            ['Trust and fraud', 'Photo custody at every handoff, sealed bags, $500 per-item guarantee. The record is the product.'],
            ['Retailers go free-pickup', 'Then we become their pickup layer — the custody API is built to be sold to them, not against them.'],
          ].map(([r, a]) => (
            <div key={r} style={{ marginTop:14 }}>
              <div style={{ fontSize:13.5, fontWeight:700 }}>{r}</div>
              <div style={{ fontSize:13, color:sub, lineHeight:1.55, marginTop:2 }}>{a}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

/* ══ ROOT ══════════════════════════════════════════════ */

export default function ErrandBoyDemo() {
  const [screen, setScreen] = useState('c-home');
  const [persona, setPersona] = useState('customer');
  const [active, setActive] = useState(false);
  const [stage, setStage] = useState(0);

  const go = useCallback(s => setScreen(s), []);

  useEffect(() => {
    if (screen === 'c-track' && stage < STEPS.length) {
      const t = setTimeout(() => setStage(s => s + 1), stage === 0 ? 500 : 2400);
      return () => clearTimeout(t);
    }
  }, [screen, stage]);

  const switchP = p => {
    setPersona(p);
    setScreen(p === 'customer' ? (active ? 'c-track' : 'c-home') : p === 'runner' ? 'r-feed' : 'founder');
  };
  const reset = () => { setActive(false); setStage(0); setPersona('customer'); setScreen('c-home'); };

  const [scene, say] = NOTES[screen] || NOTES.founder;

  const render = () => {
    switch (screen) {
      case 'c-home':   return <Home go={go} active={active} />;
      case 'c-snap':   return <Snap go={go} />;
      case 'c-window': return <Window go={go} />;
      case 'c-pay':    return <Pay go={go} onConfirm={() => { setActive(true); setStage(0); }} />;
      case 'c-track':  return <Track go={go} stage={stage} />;
      case 'c-done':   return <Done go={go} onReset={() => { setActive(false); setStage(0); }} />;
      case 'r-feed':   return <Feed go={go} />;
      case 'r-job':    return <Job go={go} />;
      default:         return <Founder />;
    }
  };

  return (
    <div className="eb">
      <style>{css}</style>
      <div className="eb-stage">

        <div className="eb-rail">
          <div style={{ fontSize:26, fontWeight:800, letterSpacing:-.8 }}>ErrandBoy</div>
          <div style={{ fontSize:14, color:sub, marginTop:6, lineHeight:1.55 }}>
            Returns, handled. Two photos, one flat price, proof at every handoff.
          </div>

          <div className="eb-seg" style={{ marginTop:26 }} role="tablist" aria-label="Persona">
            {[['customer','Customer'], ['runner','Runner'], ['founder','Founder']].map(([k, t]) => (
              <button key={k} role="tab" aria-selected={persona === k} className={persona === k ? 'on' : ''} onClick={() => switchP(k)}>{t}</button>
            ))}
          </div>

          <div style={{ marginTop:28, paddingTop:20, borderTop:`1px solid rgba(0,0,0,.08)` }}>
            <div style={{ fontSize:12.5, fontWeight:700, color:sub }}>{scene}</div>
            <div style={{ fontSize:14.5, lineHeight:1.6, marginTop:8 }}>{say}</div>
          </div>

          <button onClick={reset} style={{ marginTop:26, fontSize:13.5, fontWeight:600, color:sub }}>Reset demo</button>
        </div>

        <div className="eb-phone">
          <div className="eb-screen">{render()}</div>
        </div>
      </div>
    </div>
  );
}
