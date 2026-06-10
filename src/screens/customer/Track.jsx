import React, { useState, useEffect } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic, Seal, SpringEvent } from '../../ui.jsx';
import { STEPS } from '../../data.js';
import CustodyViewer from './CustodyViewer.jsx';

export default function Track({ go, stage, delight }) {
  const seen = STEPS.slice(0, stage);
  const done = stage >= STEPS.length;
  const [custodyOpen, setCustodyOpen] = useState(false);
  const [newIdx, setNewIdx] = useState(-1);

  useEffect(() => {
    if (stage > 0) {
      setNewIdx(stage - 1);
      const t = setTimeout(() => setNewIdx(-1), 700);
      return () => clearTimeout(t);
    }
  }, [stage]);

  const dotX = stage < 3 ? 58 : stage < 5 ? 178 : 298;
  const dotY = stage < 3 ? 86  : stage < 5 ? 56  : 24;

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title={done ? 'Returned' : 'In progress'} back={() => go('c-home')} />

      {/* Route map */}
      <div style={{ margin:'4px 20px 0', borderRadius:18, overflow:'hidden', background:surface,
        boxShadow:'0 1px 2px rgba(0,0,0,.03)' }}>
        <svg viewBox="0 0 344 132" width="100%" aria-hidden style={{ display:'block' }}>
          {[24,56,88,120].map(y => <line key={y} x1="0" y1={y} x2="344" y2={y} stroke={canvas} strokeWidth="5" />)}
          {[58,138,218,298].map(x => <line key={x} x1={x} y1="0" x2={x} y2="132" stroke={canvas} strokeWidth="5" />)}
          <path d="M58 108 L58 56 L218 56 L218 24 L298 24" fill="none" stroke={ink} strokeWidth="2.5"
            strokeLinecap="round" strokeDasharray="9 15"
            style={{ animation: done ? 'none' : 'route 1.4s linear infinite' }} />
          <circle cx="58" cy="108" r="5.5" fill={ink} />
          <circle cx="298" cy="24" r="5.5" fill="none" stroke={ink} strokeWidth="2.5" />
          {!done && (
            <>
              {delight === 'spring' && (
                <circle r="14" fill={pine} opacity=".12"
                  style={{ transform:`translate(${dotX}px,${dotY}px)`, transition:'transform 1.4s ease',
                    animation:'breathe 1.8s infinite' }} />
              )}
              <circle r="7" fill={pine}
                style={{ transform:`translate(${dotX}px,${dotY}px)`, transition:'transform 1.4s ease' }} />
            </>
          )}
          <text x="58" y="126" textAnchor="middle" fontSize="10" fontWeight="600"
            fill={sub} fontFamily="inherit">Home</text>
          <text x="298" y="14" textAnchor="middle" fontSize="10" fontWeight="600"
            fill={sub} fontFamily="inherit">UPS</text>
        </svg>
      </div>

      {/* Event timeline */}
      <div style={{ padding:'22px 28px 28px' }}>
        {seen.map((s, i) => {
          const last = i === seen.length - 1;
          const isNew = delight === 'spring' && i === newIdx;
          const node = (
            <div style={{ display:'flex', gap:16, position:'relative',
              paddingBottom: last ? 0 : 22 }}>
              {!last && (
                <span style={{ position:'absolute', left:4.5, top:18, bottom:2,
                  width:1.5, background:'#E3E2DF' }} />
              )}
              <span style={{
                width:11, height:11, borderRadius:11, marginTop:4, flexShrink:0,
                background: s.money ? pine : last && !done ? ink : '#C9C8C5',
                outline: last && !done ? `4px solid rgba(22,22,23,.08)` : 'none',
                position: 'relative',
              }}>
                {delight === 'seal' && s.proof && (
                  <span style={{ position:'absolute', left:-6, top:-6 }}>
                    <Seal show size={22} />
                  </span>
                )}
              </span>
              <div style={{ flex:1 }}>
                <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
                  <span style={{ fontSize:15.5, fontWeight: last ? 700 : 600,
                    color: s.money ? pine : ink }}>{s.title}</span>
                  <span className="num" style={{ fontSize:13, color:sub }}>{s.t}</span>
                </div>
                <div style={{ fontSize:13.5, color:sub, marginTop:2 }}>{s.sub}</div>
                {s.proof && (
                  <button onClick={() => setCustodyOpen(true)}
                    style={{ fontSize:13.5, fontWeight:600, color:pine, marginTop:6 }}>
                    View photo proof
                  </button>
                )}
              </div>
            </div>
          );
          return <SpringEvent key={s.title} isNew={isNew}>{node}</SpringEvent>;
        })}
        {!done && (
          <div style={{ fontSize:13, color:sub, paddingLeft:27, paddingTop:14,
            animation:'breathe 1.8s infinite' }}>Updating…</div>
        )}
        {done && (
          <button className="eb-cta fade" style={{ marginTop:26 }} onClick={() => go('c-done')}>
            Done
          </button>
        )}
      </div>

      {custodyOpen && <CustodyViewer onClose={() => setCustodyOpen(false)} delight={delight} />}
    </div>
  );
}
