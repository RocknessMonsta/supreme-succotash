import React, { useEffect, useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { I, ic, Seal } from '../../ui.jsx';
import { CUSTODY_RECORDS } from '../../data.js';

const SimPhoto = ({ index }) => {
  const gradients = [
    'radial-gradient(ellipse at 30% 40%, #3A3A3C, #1A1A1B)',
    'radial-gradient(ellipse at 60% 30%, #2E2E30, #141415)',
    'radial-gradient(ellipse at 50% 60%, #333335, #1C1C1E)',
  ];
  return (
    <div style={{
      width:'100%', height:140, borderRadius:14,
      background: gradients[index % gradients.length],
      position:'relative', overflow:'hidden', flexShrink:0,
    }}>
      <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:.07 }}
        preserveAspectRatio="none" viewBox="0 0 100 100">
        {[33,67].map(x => <line key={`v${x}`} x1={x} y1="0" x2={x} y2="100" stroke="#fff" strokeWidth=".5" />)}
        {[33,67].map(y => <line key={`h${y}`} x1="0" y1={y} x2="100" y2={y} stroke="#fff" strokeWidth=".5" />)}
      </svg>
      <span style={{ position:'absolute', bottom:10, left:12, fontSize:10.5, fontWeight:600,
        color:'rgba(255,255,255,.5)', fontFamily:'inherit' }}>
        {CUSTODY_RECORDS[index]?.t}
      </span>
    </div>
  );
};

export default function CustodyViewer({ onClose, delight }) {
  const [seals, setSeals] = useState([]);

  useEffect(() => {
    if (delight === 'seal') {
      CUSTODY_RECORDS.forEach((_, i) => {
        setTimeout(() => setSeals(s => [...s, i]), i * 320 + 200);
      });
    }
  }, [delight]);

  return (
    <div style={{
      position:'absolute', inset:0, zIndex:20,
      background:canvas, display:'flex', flexDirection:'column',
    }} className="slide-up">
      {/* Header */}
      <div style={{ display:'flex', alignItems:'center', padding:'20px 20px 0', gap:12 }}>
        <button onClick={onClose} aria-label="Close"
          style={{ width:32, height:32, display:'grid', placeItems:'center', color:ink }}>
          <I d={ic.x} s={20} />
        </button>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:16, fontWeight:700 }}>Chain of custody</div>
          <div style={{ fontSize:12.5, color:sub, marginTop:1 }}>Bag 8841 · NORD-448291</div>
        </div>
        <div style={{ fontSize:11, fontWeight:600, color:pine }}>3 records</div>
      </div>

      {/* Records */}
      <div style={{ flex:1, overflowY:'auto', padding:'20px 20px 32px' }}>
        {CUSTODY_RECORDS.map((r, i) => (
          <div key={r.label} className="fade"
            style={{ marginBottom: i < CUSTODY_RECORDS.length - 1 ? 24 : 0,
              animationDelay: `${i * 80}ms` }}>
            <SimPhoto index={i} />
            <div style={{ marginTop:10, display:'flex', alignItems:'flex-start', justifyContent:'space-between' }}>
              <div>
                <div style={{ fontSize:14.5, fontWeight:700 }}>{r.label}</div>
                <div style={{ fontSize:13, color:sub, marginTop:2 }}>{r.addr}</div>
                <div className="num" style={{ fontSize:12, color:sub, marginTop:3 }}>
                  Bag {r.bag} · {r.t}
                </div>
              </div>
              <div style={{ display:'flex', alignItems:'center', gap:6, marginTop:2 }}>
                {delight === 'seal' ? (
                  <span style={{ opacity: seals.includes(i) ? 1 : 0, transition:'opacity .2s' }}>
                    <Seal show={seals.includes(i)} size={36} />
                  </span>
                ) : (
                  <span style={{ display:'flex', alignItems:'center', gap:5, fontSize:12,
                    fontWeight:600, color:pine }}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                      <path d="M5 13l4 4L19 7" stroke={pine} strokeWidth="2.2"
                        strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                    Verified
                  </span>
                )}
              </div>
            </div>
            <div style={{ marginTop:8, padding:'8px 12px', background:'rgba(14,107,79,.06)',
              borderRadius:8, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
              <span style={{ fontSize:11.5, color:pine, fontWeight:600 }}>Hash</span>
              <span className="num" style={{ fontSize:11, color:sub }}>{r.hash}</span>
            </div>
            {i < CUSTODY_RECORDS.length - 1 && (
              <div style={{ width:2, height:20, background:'#E3E2DF', margin:'12px auto 0' }} />
            )}
          </div>
        ))}

        <div style={{ marginTop:24, padding:'14px 16px', background:surface, borderRadius:14,
          boxShadow:'0 1px 2px rgba(0,0,0,.03)' }}>
          <div style={{ fontSize:13, fontWeight:700, marginBottom:4 }}>This record is permanent</div>
          <div style={{ fontSize:12.5, color:sub, lineHeight:1.6 }}>
            Every handoff is timestamped, hashed, and stored independently of the return outcome.
            Retailers license this audit trail — it's the asset under the service.
          </div>
        </div>
      </div>
    </div>
  );
}
