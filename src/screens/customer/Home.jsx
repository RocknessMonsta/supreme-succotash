import React, { useEffect, useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Status, I, ic, LiveDot, FlipNumber } from '../../ui.jsx';
import { useCount } from '../../hooks.js';
import { PAST_RETURNS } from '../../data.js';

export default function Home({ go, active, refundLanded, delight }) {
  const hrs = useCount(11.5, true, 1600);
  const [notifVisible, setNotifVisible] = useState(false);

  useEffect(() => {
    if (refundLanded) {
      const t = setTimeout(() => setNotifVisible(true), 600);
      return () => clearTimeout(t);
    } else {
      setNotifVisible(false);
    }
  }, [refundLanded]);

  const HoursDisplay = () => {
    if (delight === 'flip') {
      return (
        <div style={{ display:'flex', alignItems:'baseline', gap:6, marginTop:2 }}>
          <FlipNumber value={hrs} style={{ fontSize:64, fontWeight:800, letterSpacing:-2.5, lineHeight:1.05 }} />
          <span style={{ fontSize:28, fontWeight:700, color:sub }}>hours</span>
        </div>
      );
    }
    return (
      <div className="num" style={{ fontSize:64, fontWeight:800, letterSpacing:-2.5, lineHeight:1.05, marginTop:2 }}>
        {hrs.toFixed(1)}<span style={{ fontSize:28, fontWeight:700, letterSpacing:0, marginLeft:6, color:sub }}>hours</span>
      </div>
    );
  };

  return (
    <div className="fade" style={{ flex:1, overflow:'auto', position:'relative' }}>
      <Status />

      {/* Refund notification banner */}
      {notifVisible && (
        <button
          className="notif-in"
          onClick={() => go('c-refund')}
          style={{
            position:'absolute', top:52, left:16, right:16, zIndex:10,
            background:surface, borderRadius:16, padding:'13px 16px',
            display:'flex', alignItems:'center', gap:12,
            boxShadow:'0 4px 24px rgba(0,0,0,.12)',
          }}>
          <span style={{ width:36, height:36, borderRadius:12, background:pine,
            display:'grid', placeItems:'center', flexShrink:0 }}>
            <I d={ic.dollar} s={18} c="#fff" sw={1.8} />
          </span>
          <div style={{ flex:1, textAlign:'left' }}>
            <div style={{ fontSize:13.5, fontWeight:700 }}>Nordstrom refund landed</div>
            <div style={{ fontSize:12.5, color:sub, marginTop:1 }}>$149.95 confirmed in your account</div>
          </div>
          <I d={ic.chevR} s={16} c={sub} />
        </button>
      )}

      <div style={{ padding:'26px 24px 8px', marginTop: notifVisible ? 64 : 0, transition:'margin-top .3s ease' }}>
        <div style={{ fontSize:14, fontWeight:600, color:sub }}>Returned to you</div>
        <HoursDisplay />
        <div style={{ fontSize:14, color:sub, marginTop:6 }}>
          14 returns this year · <span style={{ color:pine, fontWeight:600 }}>$1,872 refunded</span>
        </div>
      </div>

      <div style={{ padding:'20px 20px 28px' }}>
        {active ? (
          <button className="eb-group" onClick={() => go('c-track')}
            style={{ width:'100%', padding:'17px 18px', display:'flex', alignItems:'center', gap:14 }}>
            <LiveDot />
            <span style={{ flex:1 }}>
              <span style={{ display:'block', fontWeight:600, fontSize:15 }}>Nordstrom return in progress</span>
              <span style={{ display:'block', fontSize:13, color:sub, marginTop:1 }}>Maya picks up 2–4 pm today</span>
            </span>
            <I d={ic.chevR} s={18} c={sub} />
          </button>
        ) : (
          <button className="eb-cta" onClick={() => go('c-snap')}>Return something</button>
        )}

        <div style={{ fontSize:13, fontWeight:600, color:sub, margin:'26px 4px 10px' }}>Past returns</div>
        <div className="eb-group">
          {PAST_RETURNS.map(({ retailer, item, amt }) => (
            <div className="eb-row" key={item}>
              <div>
                <div style={{ fontWeight:600, fontSize:15 }}>{retailer}</div>
                <div style={{ fontSize:13, color:sub, marginTop:1 }}>{item}</div>
              </div>
              <div className="num" style={{ fontSize:15, fontWeight:600, color:pine }}>${amt.toFixed(2)}</div>
            </div>
          ))}
        </div>
        <div style={{ textAlign:'center', fontSize:12.5, color:sub, marginTop:18 }}>
          Every refund above arrived. We track them until they do.
        </div>
      </div>
    </div>
  );
}
