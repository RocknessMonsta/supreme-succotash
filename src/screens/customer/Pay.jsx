import React, { useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic } from '../../ui.jsx';
import { ITEM } from '../../data.js';

export default function Pay({ go, onConfirm }) {
  const [paying, setPaying] = useState(false);

  const handlePay = () => {
    setPaying(true);
    // Integration seam: replace setTimeout with Stripe.confirmPayment() call
    setTimeout(() => { onConfirm(); go('c-track'); }, 1200);
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title="Confirm" back={() => go('c-window')} />
      <div style={{ padding:'8px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        <div className="eb-group">
          {[
            ['Return',        `${ITEM.retailer} · ${ITEM.item}`, false],
            ['Pickup',        'Today, 2–4 pm · your door',       false],
            ['Drop-off',      'UPS, Midtown',                    false],
            ['Refund tracked', `$${ITEM.refund}`,                true ],
          ].map(([k, v, money]) => (
            <div className="eb-row" key={k} style={{ padding:'14px 18px' }}>
              <span style={{ fontSize:14.5, color:sub, flexShrink:0 }}>{k}</span>
              <span className="num" style={{ fontSize:14.5, fontWeight:600, textAlign:'right',
                color: money ? pine : ink }}>{v}</span>
            </div>
          ))}
        </div>

        <div className="eb-group eb-row" style={{ marginTop:12, padding:'14px 18px' }}>
          <span style={{ display:'flex', alignItems:'center', gap:10, fontSize:14.5, fontWeight:600 }}>
            <I d={ic.card} s={18} c={sub} /> Visa 4421
          </span>
          <span style={{ fontSize:13.5, color:sub }}>Change</span>
        </div>

        <div style={{ flex:1 }} />

        <button className="eb-cta" disabled={paying} onClick={handlePay}>
          {paying ? 'Finding your runner…' : 'Pay $14.50'}
        </button>
        <div className="eb-quiet" style={{ cursor:'default' }}>
          Cancel free until Maya is en route
        </div>
      </div>
    </div>
  );
}
