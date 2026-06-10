import React, { useState } from 'react';
import { ink, sub, canvas, surface, pine } from '../../tokens.js';
import { Nav, Status, I, ic, Seal } from '../../ui.jsx';
import { BATCH_STOPS } from '../../data.js';

const TASKS = [
  ['Photograph the item at the door', 'camera'],
  ['Scan the return label',           'doc'   ],
  ['Seal in bag',                     'box'   ],
];

const UPS_TASKS = [
  ['Scan all three bags at counter', 'bag'   ],
  ['Get printed receipt',            'doc'   ],
  ['Photograph the receipt',         'camera'],
];

export default function Job({ go, stop, onStopComplete, onBatchComplete, delight }) {
  const [step, setStep] = useState(0);
  const [sealVisible, setSealVisible] = useState(false);

  const isUPS = stop === 3;
  const current = BATCH_STOPS[stop];
  const tasks = isUPS ? UPS_TASKS : TASKS;
  const allDone = step >= tasks.length;

  const handleTap = (i) => {
    if (i !== step) return;
    const next = step + 1;
    setStep(next);
    if (delight === 'seal' && next === tasks.length && !isUPS) {
      setTimeout(() => setSealVisible(true), 200);
    }
  };

  const handleNext = () => {
    setStep(0);
    setSealVisible(false);
    if (isUPS) {
      onBatchComplete();
      go('r-done');
    } else {
      onStopComplete();
      go('r-job');
    }
  };

  return (
    <div className="fade" style={{ flex:1, display:'flex', flexDirection:'column', overflow:'auto' }}>
      <Status />
      <Nav title={isUPS ? 'UPS drop-off' : `Stop ${stop + 1} of 4`} back={() => go('r-feed')} />

      {/* Stop progress bar */}
      <div style={{ display:'flex', gap:6, padding:'4px 20px 0' }}>
        {BATCH_STOPS.map((s, i) => (
          <div key={i} style={{ flex:1, height:3, borderRadius:3,
            background: i < stop ? pine : i === stop ? ink : '#E3E2DF',
            transition:'background .3s' }} />
        ))}
      </div>

      <div style={{ padding:'16px 20px 24px', flex:1, display:'flex', flexDirection:'column' }}>
        {/* Stop header */}
        <div style={{ padding:'4px 4px 18px', position:'relative' }}>
          {isUPS ? (
            <>
              <div style={{ fontSize:21, fontWeight:700, letterSpacing:-.3 }}>{current.addr}</div>
              <div style={{ fontSize:14, color:sub, marginTop:3 }}>Drop all bags · get receipt scan</div>
            </>
          ) : (
            <>
              <div style={{ fontSize:21, fontWeight:700, letterSpacing:-.3 }}>
                {current.addr} · {current.name}
              </div>
              <div style={{ fontSize:14, color:sub, marginTop:3 }}>
                {current.retailer} · {current.note}
              </div>
              {current.bag && (
                <div className="num" style={{ fontSize:12.5, color:sub, marginTop:4 }}>
                  Bag {current.bag}
                </div>
              )}
              {delight === 'seal' && sealVisible && (
                <span style={{ position:'absolute', top:0, right:0 }}>
                  <Seal show size={48} />
                </span>
              )}
            </>
          )}
        </div>

        {/* Task checklist */}
        <div className="eb-group">
          {tasks.map(([label, iconKey], i) => {
            const done    = i < step;
            const active  = i === step;
            const locked  = i > step;
            return (
              <button key={label} className="eb-row"
                onClick={() => handleTap(i)}
                style={{ width:'100%', gap:14, opacity: locked ? .32 : 1, transition:'opacity .25s' }}>
                <span style={{
                  width:36, height:36, borderRadius:18, flexShrink:0,
                  display:'grid', placeItems:'center',
                  background: done ? pine : canvas,
                  transition: 'background .25s',
                }}>
                  {done
                    ? <I d={ic.check} s={16} c="#fff" sw={2.4} />
                    : <I d={ic[iconKey]} s={17} c={active ? ink : sub} />}
                </span>
                <span style={{ flex:1, fontSize:15, fontWeight:600 }}>{label}</span>
                {done   && <span className="num" style={{ fontSize:12.5, color:sub }}>✓</span>}
                {active && <span style={{ fontSize:13, color:sub }}>Tap</span>}
              </button>
            );
          })}
        </div>

        {/* Completion message */}
        {allDone && !isUPS && (
          <div className="fade" style={{ marginTop:18, textAlign:'center' }}>
            <div style={{ fontSize:15, fontWeight:600 }}>Custody is yours.</div>
            <div style={{ fontSize:13.5, color:sub, marginTop:3 }}>
              {current.name} just got your photos.{' '}
              {stop < 3 ? `Next: ${BATCH_STOPS[stop + 1].addr}.` : 'Head to UPS.'}
            </div>
          </div>
        )}
        {allDone && isUPS && (
          <div className="fade" style={{ marginTop:18, textAlign:'center' }}>
            <div style={{ fontSize:15, fontWeight:600 }}>Batch closed.</div>
            <div style={{ fontSize:13.5, color:sub, marginTop:3 }}>
              All three customers got confirmation.
            </div>
          </div>
        )}

        <div style={{ flex:1 }} />
        <button className="eb-cta" disabled={!allDone} onClick={handleNext}>
          {!allDone
            ? `Complete ${tasks.length - step} more step${tasks.length - step !== 1 ? 's' : ''}`
            : isUPS
              ? 'Finish batch'
              : stop < 2
                ? `Navigate to ${BATCH_STOPS[stop + 1].addr}`
                : 'Navigate to UPS'
          }
        </button>
      </div>
    </div>
  );
}
