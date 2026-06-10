export const ITEM = {
  retailer: 'Nordstrom',
  item: 'On Cloudmonster, W 8.5',
  order: 'NORD-448291',
  refund: 149.95,
};

export const STEPS = [
  { t: '2:04', title: 'Runner matched',              sub: 'Maya · 4.97 · 612 returns' },
  { t: '2:21', title: 'Maya is on the way',          sub: 'Arriving in your 2–4 pm window' },
  { t: '2:38', title: 'Picked up at your door',      sub: 'Item and label photographed', proof: true },
  { t: '3:02', title: 'En route to UPS',             sub: 'Sealed bag 8841 · 1.8 mi' },
  { t: '3:19', title: 'Dropped off, receipt in hand',sub: 'UPS acceptance scan confirmed', proof: true },
  { t: '3:20', title: 'Refund initiated',            sub: '$149.95 from Nordstrom, 3–5 days', money: true },
];

export const CUSTODY_RECORDS = [
  { t: '2:38', label: 'Item at pickup',   bag: '8841', addr: '412 W 23rd St',        hash: 'a3f8…e1' },
  { t: '2:38', label: 'Label confirmed',  bag: '8841', addr: '412 W 23rd St',        hash: 'b72c…9a' },
  { t: '3:19', label: 'UPS acceptance',   bag: '8841', addr: 'UPS Store, 465 W 23rd', hash: 'f019…44' },
];

export const BATCH_STOPS = [
  { addr: '412 W 23rd', name: 'Elliot', retailer: 'Nordstrom', note: 'Sneakers · bring a box',      bag: '8841' },
  { addr: '388 W 21st', name: 'Sarah',  retailer: 'Zara',      note: 'Blazer · pre-labeled',        bag: '8842' },
  { addr: '301 W 19th', name: 'James',  retailer: 'REI',        note: 'Two parcels · ready at door', bag: '8843' },
  { addr: 'UPS · 465 W 23rd', name: null, retailer: null,       note: 'Drop all · scan receipt',    bag: null   },
];

export const PAST_RETURNS = [
  { retailer: 'Amazon', item: 'USB-C hub',    amt: 42.99  },
  { retailer: 'Zara',   item: 'Linen blazer', amt: 89.90  },
  { retailer: 'REI',    item: 'Trail poles',  amt: 129.00 },
];

export const NOTES = {
  'c-onboard': ['Customer · Setup',         'Thirty seconds to set up. One address, one card. We ask once, remember forever.'],
  'c-home':    ['Customer · Home',          'Open on the only number that matters to her: hours back. We sell time, not logistics.'],
  'c-snap':    ['Customer · New return',    'The entire ask is two photos. We read the label — she types nothing. Friction is the competitor.'],
  'c-window':  ['Customer · Schedule',      'One flat price, stated once. No surge, no tipping screen, no upsell. Trust is priced in.'],
  'c-pay':     ['Customer · Confirm',       "Point at what isn't here: no cart, no account setup wall. Thirty seconds, door to done."],
  'c-track':   ['Customer · Tracking',      'The moat: every handoff timestamped with photo proof. This custody record is what a retailer or carrier acquires.'],
  'c-custody': ['Customer · Proof chain',   'Every photo, every handoff, in order. This is the enterprise asset — the audit trail, not the pickup service.'],
  'c-done':    ['Customer · Complete',      "We close the loop on her refund, not our dropoff. The counted minutes are the brand."],
  'c-refund':  ['Customer · Refund landed', "We track the money, not just the package. The app surfaces when the refund hits — that's the loop no one else closes."],
  'r-feed':    ['Runner · Offers',          'Supply economics: four returns batch into one UPS run. Density, not hustle, sets the wage.'],
  'r-job':     ['Runner · Pickup',          'Three taps, no typing, no training. Quality is enforced by the flow itself.'],
  'r-done':    ['Runner · Batch complete',  'Earnings settle instantly. No wait, no minimum. That\'s retention on the supply side.'],
  'founder':   ['Founder · The case',       'Contribution margin per order, cohort retention, the ask, and the three risks — before they ask.'],
};

export const COHORTS = [
  ['Feb', [100, 64, 51, 47]],
  ['Mar', [100, 62, 49, null]],
  ['Apr', [100, 61, null, null]],
  ['May', [100, null, null, null]],
];

export const MARGIN = [
  ['Customer pays',               14.50, '#161617'],
  ['Runner (batched)',             -8.90, '#A5A4A1'],
  ['Support, insurance, payments', -1.11, '#C9C8C5'],
  ['Contribution per order',        4.49, '#0E6B4F'],
];
