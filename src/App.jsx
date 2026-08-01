import React, { useState, useEffect, useCallback, useRef } from 'react';
import { sub } from './tokens.js';
import { css, I, ic } from './ui.jsx';
import { NOTES, STEPS } from './data.js';
import DelightPicker from './DelightPicker.jsx';

import Onboarding   from './screens/customer/Onboarding.jsx';
import Home         from './screens/customer/Home.jsx';
import Snap         from './screens/customer/Snap.jsx';
import Window       from './screens/customer/Window.jsx';
import Pay          from './screens/customer/Pay.jsx';
import Track        from './screens/customer/Track.jsx';
import Done         from './screens/customer/Done.jsx';
import RefundLanded from './screens/customer/RefundLanded.jsx';
import Feed         from './screens/runner/Feed.jsx';
import Job          from './screens/runner/Job.jsx';
import BatchDone    from './screens/runner/BatchDone.jsx';
import Founder      from './screens/founder/index.jsx';

/* Ordered screens for keyboard presenter nav (→ key) */
const GP = [
  'c-home','c-snap','c-window','c-pay',
  'c-track','c-track','c-track','c-track','c-track','c-track',
  'c-done','c-home',
];

export default function ErrandBoyDemo() {
  /* ── Persistent ─ */
  const [onboarded,    setOnboarded   ] = useState(() => !!localStorage.getItem('eb_onboarded'));
  const [delightStyle, setDelightStyle] = useState(() => localStorage.getItem('eb_delight') || 'seal');

  /* ── Screen & flow state ─ */
  const [screen,       setScreen   ] = useState(() => localStorage.getItem('eb_onboarded') ? 'c-home' : 'c-onboard');
  const [persona,      setPersona  ] = useState('customer');
  const [custActive,   setCustActive] = useState(false);
  const [trackStage,   setTrackStage] = useState(0);
  const [refundLanded, setRefundLanded] = useState(false);
  const [runnerStop,   setRunnerStop] = useState(0);

  /* ── Presenter ─ */
  const [presenterMode, setPresenter] = useState(false);
  const [presHint,      setPresHint ] = useState(false);
  const gpIdx = useRef(0);

  const go = useCallback(s => setScreen(s), []);

  /* Auto-advance tracking stages */
  useEffect(() => {
    if (screen === 'c-track' && trackStage < STEPS.length) {
      const t = setTimeout(() => setTrackStage(s => s + 1), trackStage === 0 ? 500 : 2400);
      return () => clearTimeout(t);
    }
  }, [screen, trackStage]);

  /* Simulate refund notification 5s after returning home post-completion */
  useEffect(() => {
    if (screen === 'c-home' && custActive && trackStage >= STEPS.length) {
      const t = setTimeout(() => setRefundLanded(true), 5000);
      return () => clearTimeout(t);
    }
  }, [screen, custActive, trackStage]);

  /* Keyboard presenter controls */
  useEffect(() => {
    const down = e => {
      if (e.key === 'f' || e.key === 'F')   { e.preventDefault(); setPresenter(p => !p); }
      if (e.key === '?' || e.key === '/')    setPresHint(h => !h);
      if (e.key === 'Escape')                setPresenter(false);
      if ((e.key === 'ArrowRight' || e.key === 'ArrowDown') && persona === 'customer') {
        e.preventDefault();
        advanceGP();
      }
    };
    window.addEventListener('keydown', down);
    return () => window.removeEventListener('keydown', down);
  });

  const advanceGP = () => {
    const cur = GP[gpIdx.current];
    if (cur === 'c-track') {
      if (trackStage < STEPS.length) { setTrackStage(s => s + 1); return; }
      gpIdx.current += 1;
      setScreen('c-done');
      return;
    }
    if (cur === 'c-pay') { setCustActive(true); setTrackStage(0); }
    if (cur === 'c-done') { setCustActive(false); setTrackStage(0); }
    gpIdx.current = Math.min(gpIdx.current + 1, GP.length - 1);
    setScreen(GP[gpIdx.current]);
  };

  /* Persona switcher */
  const switchP = p => {
    setPersona(p);
    if (p === 'customer')      setScreen(custActive ? 'c-track' : 'c-home');
    else if (p === 'runner')   setScreen(runnerStop === 4 ? 'r-done' : 'r-feed');
    else                       setScreen('founder');
  };

  /* Hard reset */
  const reset = () => {
    setCustActive(false); setTrackStage(0); setRefundLanded(false);
    setRunnerStop(0); setPersona('customer');
    setScreen(onboarded ? 'c-home' : 'c-onboard');
    gpIdx.current = 0;
  };

  const [scene, say] = NOTES[screen] || NOTES['founder'];

  /* ── Screen router ─ */
  const render = () => {
    switch (screen) {
      case 'c-onboard':
        return <Onboarding go={go} onComplete={() => {
          setOnboarded(true);
          localStorage.setItem('eb_onboarded', '1');
        }} />;
      case 'c-home':
        return <Home go={go} active={custActive} refundLanded={refundLanded} delight={delightStyle} />;
      case 'c-snap':
        return <Snap go={go} delight={delightStyle} />;
      case 'c-window':
        return <Window go={go} />;
      case 'c-pay':
        return <Pay go={go} onConfirm={() => { setCustActive(true); setTrackStage(0); }} />;
      case 'c-track':
        return <Track go={go} stage={trackStage} delight={delightStyle} />;
      case 'c-done':
        return <Done go={go} delight={delightStyle} onReset={() => { setCustActive(false); setTrackStage(0); }} />;
      case 'c-refund':
        return <RefundLanded go={go} delight={delightStyle} onAcknowledge={() => setRefundLanded(false)} />;
      case 'r-feed':
        return <Feed go={go} />;
      case 'r-job':
        return <Job
          go={go} stop={runnerStop} delight={delightStyle}
          onStopComplete={() => setRunnerStop(s => Math.min(s + 1, 3))}
          onBatchComplete={() => setRunnerStop(4)}
        />;
      case 'r-done':
        return <BatchDone go={go} delight={delightStyle} onReset={() => setRunnerStop(0)} />;
      default:
        return <Founder delight={delightStyle} />;
    }
  };

  return (
    <div className={`eb${presenterMode ? ' eb-presenter' : ''}`}>
      <style>{css}</style>

      <div className="eb-stage">

        {/* ── Pitch rail ── */}
        <div className="eb-rail">
          <div style={{ fontSize:26, fontWeight:800, letterSpacing:-.8 }}>ErrandBoy</div>
          <div style={{ fontSize:13.5, color:sub, marginTop:5, lineHeight:1.55 }}>
            Returns, handled. Two photos, one flat price, proof at every handoff.
          </div>

          <div className="eb-seg" style={{ marginTop:22 }} role="tablist" aria-label="Persona">
            {[['customer','Customer'],['runner','Runner'],['founder','Founder']].map(([k, t]) => (
              <button key={k} role="tab" aria-selected={persona === k}
                className={persona === k ? 'on' : ''} onClick={() => switchP(k)}>{t}</button>
            ))}
          </div>

          <div style={{ marginTop:24, paddingTop:18, borderTop:'1px solid rgba(0,0,0,.07)' }}>
            <div style={{ fontSize:12.5, fontWeight:700, color:sub }}>{scene}</div>
            <div style={{ fontSize:14, lineHeight:1.6, marginTop:7 }}>{say}</div>
          </div>

          {presHint && (
            <div style={{ marginTop:16, padding:'12px 14px', background:'rgba(0,0,0,.04)',
              borderRadius:10, fontSize:12 }}>
              <div style={{ fontWeight:700, marginBottom:6 }}>Keyboard shortcuts</div>
              {[['→ / ↓','Advance golden path'],['F','Toggle fullscreen'],['?','Toggle hints'],['Esc','Exit fullscreen']].map(([k,v]) => (
                <div key={k} style={{ display:'flex', gap:8, marginBottom:3 }}>
                  <span style={{ fontWeight:700, width:44, flexShrink:0 }}>{k}</span>
                  <span style={{ color:sub }}>{v}</span>
                </div>
              ))}
            </div>
          )}

          <DelightPicker current={delightStyle} onChange={setDelightStyle} />

          <div style={{ marginTop:22, display:'flex', gap:14, flexWrap:'wrap' }}>
            <button onClick={reset} style={{ fontSize:13, fontWeight:600, color:sub }}>Reset demo</button>
            <button onClick={() => setPresHint(h => !h)} style={{ fontSize:13, fontWeight:600, color:sub }}>
              {presHint ? 'Hide keys' : '⌨ Shortcuts'}
            </button>
            <button onClick={() => setPresenter(p => !p)} style={{ fontSize:13, fontWeight:600, color:sub }}>
              {presenterMode ? 'Exit fullscreen' : '⛶ Present'}
            </button>
          </div>
        </div>

        {/* ── Phone frame ── */}
        <div className="eb-phone">
          <div className="eb-screen">{render()}</div>
        </div>

      </div>
    </div>
  );
}
