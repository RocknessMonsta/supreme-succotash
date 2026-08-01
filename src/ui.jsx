import React, { useState, useEffect, useRef } from 'react';
import { ink, sub, canvas, surface, pine, press } from './tokens.js';
import { useCount, useFlipDigit } from './hooks.js';

export const css = `
@import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700;800&display=swap');

.eb * { box-sizing:border-box; -webkit-font-smoothing:antialiased; }
.eb { font-family:'Hanken Grotesk',-apple-system,sans-serif; background:#E9E8E5; min-height:100vh; color:${ink}; }
.eb button { font-family:inherit; color:inherit; border:none; background:none; padding:0; cursor:pointer; text-align:left; }
.eb .num { font-variant-numeric:tabular-nums; }

.eb-stage { display:flex; gap:64px; max-width:1100px; margin:0 auto; padding:56px 32px 72px; align-items:flex-start; justify-content:center; }
@media (max-width:900px){ .eb-stage{ flex-direction:column; align-items:center; gap:36px; } .eb-rail{ max-width:400px; width:100%; position:static !important; } }

.eb-rail { width:300px; flex-shrink:0; position:sticky; top:56px; }

.eb-seg { display:flex; background:rgba(0,0,0,.055); border-radius:12px; padding:3px; }
.eb-seg button { flex:1; text-align:center; font-size:13.5px; font-weight:600; padding:9px 0; border-radius:9px; color:${sub}; transition:all .2s ease; }
.eb-seg button.on { background:#fff; color:${ink}; box-shadow:0 1px 4px rgba(0,0,0,.10); }

.eb-phone { width:384px; flex-shrink:0; background:#3C3C3E; border-radius:54px; padding:10px; box-shadow:0 24px 64px rgba(0,0,0,.22); }
@media (max-width:430px){ .eb-phone{ width:100%; } }
.eb-screen { background:${canvas}; border-radius:45px; overflow:hidden; height:792px; display:flex; flex-direction:column; position:relative; }

.eb-group { background:${surface}; border-radius:18px; box-shadow:0 1px 2px rgba(0,0,0,.03); }
.eb-row { display:flex; justify-content:space-between; align-items:center; padding:15px 18px; }
.eb-row + .eb-row { border-top:1px solid ${canvas}; }

.eb-cta { display:block; width:100%; text-align:center; background:${ink}; color:#fff; font-size:16px; font-weight:600; padding:16px; border-radius:16px; transition:transform .12s ease,background .15s; }
.eb-cta:active { transform:scale(.975); background:${press}; }
.eb-cta:disabled { opacity:.3; pointer-events:none; }
.eb-quiet { display:block; width:100%; text-align:center; color:${sub}; font-size:14px; font-weight:500; padding:12px; }

.eb button:focus-visible { outline:2px solid ${pine}; outline-offset:3px; border-radius:8px; }

/* ── Animations ─── */
.fade { animation:fd .38s ease both; }
@keyframes fd { from{opacity:0;transform:translateY(6px)} to{opacity:1;transform:none} }
@keyframes breathe { 0%,100%{opacity:1} 50%{opacity:.35} }
@keyframes drawC { to{stroke-dashoffset:0} }
@keyframes route { to{stroke-dashoffset:-24} }

/* Delight A: Custody Seal */
@keyframes sealStamp {
  0%   { transform:scale(2.2) rotate(-12deg); opacity:0; }
  55%  { transform:scale(.9) rotate(3deg); opacity:1; }
  75%  { transform:scale(1.06) rotate(-1.5deg); }
  100% { transform:scale(1) rotate(0); opacity:1; }
}
.seal-stamp { animation:sealStamp .48s cubic-bezier(.34,1.56,.64,1) forwards; }

/* Delight B: Flip clock */
@keyframes flipDown {
  0%   { transform:rotateX(-90deg) translateY(-4px); opacity:0; }
  60%  { transform:rotateX(8deg) translateY(1px); opacity:1; }
  100% { transform:rotateX(0) translateY(0); opacity:1; }
}

/* Delight C: Spring events */
@keyframes springIn {
  0%   { transform:translate(28px,10px); opacity:0; }
  60%  { transform:translate(-5px,-2px); opacity:1; }
  80%  { transform:translate(2px,1px); }
  100% { transform:none; opacity:1; }
}
.spring-in { animation:springIn .44s cubic-bezier(.34,1.56,.64,1) forwards; }

/* Slide-up overlay */
@keyframes slideUp { from{transform:translateY(100%)} to{transform:translateY(0)} }
.slide-up { animation:slideUp .38s cubic-bezier(.4,0,.2,1) forwards; }

/* Notification drop */
@keyframes notifIn {
  0%   { transform:translateY(-110%) scale(.96); opacity:0; }
  100% { transform:translateY(0) scale(1); opacity:1; }
}
.notif-in { animation:notifIn .42s cubic-bezier(.34,1.56,.64,1) forwards; }

@media (prefers-reduced-motion:reduce){
  .fade,.slide-up,.spring-in,.notif-in { animation:none; }
  .eb *{ animation-duration:.001s !important; transition-duration:.001s !important; }
}

/* Presenter full-screen mode */
.eb-presenter .eb-rail { display:none; }
.eb-presenter .eb-stage { padding:0; max-width:none; justify-content:center; align-items:center; min-height:100vh; }
.eb-presenter .eb-phone { box-shadow:0 32px 80px rgba(0,0,0,.35); }
`;

