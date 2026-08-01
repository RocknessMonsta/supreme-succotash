import { useState, useEffect, useRef } from 'react';

export const useCount = (target, run, dur = 1400) => {
  const [v, setV] = useState(0);
  useEffect(() => {
    if (!run) { setV(0); return; }
    let start, raf;
    const step = t => {
      if (!start) start = t;
      const p = Math.min((t - start) / dur, 1);
      setV(target * (1 - Math.pow(1 - p, 3)));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [run, target, dur]);
  return v;
};

export const useFlipDigit = (digit) => {
  const [animKey, setAnimKey] = useState(0);
  const prev = useRef(digit);
  useEffect(() => {
    if (digit !== prev.current) {
      setAnimKey(k => k + 1);
      prev.current = digit;
    }
  }, [digit]);
  return animKey;
};
