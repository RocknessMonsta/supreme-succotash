import React, { useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic } from '../../ui.jsx';

const STEPS = ['Address', 'Payment', 'Done'];

const dot = (active, done) => (
  <span style={{
    width: done ? 18 : active ? 18 : 8,
    height: 8, borderRadius: 8,
    background: done || active ? ink : '#D1D0CE',
    transition: 'all .25s ease',
    flexShrink: 0,
  }} />
);

export default function Onboarding({ go, onComplete }) {
  const [step, setStep] = useState(0);
  const [addr, setAddr] = useState({ line1: '', apt: '', zip: '' });
  const [cardNum, setCardNum] = useState('');

  const advance = () => {
    if (step < 2) setStep(s => s + 1);
    else { onComplete(); go('c-home'); }
  };

  const formatCard = v => {
    const d = v.replace(/\D/g, '').slice(0, 16);
    return d.replace(/(.{4})/g, '$1 ').trim();
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />

      {step === 0 && (
        <>
          <div style={{ padding:'28px 24px 8px' }}>
            <div style={{ fontSize:27, fontWeight:800, letterSpacing:-.7, lineHeight:1.15 }}>
              Where should<br />Maya come?
            </div>
            <div style={{ fontSize:14, color:sub, marginTop:8 }}>Your pickup address. One time.</div>
          </div>
          <div style={{ padding:'20px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
            <div className="eb-group">
              <div className="eb-row" style={{ padding:'0 18px' }}>
                <input
                  value={addr.line1}
                  onChange={e => setAddr(a => ({ ...a, line1: e.target.value }))}
                  placeholder="Street address"
                  style={{ flex:1, border:'none', background:'none', fontSize:15, fontWeight:500,
                    padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none' }}
                />
              </div>
              <div className="eb-row" style={{ padding:'0 18px' }}>
                <input
                  value={addr.apt}
                  onChange={e => setAddr(a => ({ ...a, apt: e.target.value }))}
                  placeholder="Apt / floor (optional)"
                  style={{ flex:1, border:'none', background:'none', fontSize:15, fontWeight:500,
                    padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none' }}
                />
              </div>
              <div className="eb-row" style={{ padding:'0 18px' }}>
                <input
                  value={addr.zip}
                  onChange={e => setAddr(a => ({ ...a, zip: e.target.value.replace(/\D/g,'').slice(0,5) }))}
                  placeholder="ZIP code"
                  inputMode="numeric"
                  style={{ flex:1, border:'none', background:'none', fontSize:15, fontWeight:500,
                    padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none' }}
                />
              </div>
            </div>
            <div style={{ fontSize:12.5, color:sub, marginTop:14, lineHeight:1.55, padding:'0 4px' }}>
              We'll only use this for pickups. No marketing, no data sales. Ever.
            </div>
            <div style={{ flex:1 }} />
            <button className="eb-cta" disabled={!addr.line1 || !addr.zip} onClick={advance}>
              Continue
            </button>
          </div>
        </>
      )}

      {step === 1 && (
        <>
          <Nav title="" back={() => setStep(0)} />
          <div style={{ padding:'12px 24px 8px' }}>
            <div style={{ fontSize:27, fontWeight:800, letterSpacing:-.7, lineHeight:1.15 }}>
              One card.<br />Never type it again.
            </div>
            <div style={{ fontSize:14, color:sub, marginTop:8 }}>Charged only when a runner accepts.</div>
          </div>
          <div style={{ padding:'20px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
            <div className="eb-group">
              <div className="eb-row" style={{ padding:'0 18px', gap:12 }}>
                <I d={ic.card} s={18} c={sub} />
                <input
                  value={cardNum}
                  onChange={e => setCardNum(formatCard(e.target.value))}
                  placeholder="Card number"
                  inputMode="numeric"
                  className="num"
                  style={{ flex:1, border:'none', background:'none', fontSize:15, fontWeight:600,
                    padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none', letterSpacing:.5 }}
                />
              </div>
              <div style={{ display:'flex' }}>
                <div className="eb-row" style={{ flex:1, padding:'0 18px' }}>
                  <input placeholder="MM / YY" inputMode="numeric"
                    style={{ width:'100%', border:'none', background:'none', fontSize:15, fontWeight:500,
                      padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none' }} />
                </div>
                <div className="eb-row" style={{ flex:1, padding:'0 18px', borderLeft:`1px solid ${canvas}` }}>
                  <input placeholder="CVV" inputMode="numeric"
                    style={{ width:'100%', border:'none', background:'none', fontSize:15, fontWeight:500,
                      padding:'17px 0', fontFamily:'inherit', color:ink, outline:'none' }} />
                </div>
              </div>
            </div>
            <div style={{ fontSize:12.5, color:sub, marginTop:14, lineHeight:1.55, padding:'0 4px' }}>
              Payments via Stripe. Your card number never touches our servers.
            </div>
            <div style={{ flex:1 }} />
            <button className="eb-cta" disabled={cardNum.replace(/\s/g,'').length < 16} onClick={advance}>
              Save card
            </button>
          </div>
        </>
      )}

      {step === 2 && (
        <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center',
          justifyContent:'center', padding:'40px 28px', textAlign:'center' }}>
          <svg width="72" height="72" viewBox="0 0 72 72" fill="none" aria-hidden>
            <circle cx="36" cy="36" r="32" fill="none" stroke={pine} strokeWidth="2.5"
              strokeDasharray="201" strokeDashoffset="201"
              style={{ animation:'drawC .5s ease-out forwards' }} />
            <path d="M23 37l10 10 16-20" fill="none" stroke={pine} strokeWidth="3.5"
              strokeLinecap="round" strokeLinejoin="round"
              strokeDasharray="42" strokeDashoffset="42"
              style={{ animation:'drawC .35s .45s ease-out forwards' }} />
          </svg>
          <div style={{ fontSize:27, fontWeight:800, letterSpacing:-.6, marginTop:28 }}>You're set.</div>
          <div style={{ fontSize:14.5, color:sub, marginTop:10, lineHeight:1.6 }}>
            Drop a return from anywhere in Chelsea.<br />Maya brings the box.
          </div>
          <button className="eb-cta" style={{ marginTop:40, width:'100%' }} onClick={advance}>
            Start returning
          </button>
        </div>
      )}

      {/* Progress dots */}
      {step < 2 && (
        <div style={{ display:'flex', gap:6, justifyContent:'center', padding:'0 0 28px' }}>
          {STEPS.slice(0,2).map((_, i) => (
            <span key={i}>{dot(i === step, i < step)}</span>
          ))}
        </div>
      )}
    </div>
  );
}