/* ── Icons ────────────────────────────────────────────── */
export const I = ({ d, s = 20, c = 'currentColor', sw = 1.6 }) => (
  <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
    <path d={d} stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const ic = {
  chevR:  'M9 5l7 7-7 7',
  chevL:  'M15 19l-7-7 7-7',
  chevD:  'M6 9l6 6 6-6',
  camera: 'M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V8z M12 16a3.5 3.5 0 100-7 3.5 3.5 0 000 7z',
  box:    'M4 8l8-4 8 4v8l-8 4-8-4V8z M4 8l8 4m0 0l8-4m-8 4v8',
  check:  'M5 12.5l5 5L19 7',
  clock:  'M12 21a9 9 0 100-18 9 9 0 000 18z M12 8v4.5l3 2',
  doc:    'M7 3h7l4 4v14H7V3z M14 3v4h4',
  card:   'M3 7a2 2 0 012-2h14a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V7z M3 10h18',
  map:    'M3 6l6-3 6 3 6-3v15l-6 3-6-3-6 3V6z M9 3v15 M15 6v15',
  star:   'M12 3l2.7 5.8 6.3.7-4.7 4.3 1.3 6.2L12 16.9 6.4 20l1.3-6.2L3 9.5l6.3-.7L12 3z',
  photo:  'M4 5a2 2 0 012-2h12a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V5z M4 9h16 M9 5v4',
  x:      'M18 6L6 18M6 6l12 12',
  bag:    'M6 2l-2 5h16l-2-5H6z M4 7v13a2 2 0 002 2h12a2 2 0 002-2V7',
  dollar: 'M12 2v20M17 5H9.5a3.5 3.5 0 100 7h5a3.5 3.5 0 110 7H6',
  loc:    'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 110-5 2.5 2.5 0 010 5z',
};

/* ── Shared Primitives ────────────────────────────────── */
export const Status = () => (
  <div className="num" style={{ display:'flex', justifyContent:'space-between', padding:'16px 28px 0', fontSize:14, fontWeight:600 }}>
    <span>2:04</span><span style={{ letterSpacing:2, fontSize:11 }}>●●●</span>
  </div>
);

export const Nav = ({ title, back, trailing }) => (
  <div style={{ display:'flex', alignItems:'center', padding:'12px 20px 4px', minHeight:48 }}>
    {back
      ? <button onClick={back} aria-label="Back" style={{ padding:6, marginLeft:-6, color:ink }}><I d={ic.chevL} /></button>
      : <span style={{ width:32 }} />}
    <div style={{ flex:1, textAlign:'center', fontSize:16, fontWeight:600 }}>{title}</div>
    <span style={{ width:32, display:'flex', justifyContent:'flex-end' }}>{trailing}</span>
  </div>
);

export const DrawnCheck = ({ size = 88 }) => (
  <svg width={size} height={size} viewBox="0 0 88 88" aria-hidden>
    <circle cx="44" cy="44" r="40" fill="none" stroke={pine} strokeWidth="3"
      strokeDasharray="252" strokeDashoffset="252"
      style={{ animation:'drawC .55s ease-out forwards' }} />
    <path d="M28 45l11 11 21-24" fill="none" stroke={pine} strokeWidth="4"
      strokeLinecap="round" strokeLinejoin="round"
      strokeDasharray="50" strokeDashoffset="50"
      style={{ animation:'drawC .4s .45s ease-out forwards' }} />
  </svg>
);

/* ── Delight A: Custody Seal ──────────────────────────── */
export const Seal = ({ show, size = 40 }) => {
  if (!show) return null;
  const r = (size - 5) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} fill="none"
      className="seal-stamp" aria-hidden>
      <circle cx={size/2} cy={size/2} r={r} stroke={pine} strokeWidth="2"
        strokeDasharray={circ} strokeDashoffset={circ}
        style={{ animation:'drawC .32s ease-out forwards' }} />
      <text x={size/2} y={size/2 + size*0.14} textAnchor="middle"
        fontSize={size * 0.27} fontWeight="800" fill={pine} fontFamily="inherit"
        style={{ animation:'fd .15s .28s ease both' }}>EB</text>
    </svg>
  );
};

/* ── Delight B: Flip digit ────────────────────────────── */
const FlipDigit = ({ digit }) => {
  const animKey = useFlipDigit(digit);
  return (
    <span key={animKey} style={{
      display:'inline-block',
      animation: animKey > 0 ? 'flipDown .2s ease-out' : 'none',
      transformOrigin: 'center top',
    }}>{digit}</span>
  );
};

export const FlipNumber = ({ value, style }) => {
  const rounded = Math.round(value);
  const digits = String(rounded).split('');
  return (
    <span style={style} className="num">
      {digits.map((d, i) => <FlipDigit key={i} digit={d} />)}
    </span>
  );
};

/* ── Delight C: Spring event wrapper ─────────────────── */
export const SpringEvent = ({ isNew, children }) => (
  <div className={isNew ? 'spring-in' : 'fade'}>{children}</div>
);

/* ── Live dot ─────────────────────────────────────────── */
export const LiveDot = ({ color = pine, size = 8 }) => (
  <span style={{
    width: size, height: size, borderRadius: size,
    background: color, flexShrink: 0,
    animation: 'breathe 1.8s infinite',
    display: 'inline-block',
  }} />
);
