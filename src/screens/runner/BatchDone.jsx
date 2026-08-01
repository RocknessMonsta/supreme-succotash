import React from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Status, DrawnCheck, I, ic, FlipNumber, LiveDot } from '../../ui.jsx';
import { useCount } from '../../hooks.js';
import { BATCH_STOPS } from '../../data.js';

export default function BatchDone({ go, onReset, delight }) {
  const earn = useCount(38.40, true, 1400);

  const EarnDisplay = () => {
    if (delight === 'flip') {
      return (
        <div style={{ display:'flex', alignItems:'flex-start', gap:2, justifyContent:'center', marginTop:24 }}>
          <span style={{ fontSize:28, fontWeight:700, color:pine, marginTop:10 }}>$</span>
          <FlipNumber value={earn} style={{ fontSize:64, fontWeight:800, letterSpacing:-2, color:pine, lineHeight:1 }} />
        </div>
      );
    }
    return (
      <div className="num" style={{ fontSize:64, fontWeight:800, letterSpacing:-2, color:pine,
        lineHeight:1, marginTop:24 }}>
        ${earn.toFixed(2)}
      </div>
    );
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto', textAlign:'center' }}>
      <Status />
      <div style={{ padding:'44px 28px 28px', flex:1, display:'flex', flexDirection:'column', alignItems:'center' }}>
        <DrawnCheck />
        <EarnDisplay />
        <div style={{ fontSize:16, fontWeight:600, marginTop:6 }}>batch complete.</div>
        <div style={{ fontSize:13.5, color:sub, marginTop:8 }}>
          2.6 mi loop · 4 returns · 58 min
        </div>

        {/* Route complete dots */}
        <div style={{ display:'flex', alignItems:'center', gap:0, marginTop:32 }}>
          {BATCH_STOPS.map((s, i) => (
            <React.Fragment key={s.addr}>
              <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:5 }}>
                <div style={{ width:10, height:10, borderRadius:10,
                  background: i === BATCH_STOPS.length - 1 ? pine : ink }} />
                <div style={{ fontSize:10.5, color:sub, fontWeight:600, maxWidth:56, textAlign:'center', lineHeight:1.3 }}>
                  {i === BATCH_STOPS.length - 1 ? 'UPS' : s.name}
                </div>
              </div>
              {i < BATCH_STOPS.length - 1 && (
                <div style={{ height:1.5, width:28, background:'#D1D0CE', marginBottom:14 }} />
              )}
            </React.Fragment>
          ))}
        </div>

        {/* Payout breakdown */}
        <div style={{ width:'100%', background:surface, borderRadius:18,
          boxShadow:'0 1px 2px rgba(0,0,0,.03)', marginTop:28, textAlign:'left' }}>
          {[
            ['4 pickups',    '$28.00'],
            ['UPS drop-off', '$4.40' ],
            ['Packaging ×1', '$3.60' ],
            ['Tip (avg)',     '$2.40' ],
          ].map(([k, v], i, a) => (
            <div key={k} style={{ display:'flex', justifyContent:'space-between',
              padding:'13px 18px',
              borderBottom: i < a.length - 1 ? `1px solid ${canvas}` : 'none' }}>
              <span style={{ fontSize:14.5, color:sub }}>{k}</span>
              <span className="num" style={{ fontSize:14.5, fontWeight:600 }}>{v}</span>
            </div>
          ))}
        </div>

        <div style={{ marginTop:18, display:'flex', alignItems:'center', gap:8,
          fontSize:13.5, fontWeight:600, color:pine }}>
          <LiveDot />
          Sent to Venmo · now
        </div>

        <div style={{ flex:1 }} />
        <button className="eb-cta" style={{ width:'100%' }}
          onClick={() => { onReset(); go('r-feed'); }}>
          Back to offers
        </button>
      </div>
    </div>
  );
}
