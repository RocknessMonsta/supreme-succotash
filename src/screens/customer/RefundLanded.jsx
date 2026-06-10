import React, { useEffect } from 'react';
import { ink, sub, pine } from '../../tokens.js';
import { Status, I, ic, FlipNumber } from '../../ui.jsx';
import { useCount } from '../../hooks.js';

export default function RefundLanded({ go, onAcknowledge, delight }) {
  const amount = useCount(149.95, true, 1200);

  useEffect(() => {
    return () => onAcknowledge?.();
  }, []);

  const AmountDisplay = () => {
    if (delight === 'flip') {
      return (
        <div style={{ display:'flex', alignItems:'flex-start', gap:2, justifyContent:'center', marginTop:24 }}>
          <span style={{ fontSize:28, fontWeight:700, color:pine, marginTop:8 }}>$</span>
          <FlipNumber value={amount} style={{ fontSize:64, fontWeight:800, letterSpacing:-2, color:pine, lineHeight:1 }} />
        </div>
      );
    }
    return (
      <div className="num" style={{ fontSize:64, fontWeight:800, letterSpacing:-2, color:pine,
        lineHeight:1, marginTop:24 }}>
        ${Math.round(amount * 100) / 100 < 149.95
          ? amount.toFixed(0)
          : '149.95'}
      </div>
    );
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto', textAlign:'center' }}>
      <Status />
      <div style={{ padding:'52px 28px 28px', flex:1, display:'flex', flexDirection:'column', alignItems:'center' }}>
        {/* Animated money icon */}
        <div style={{ width:80, height:80, borderRadius:24, background:pine,
          display:'grid', placeItems:'center', boxShadow:'0 8px 32px rgba(14,107,79,.28)' }}>
          <svg width="38" height="38" viewBox="0 0 24 24" fill="none">
            <path d="M12 2v20M17 5H9.5a3.5 3.5 0 100 7h5a3.5 3.5 0 110 7H6"
              stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
              strokeDasharray="60" strokeDashoffset="60"
              style={{ animation:'drawC .5s .15s ease-out forwards' }} />
          </svg>
        </div>

        <AmountDisplay />
        <div style={{ fontSize:13, color:sub, marginTop:4 }}>landed in your account</div>

        <div style={{ marginTop:32, textAlign:'left', width:'100%' }}>
          <div style={{ fontSize:13, fontWeight:600, color:sub, marginBottom:10 }}>Details</div>
          <div style={{ background:'#fff', borderRadius:18, boxShadow:'0 1px 2px rgba(0,0,0,.03)' }}>
            {[
              ['From',   'Nordstrom'],
              ['Order',  'NORD-448291'],
              ['Method', 'Original card'],
              ['Arrived','Today, 3:47 pm'],
            ].map(([k, v]) => (
              <div key={k} style={{ display:'flex', justifyContent:'space-between',
                padding:'13px 18px', borderBottom:`1px solid #F5F4F2` }}>
                <span style={{ fontSize:14.5, color:sub }}>{k}</span>
                <span style={{ fontSize:14.5, fontWeight:600 }}>{v}</span>
              </div>
            ))}
            <div style={{ display:'flex', justifyContent:'space-between', padding:'13px 18px' }}>
              <span style={{ fontSize:14.5, color:sub }}>Return time</span>
              <span className="num" style={{ fontSize:14.5, fontWeight:600, color:pine }}>52 min total</span>
            </div>
          </div>
        </div>

        <div style={{ fontSize:13, color:sub, lineHeight:1.6, marginTop:20 }}>
          We tracked this refund for 3 days.<br />Most apps stop at the carrier scan. We don't.
        </div>

        <div style={{ flex:1 }} />
        <button className="eb-cta" style={{ width:'100%' }} onClick={() => go('c-home')}>
          Back home
        </button>
      </div>
    </div>
  );
}
