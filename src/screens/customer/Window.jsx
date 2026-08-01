import React, { useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic } from '../../ui.jsx';

const WINDOWS = ['12–2 pm', '2–4 pm', '4–6 pm', 'Tomorrow am'];

export default function Window({ go }) {
  const [win, setWin] = useState(1);
  const [pack, setPack] = useState(true);
  const price = pack ? 14.50 : 12.50;

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="Pickup" back={() => go('c-snap')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div style={{ fontSize:13, fontWeight:600, color:sub, margin:'4px 4px 10px' }}>Today</div>
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
          {WINDOWS.map((w, i) => (
            <button key={w} onClick={() => setWin(i)}
              style={{
                textAlign:'center', padding:'15px 0', borderRadius:14,
                fontSize:15, fontWeight:600,
                background: win === i ? ink : surface,
                color: win === i ? '#fff' : ink,
                boxShadow: '0 1px 2px rgba(0,0,0,.03)',
                transition: 'all .18s ease',
              }}>{w}</button>
          ))}
        </div>

        <button className="eb-group" onClick={() => setPack(!pack)}
          style={{ width:'100%', marginTop:14, padding:'15px 18px', display:'flex', gap:14, alignItems:'center' }}>
          <span style={{
            width:24, height:24, borderRadius:12, flexShrink:0,
            display:'grid', placeItems:'center',
            background: pack ? pine : '#E8E8EA',
            transition: 'background .2s',
          }}>
            {pack && <I d={ic.check} s={14} c="#fff" sw={2.6} />}
          </span>
          <span>
            <span style={{ display:'block', fontWeight:600, fontSize:15 }}>No box? Maya brings one.</span>
            <span style={{ display:'block', fontSize:13, color:sub, marginTop:1 }}>Hand it over as-is · adds $2</span>
          </span>
        </button>

        <div style={{ flex:1 }} />
        <div style={{ textAlign:'center', marginBottom:18 }}>
          <span className="num" style={{ fontSize:44, fontWeight:800, letterSpacing:-1.5 }}>
            ${price.toFixed(2)}
          </span>
          <div style={{ fontSize:13.5, color:sub, marginTop:2 }}>
            Flat. Door to refund. About 50 minutes of your day, kept.
          </div>
        </div>
        <button className="eb-cta" onClick={() => go('c-pay')}>Continue</button>
      </div>
    </div>
  );
}
