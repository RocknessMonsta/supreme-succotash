import React, { useState } from 'react';
import { ink, sub, pine } from '../../tokens.js';
import { Status, DrawnCheck, I, ic, FlipNumber } from '../../ui.jsx';
import { useCount } from '../../hooks.js';

export default function Done({ go, onReset, delight }) {
  const mins = useCount(52, true, 1600);
  const [stars, setStars] = useState(5);

  const MinDisplay = () => {
    if (delight === 'flip') {
      return (
        <div style={{ display:'flex', alignItems:'baseline', gap:0, marginTop:26, lineHeight:1 }}>
          <FlipNumber value={mins} style={{ fontSize:58, fontWeight:800, letterSpacing:-2 }} />
          <span style={{ fontSize:20, fontWeight:700, color:sub, marginLeft:6 }}>min</span>
        </div>
      );
    }
    return (
      <div className="num" style={{ fontSize:58, fontWeight:800, letterSpacing:-2, marginTop:26, lineHeight:1 }}>
        {Math.round(mins)}<span style={{ fontSize:20, fontWeight:700, color:sub, marginLeft:4 }}>min</span>
      </div>
    );
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto', textAlign:'center' }}>
      <Status />
      <div style={{ padding:'44px 28px 28px', flex:1, display:'flex', flexDirection:'column', alignItems:'center' }}>
        <DrawnCheck />
        <MinDisplay />
        <div style={{ fontSize:17, fontWeight:600, marginTop:8 }}>returned to your day.</div>
        <div style={{ fontSize:14, color:sub, marginTop:14, lineHeight:1.55 }}>
          Nordstrom has your sneakers.<br />
          <span style={{ color:pine, fontWeight:600 }}>$149.95</span> is on its way back —
          we'll tell you when it lands.
        </div>

        <div style={{ marginTop:40 }}>
          <div style={{ fontSize:14, fontWeight:600 }}>How was Maya?</div>
          <div style={{ display:'flex', gap:4, marginTop:10, justifyContent:'center' }}
            role="radiogroup" aria-label="Rate Maya">
            {[1,2,3,4,5].map(n => (
              <button key={n} onClick={() => setStars(n)} aria-label={`${n} of 5`}
                style={{ padding:4 }}>
                <svg width="28" height="28" viewBox="0 0 24 24"
                  fill={n <= stars ? ink : 'none'}>
                  <path d="M12 3l2.7 5.8 6.3.7-4.7 4.3 1.3 6.2L12 16.9 6.4 20l1.3-6.2L3 9.5l6.3-.7L12 3z"
                    stroke={n <= stars ? ink : '#C9C8C5'} strokeWidth="1.5" strokeLinejoin="round" />
                </svg>
              </button>
            ))}
          </div>
        </div>

        <div style={{ flex:1 }} />
        <button className="eb-cta" style={{ width:'100%' }}
          onClick={() => { onReset(); go('c-home'); }}>
          Done
        </button>
      </div>
    </div>
  );
}
