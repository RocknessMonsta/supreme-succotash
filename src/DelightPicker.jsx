import React, { useState, useEffect, useRef } from 'react';
import { ink, sub, canvas, surface, pine } from './tokens.js';
import { I, ic, Seal, FlipNumber } from './ui.jsx';
import { useCount } from './hooks.js';

/* ── Seal Demo ─────────────────────────────────────────── */
const SealDemo = () => {
  const [stamped, setStamped] = useState(false);
  const [key, setKey] = useState(0);
  useEffect(() => {
    if (stamped) {
      const t = setTimeout(() => { setStamped(false); setKey(k => k + 1); }, 2600);
      return () => clearTimeout(t);
    }
  }, [stamped]);
  return (
    <button onClick={() => !stamped && setStamped(true)}
      style={{ width:'100%', textAlign:'center', padding:0 }}>
      <div style={{ position:'relative', display:'inline-block',
        width:100, height:68, borderRadius:12, overflow:'hidden',
        background:'linear-gradient(135deg,#2A2A2C,#1A1A1B)',
        boxShadow:'0 2px 8px rgba(0,0,0,.14)' }}>
        <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:.08 }}
          preserveAspectRatio="none" viewBox="0 0 100 100">
          {[33,67].map(x => <line key={`v${x}`} x1={x} y1="0" x2={x} y2="100" stroke="#fff" strokeWidth=".8" />)}
          {[33,67].map(y => <line key={`h${y}`} x1="0" y1={y} x2="100" y2={y} stroke="#fff" strokeWidth=".8" />)}
        </svg>
        <span style={{ position:'absolute', bottom:6, left:8,
          fontSize:9, color:'rgba(255,255,255,.4)', fontFamily:'inherit', fontWeight:600 }}>2:38</span>
        {stamped && (
          <span key={key} style={{ position:'absolute', top:6, right:6 }}>
            <Seal show size={28} />
          </span>
        )}
      </div>
      <div style={{ fontSize:11.5, color: stamped ? pine : sub, fontWeight:600, marginTop:7,
        transition:'color .2s' }}>
        {stamped ? 'Custody sealed' : 'Tap to seal →'}
      </div>
    </button>
  );
};

/* ── Flip Demo ─────────────────────────────────────────── */
const FlipDemo = () => {
  const [val, setVal] = useState(48);
  const dir = useRef(1);
  useEffect(() => {
    const t = setInterval(() => {
      setVal(v => {
        const next = v + dir.current;
        if (next >= 52) dir.current = -1;
        if (next <= 48) dir.current = 1;
        return next;
      });
    }, 700);
    return () => clearInterval(t);
  }, []);
  return (
    <div style={{ textAlign:'center' }}>
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'center', gap:3 }}>
        <FlipNumber value={val} style={{ fontSize:36, fontWeight:800, letterSpacing:-1.2, color:ink }} />
        <span style={{ fontSize:15, fontWeight:700, color:sub }}>min</span>
      </div>
      <div style={{ fontSize:11.5, color:sub, fontWeight:600, marginTop:6 }}>
        returned to your day
      </div>
    </div>
  );
};

/* ── Spring Demo ───────────────────────────────────────── */
const SPRING_EVENTS = ['Runner matched', 'Picked up', 'Refund initiated'];
const SpringDemo = () => {
  const [shown, setShown] = useState(0);
  const [key, setKey] = useState(0);
  useEffect(() => {
    if (shown < SPRING_EVENTS.length) {
      const t = setTimeout(() => setShown(s => s + 1), 700);
      return () => clearTimeout(t);
    } else {
      const t = setTimeout(() => { setShown(0); setKey(k => k + 1); }, 1800);
      return () => clearTimeout(t);
    }
  }, [shown]);
  return (
    <div>
      {SPRING_EVENTS.map((e, i) => (
        <div key={`${key}-${i}`}
          style={{
            display:'flex', alignItems:'center', gap:8, marginBottom:6,
            opacity: i < shown ? 1 : 0,
            animation: i < shown ? `springIn .42s cubic-bezier(.34,1.56,.64,1) ${0}ms both` : 'none',
          }}>
          <span style={{ width:7, height:7, borderRadius:7, background: i === 2 ? pine : '#C9C8C5', flexShrink:0 }} />
          <span style={{ fontSize:12.5, fontWeight: i === shown - 1 ? 700 : 500, color: i === 2 ? pine : ink }}>
            {e}
          </span>
        </div>
      ))}
    </div>
  );
};

/* ── Picker ────────────────────────────────────────────── */
const OPTIONS = [
  {
    key: 'seal',
    name: 'Custody seal',
    desc: 'Proof moments stamp with an EB mark. The delight is the moat.',
    Demo: SealDemo,
  },
  {
    key: 'flip',
    name: 'Flip clock',
    desc: 'Time counted back in tumbling digits. Numbers are the brand.',
    Demo: FlipDemo,
  },
  {
    key: 'spring',
    name: 'Spring tracking',
    desc: 'Events arrive with physics. The tracking screen is the star.',
    Demo: SpringDemo,
  },
];

export default function DelightPicker({ current, onChange }) {
  const [open, setOpen] = useState(false);

  return (
    <div style={{ marginTop:20 }}>
      <button onClick={() => setOpen(o => !o)}
        style={{ display:'flex', alignItems:'center', gap:6,
          fontSize:13, fontWeight:600, color:sub }}>
        <span style={{ fontSize:14 }}>◐</span>
        Delight style
        <span style={{ transform: open ? 'rotate(180deg)' : 'none', transition:'transform .2s',
          display:'inline-flex' }}>
          <I d={ic.chevD} s={14} c={sub} />
        </span>
      </button>

      {open && (
        <div style={{ marginTop:14 }}>
          {OPTIONS.map(({ key, name, desc, Demo }) => {
            const selected = current === key;
            return (
              <div key={key}
                style={{
                  borderRadius:14, padding:'14px 14px',
                  background: selected ? `rgba(14,107,79,.07)` : surface,
                  boxShadow: selected
                    ? `inset 0 0 0 1.5px ${pine}`
                    : '0 1px 2px rgba(0,0,0,.04)',
                  marginBottom:10, transition:'all .18s ease',
                }}>
                <div style={{ marginBottom:11 }}>
                  <Demo />
                </div>
                <div style={{ fontSize:13, fontWeight:700, marginBottom:2,
                  color: selected ? pine : ink }}>{name}</div>
                <div style={{ fontSize:12, color:sub, lineHeight:1.5, marginBottom:10 }}>{desc}</div>
                <button
                  onClick={() => { onChange(key); localStorage.setItem('eb_delight', key); }}
                  style={{
                    fontSize:12.5, fontWeight:700, padding:'7px 14px', borderRadius:9,
                    background: selected ? pine : '#EEEEED', color: selected ? '#fff' : sub,
                    transition:'all .18s',
                  }}>
                  {selected ? 'Active' : 'Use this'}
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
