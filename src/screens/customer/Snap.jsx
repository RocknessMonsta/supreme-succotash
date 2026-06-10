import React, { useState, useEffect } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic, Seal } from '../../ui.jsx';
import { ITEM } from '../../data.js';

export default function Snap({ go, delight }) {
  const [shots, setShots] = useState(0);
  const [read, setRead] = useState(false);
  const [sealShown, setSealShown] = useState([false, false]);

  useEffect(() => {
    if (shots === 2) {
      const t = setTimeout(() => setRead(true), 1100);
      return () => clearTimeout(t);
    }
  }, [shots]);

  const capturePhoto = (i) => {
    setShots(i + 1);
    if (delight === 'seal') {
      setTimeout(() => {
        setSealShown(s => { const n = [...s]; n[i] = true; return n; });
      }, 180);
    }
  };

  const Frame = ({ i, label }) => {
    const done = shots > i;
    const activeF = shots === i;
    return (
      <button
        onClick={() => activeF && capturePhoto(i)}
        aria-label={label}
        style={{
          flex:1, height:175, borderRadius:18, position:'relative', overflow:'hidden',
          background: done ? 'linear-gradient(150deg,#2A2A2C,#1A1A1B)' : surface,
          boxShadow: activeF ? `inset 0 0 0 2px ${ink}` : '0 1px 2px rgba(0,0,0,.03)',
          display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:10,
          transition:'all .28s ease',
        }}>
        {done ? (
          <>
            <span style={{ position:'absolute', inset:0,
              background:'radial-gradient(120px 80px at 35% 30%, rgba(255,255,255,.12), transparent)' }} />
            {/* Grid lines to simulate a real photo */}
            <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:.08 }}
              preserveAspectRatio="none" viewBox="0 0 100 100">
              {[33,67].map(x => <line key={`v${x}`} x1={x} y1="0" x2={x} y2="100" stroke="#fff" strokeWidth=".5" />)}
              {[33,67].map(y => <line key={`h${y}`} x1="0" y1={y} x2="100" y2={y} stroke="#fff" strokeWidth=".5" />)}
            </svg>
            {delight === 'seal' && sealShown[i] ? (
              <span style={{ position:'absolute', top:10, right:10 }}>
                <Seal show size={38} />
              </span>
            ) : (
              <span style={{ position:'absolute', top:12, right:12, width:24, height:24, borderRadius:12,
                background:'#fff', display:'grid', placeItems:'center' }}>
                <I d={ic.check} s={14} c={pine} sw={2.4} />
              </span>
            )}
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
        <div style={{ fontSize:22, fontWeight:700, letterSpacing:-.4, padding:'4px 4px 16px' }}>
          Two photos.<br />We handle the rest.
        </div>
        <div style={{ display:'flex', gap:12 }}>
          <Frame i={0} label="The item" />
          <Frame i={1} label="The label" />
        </div>

        {shots === 2 && !read && (
          <div className="fade" style={{ marginTop:20, fontSize:14, color:sub, textAlign:'center' }}>
            {delight === 'seal' ? 'Sealing record…' : 'Reading label…'}
          </div>
        )}

        {read && (
          <div className="eb-group fade" style={{ marginTop:20 }}>
            {[
              ['Retailer', ITEM.retailer, false],
              ['Item',     ITEM.item,     false],
              ['Order',    ITEM.order,    false],
              ['Refund due', `$${ITEM.refund}`, true],
            ].map(([k, v, money], idx) => (
              <div key={k} className="eb-row"
                style={{
                  padding:'13px 18px',
                  animation: delight === 'spring'
                    ? `springIn .42s cubic-bezier(.34,1.56,.64,1) ${idx * 80}ms both`
                    : undefined,
                }}>
                <span style={{ fontSize:14.5, color:sub }}>{k}</span>
                <span className="num" style={{ fontSize:14.5, fontWeight:600, color: money ? pine : ink }}>{v}</span>
              </div>
            ))}
          </div>
        )}

        <div style={{ flex:1 }} />
        <button className="eb-cta" disabled={!read} onClick={() => read && go('c-window')}>Continue</button>
      </div>
    </div>
  );
}
