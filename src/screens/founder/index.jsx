import React from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Status, I, ic, LiveDot, FlipNumber } from '../../ui.jsx';
import { useCount } from '../../hooks.js';
import { COHORTS, MARGIN } from '../../data.js';

const Stat = ({ k, v, s }) => (
  <div style={{ flex:1, minWidth:128 }}>
    <div className="num" style={{ fontSize:30, fontWeight:800, letterSpacing:-1 }}>{v}</div>
    <div style={{ fontSize:13, fontWeight:600, marginTop:2 }}>{k}</div>
    {s && <div style={{ fontSize:12, color:sub, marginTop:1 }}>{s}</div>}
  </div>
);

export default function Founder({ delight }) {
  const mins = useCount(7650, true, 2000);

  return (
    <div className="fade" style={{ flex:1, overflow:'auto' }}>
      <Status />
      <div style={{ padding:'22px 24px 36px' }}>

        {/* Pilot header */}
        <div style={{ display:'flex', alignItems:'center', gap:7, marginBottom:4 }}>
          <LiveDot />
          <span style={{ fontSize:13, fontWeight:600, color:sub }}>Chelsea pilot · week 8</span>
        </div>
        <div style={{ fontSize:25, fontWeight:800, letterSpacing:-.6, marginBottom:4 }}>
          The case, in one screen.
        </div>

        {/* Live minutes saved counter */}
        <div style={{ fontSize:13, color:sub, marginBottom:22 }}>
          {delight === 'flip'
            ? <>
                <FlipNumber value={mins} style={{ fontSize:14, fontWeight:700, color:pine }} />
                {' '}min saved today across all users
              </>
            : <><span className="num" style={{ color:pine, fontWeight:700 }}>{Math.round(mins).toLocaleString()}</span>
                {' '}min saved today across all users</>
          }
        </div>

        {/* Top stats */}
        <div style={{ display:'flex', gap:12, flexWrap:'wrap', marginBottom:28 }}>
          <Stat k="Returns done"    v="509" s="+34% wk over wk" />
          <Stat k="Repeat in 30 d" v="61%" s="of paying customers" />
        </div>

        {/* Contribution margin */}
        <div style={{ marginBottom:28 }}>
          <div style={{ fontSize:14, fontWeight:700, marginBottom:12 }}>Every order makes money</div>
          {MARGIN.map(([k, v, c]) => (
            <div key={k} style={{ display:'flex', alignItems:'center', gap:10, marginBottom:9 }}>
              <span style={{ width:124, fontSize:12.5, flexShrink:0,
                color: c === pine ? pine : sub,
                fontWeight: c === pine ? 700 : 500 }}>{k}</span>
              <span style={{
                height:22, borderRadius:6, background:c,
                width:`${(Math.abs(v) / 14.5) * 100}%`, minWidth:8,
                transition:'width .6s',
              }} />
              <span className="num" style={{ fontSize:13, fontWeight:700,
                color: c === pine ? pine : ink }}>
                {v < 0 ? '−' : ''}${Math.abs(v).toFixed(2)}
              </span>
            </div>
          ))}
          <div style={{ fontSize:12.5, color:sub, lineHeight:1.55, marginTop:8 }}>
            Batching is the unlock: four returns share one trip, so the runner earns $42/hr
            while we keep 31%. Single-task gig apps can't replicate the route density.
          </div>
        </div>

        {/* Cohort retention */}
        <div style={{ marginBottom:28 }}>
          <div style={{ fontSize:14, fontWeight:700 }}>They come back</div>
          <div style={{ fontSize:12.5, color:sub, marginTop:2, marginBottom:12 }}>
            Monthly retention by cohort, % still ordering
          </div>
          <div style={{ display:'flex', gap:6, marginBottom:6 }}>
            <span style={{ width:34 }} />
            {['M0','M1','M2','M3'].map(m => (
              <span key={m} className="num" style={{ flex:1, textAlign:'center',
                fontSize:11, color:sub, fontWeight:600 }}>{m}</span>
            ))}
          </div>
          {COHORTS.map(([m, row]) => (
            <div key={m} style={{ display:'flex', gap:6, marginBottom:6 }}>
              <span style={{ width:34, fontSize:11.5, color:sub, fontWeight:600, alignSelf:'center' }}>{m}</span>
              {row.map((v, i) => (
                <span key={i} className="num" style={{
                  flex:1, textAlign:'center', fontSize:12.5, fontWeight:700,
                  padding:'9px 0', borderRadius:8,
                  background: v == null ? 'transparent' : `rgba(14,107,79,${0.07 + (v / 100) * 0.5})`,
                  color: v == null ? 'transparent' : v > 70 ? '#fff' : pine,
                }}>{v ?? '·'}</span>
              ))}
            </div>
          ))}
        </div>

        {/* The ask */}
        <div style={{ background:ink, borderRadius:18, padding:'20px', color:'#fff', marginBottom:24 }}>
          <div style={{ fontSize:14, fontWeight:700 }}>The ask: $300K</div>
          <div style={{ fontSize:13, color:'rgba(255,255,255,.65)', marginTop:8, lineHeight:1.65 }}>
            Buys 12 months and four milestones: three NYC zones live, 2,500 returns a week,
            contribution-positive at the order level, and one signed retailer pilot.
            Hit those and the seed prices itself.
          </div>
        </div>

        {/* Kill risks */}
        <div>
          <div style={{ fontSize:14, fontWeight:700, marginBottom:14 }}>What kills this, and our answer</div>
          {[
            ['Density cold start',       'Launch one zip at a time; batch from day one; seed demand through doorman buildings.'],
            ['Trust and fraud',          'Photo custody at every handoff, sealed bags, $500 per-item guarantee. The record is the product.'],
            ['Retailers go free-pickup', 'Then we become their pickup layer — the custody API is built to be sold to them, not against them.'],
          ].map(([r, a]) => (
            <div key={r} style={{ marginBottom:16 }}>
              <div style={{ fontSize:13.5, fontWeight:700 }}>{r}</div>
              <div style={{ fontSize:13, color:sub, lineHeight:1.55, marginTop:3 }}>{a}</div>
            </div>
          ))}
        </div>

      </div>
    </div>
  );
}
