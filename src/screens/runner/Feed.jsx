import React from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Status, I, ic, LiveDot } from '../../ui.jsx';
import { useCount } from '../../hooks.js';
import { BATCH_STOPS } from '../../data.js';

export default function Feed({ go }) {
  const earn = useCount(86, true, 1200);

  return (
    <div className="fade" style={{ flex:1, overflow:'auto' }}>
      <Status />
      <div style={{ padding:'24px 24px 8px', display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
        <div>
          <div style={{ fontSize:14, color:sub, fontWeight:600 }}>Today, Chelsea zone</div>
          <div className="num" style={{ fontSize:46, fontWeight:800, letterSpacing:-1.5, lineHeight:1.1 }}>
            ${Math.round(earn)}
          </div>
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:7, fontSize:13.5, fontWeight:600,
          color:pine, paddingBottom:8 }}>
          <LiveDot />Online
        </div>
      </div>

      <div style={{ padding:'14px 20px 28px' }}>
        {/* Featured batch */}
        <div className="eb-group" style={{ padding:'20px 20px 18px' }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
            <div style={{ fontSize:17, fontWeight:700 }}>Batch of 4 · one UPS run</div>
            <div className="num" style={{ fontSize:20, fontWeight:800 }}>$38.40</div>
          </div>
          <div style={{ fontSize:13.5, color:sub, marginTop:3 }}>
            2.6 mi loop · about 55 min ·{' '}
            <span style={{ color:pine, fontWeight:600 }}>$42/hr</span>
          </div>

          {/* Stop preview */}
          <div style={{ marginTop:16 }}>
            {BATCH_STOPS.map((s, i, a) => (
              <div key={s.addr} style={{ display:'flex', gap:12, alignItems:'center',
                position:'relative', paddingBottom: i === a.length - 1 ? 0 : 14 }}>
                {i !== a.length - 1 && (
                  <span style={{ position:'absolute', left:3.5, top:14, bottom:0,
                    width:1.5, background:'#E8E8EA' }} />
                )}
                <span style={{ width:9, height:9, borderRadius:9, flexShrink:0,
                  background: i === a.length - 1 ? pine : '#C9C8C5' }} />
                <div style={{ flex:1 }}>
                  <span style={{ fontSize:14, fontWeight: i === a.length - 1 ? 600 : 500,
                    color: i === a.length - 1 ? ink : '#48484C' }}>
                    {s.addr}
                  </span>
                  {s.note && (
                    <span style={{ fontSize:12.5, color:sub, marginLeft:6 }}>— {s.note}</span>
                  )}
                </div>
              </div>
            ))}
          </div>

          <button className="eb-cta" style={{ marginTop:18 }} onClick={() => go('r-job')}>
            Accept batch
          </button>
        </div>

        {/* Other offers */}
        <div className="eb-group" style={{ marginTop:12 }}>
          {[
            ['Single · Flatiron',        '0.9 mi · 1 return',  '$9.75' ],
            ['Batch of 3 · West Village','3.1 mi loop',        '$29.10'],
          ].map(([t, s, p]) => (
            <div className="eb-row" key={t}>
              <div>
                <div style={{ fontWeight:600, fontSize:15 }}>{t}</div>
                <div style={{ fontSize:13, color:sub, marginTop:1 }}>{s}</div>
              </div>
              <span className="num" style={{ fontWeight:700, fontSize:15 }}>{p}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
