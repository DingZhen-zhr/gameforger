/* @jsx React.createElement */
// GameForger v2 — shared base
// Loaded after React/Babel/ios-frame/design-canvas. Exports to window.

// ─────────────────────────────────────────────────────────────
// Icon bank — same stroke style across both directions
// ─────────────────────────────────────────────────────────────
const Icon2 = ({ size = 20, stroke = 1.7, color = "currentColor", children }) =>
  React.createElement('svg', {
    width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: color, strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round",
  }, children);

const I2 = {
  Plus:    (p) => <Icon2 {...p}><path d="M12 5v14M5 12h14"/></Icon2>,
  Search:  (p) => <Icon2 {...p}><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></Icon2>,
  Chev:    (p) => <Icon2 {...p}><path d="M9 6l6 6-6 6"/></Icon2>,
  ChevL:   (p) => <Icon2 {...p}><path d="M15 6l-6 6 6 6"/></Icon2>,
  ChevD:   (p) => <Icon2 {...p}><path d="M6 9l6 6 6-6"/></Icon2>,
  More:    (p) => <Icon2 {...p}><circle cx="5" cy="12" r="1.4" fill="currentColor"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/><circle cx="19" cy="12" r="1.4" fill="currentColor"/></Icon2>,
  Close:   (p) => <Icon2 {...p}><path d="M6 6l12 12M18 6L6 18"/></Icon2>,
  Check:   (p) => <Icon2 {...p}><path d="M5 12l4 4 10-10"/></Icon2>,
  Send:    (p) => <Icon2 {...p}><path d="M5 12h14M13 6l6 6-6 6"/></Icon2>,
  Sparkle: (p) => <Icon2 {...p}><path d="M12 3l1.6 4.8L18 9.5l-4.4 1.7L12 16l-1.6-4.8L6 9.5l4.4-1.7L12 3z"/></Icon2>,
  Sun:     (p) => <Icon2 {...p}><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.4 1.4M17.6 17.6L19 19M5 19l1.4-1.4M17.6 6.4L19 5"/></Icon2>,
  Moon:    (p) => <Icon2 {...p}><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></Icon2>,
  Folder:  (p) => <Icon2 {...p}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/></Icon2>,
  Grid:    (p) => <Icon2 {...p}><rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/></Icon2>,
  Layers:  (p) => <Icon2 {...p}><path d="M12 3l9 5-9 5-9-5 9-5zM3 13l9 5 9-5M3 17l9 5 9-5"/></Icon2>,
  Person:  (p) => <Icon2 {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></Icon2>,
  Settings:(p) => <Icon2 {...p}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.6-2-3.4-2.4.8a7 7 0 0 0-2.1-1.2L14 3h-4l-.4 2.4a7 7 0 0 0-2.1 1.2l-2.4-.8-2 3.4 2 1.6A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.6 2 3.4 2.4-.8c.6.5 1.4.9 2.1 1.2L10 21h4l.4-2.4c.7-.3 1.5-.7 2.1-1.2l2.4.8 2-3.4-2-1.6c.1-.4.1-.8.1-1.2z"/></Icon2>,
  Bell:    (p) => <Icon2 {...p}><path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6zM10 19a2 2 0 0 0 4 0"/></Icon2>,
  Edit:    (p) => <Icon2 {...p}><path d="M4 20h4l11-11-4-4L4 16v4z"/><path d="M14 5l4 4"/></Icon2>,
  Code:    (p) => <Icon2 {...p}><path d="M8 6l-5 6 5 6M16 6l5 6-5 6M14 4l-4 16"/></Icon2>,
  Eye:     (p) => <Icon2 {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></Icon2>,
  Play:    (p) => <Icon2 {...p}><path d="M6 4l14 8-14 8V4z" fill="currentColor"/></Icon2>,
  Volume:  (p) => <Icon2 {...p}><path d="M4 9v6h3l5 4V5L7 9H4z"/><path d="M16 8a5 5 0 0 1 0 8"/></Icon2>,
  Expand:  (p) => <Icon2 {...p}><path d="M4 10V4h6M20 14v6h-6M4 14v6h6M20 10V4h-6"/></Icon2>,
  Share:   (p) => <Icon2 {...p}><path d="M12 3v13M7 8l5-5 5 5M5 15v4a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-4"/></Icon2>,
  Copy:    (p) => <Icon2 {...p}><rect x="8" y="8" width="12" height="12" rx="2.5"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/></Icon2>,
  Refresh: (p) => <Icon2 {...p}><path d="M21 12a9 9 0 1 1-3.2-6.9"/><path d="M21 4v5h-5"/></Icon2>,
  Info:    (p) => <Icon2 {...p}><circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8.5v.01"/></Icon2>,
  Key:     (p) => <Icon2 {...p}><circle cx="8" cy="15" r="4"/><path d="M11 13l9-9M16 7l3 3M14 10l2 2"/></Icon2>,
  Coin:    (p) => <Icon2 {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h3.5a2 2 0 0 1 0 4H10a2 2 0 0 0 0 4h4"/></Icon2>,
  Logout:  (p) => <Icon2 {...p}><path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 17l5-5-5-5M15 12H3"/></Icon2>,
  Chat:    (p) => <Icon2 {...p}><path d="M21 12a8 8 0 1 1-3-6.2L21 4l-1 4.5A8 8 0 0 1 21 12z"/></Icon2>,
  Palette: (p) => <Icon2 {...p}><path d="M12 3a9 9 0 0 0 0 18c1.5 0 2-1 2-2 0-1.5-1-1.5-1-3 0-1 1-2 2.5-2H18a3 3 0 0 0 3-3 9 9 0 0 0-9-8z"/></Icon2>,
  Mark:    (p) => <Icon2 {...p}><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z"/></Icon2>,
  Wand:    (p) => <Icon2 {...p}><path d="M4 20l11-11"/><path d="M16 4l1.5 1.5M20 8l-1.5-1.5M19 4l-2 2M16 7l1 1"/></Icon2>,
  Dot:     (p) => <Icon2 {...p}><circle cx="12" cy="12" r="3" fill="currentColor"/></Icon2>,
  Heart:   (p) => <Icon2 {...p}><path d="M12 21s-7-4.5-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6c-2.5 4.5-9.5 9-9.5 9z"/></Icon2>,
  Trash:   (p) => <Icon2 {...p}><path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/></Icon2>,
  Star:    (p) => <Icon2 {...p}><path d="M12 3l2.7 5.7 6.3.9-4.5 4.4 1 6.2L12 17.3l-5.5 2.9 1-6.2L3 9.6l6.3-.9L12 3z"/></Icon2>,
  Clock:   (p) => <Icon2 {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></Icon2>,
};

// ─────────────────────────────────────────────────────────────
// Brand mark — anvil with sparks
//   A real blacksmith anvil silhouette: horn left, working surface,
//   stepped neck, base. Two sparks above the strike point.
//   Static. Works at any size, any theme.
// ─────────────────────────────────────────────────────────────

// Anvil path — viewBox 0 0 32 32, fits with ~2px breathing
//   horn tip (1,11.5) → top surface → neck → flared base
const ANVIL_PATH = "M 1 11.5 L 5 8.5 L 28 8.5 L 28 13 L 21 13 L 21 18 L 28 18 L 28 24 L 4 24 L 4 18 L 11 18 L 11 13 L 5 13 Z";

// Direction A · iOS-soft anvil — rounded, hairline frame around it
function ForgeMark({ size = 28, color = 'currentColor', accent }) {
  const acc = accent || color;
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      {/* soft squircle frame */}
      <rect x="2" y="2" width="28" height="28" rx="8" fill={color} opacity="0.06"/>
      {/* anvil silhouette */}
      <path d={ANVIL_PATH} fill={color} strokeLinejoin="round" strokeLinecap="round" stroke={color} strokeWidth="0.5"/>
      {/* sparks above strike surface */}
      <circle cx="23" cy="4.5" r="1.9" fill={acc}/>
      <circle cx="27" cy="2.8" r="0.9" fill={acc} opacity="0.55"/>
    </svg>
  );
}

// Direction B · editorial anvil — flat silhouette, no frame, bigger sparks
function ForgeMarkB({ size = 28, color = 'currentColor', accent }) {
  const acc = accent || color;
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      {/* anvil silhouette — solid */}
      <path d={ANVIL_PATH} fill={color}/>
      {/* sparks above strike surface — editorial diamond + dot */}
      <path d="M 23 6 L 24.5 3 L 26 6 L 24.5 9 Z" fill={acc}/>
      <circle cx="20" cy="4" r="0.9" fill={acc} opacity="0.7"/>
      <circle cx="28" cy="3" r="0.7" fill={acc} opacity="0.5"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Phone shell — iOS frame with theme-aware bezel
// ─────────────────────────────────────────────────────────────
function PhoneV2({ children, theme, dir }) {
  // Bezel color follows theme — dark phone for dark, light silver for light
  const bezel = theme === 'dark' ? '#0A0A0A' : '#D8D5CE';
  const innerStroke = theme === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.12)';
  const shadow = theme === 'dark'
    ? '0 30px 70px rgba(0,0,0,0.5), 0 0 0 0.5px rgba(255,255,255,0.06)'
    : '0 30px 70px rgba(60,50,30,0.18), 0 6px 18px rgba(60,50,30,0.10)';
  // Status bar tint — dark text on light bg, white on dark
  const statusDark = theme === 'dark';
  return (
    <div data-dir={dir} data-theme={theme} style={{
      width: 402, height: 874, borderRadius: 54, overflow: 'hidden', position: 'relative',
      background: bezel,
      boxShadow: `0 0 0 6px ${bezel}, 0 0 0 7px ${innerStroke}, ${shadow}`,
      fontFamily: 'var(--font-ui)',
    }}>
      {/* screen surface */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'var(--bg)',
        color: 'var(--text-1)',
      }} />
      {/* dynamic island */}
      <div style={{
        position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
        width: 122, height: 36, borderRadius: 24, background: '#000', zIndex: 100,
      }} />
      {/* status bar */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 50 }}>
        <IOSStatusBar dark={statusDark} />
      </div>
      {/* home indicator */}
      <div style={{
        position: 'absolute', bottom: 8, left: 0, right: 0, zIndex: 90,
        display: 'flex', justifyContent: 'center', pointerEvents: 'none',
      }}>
        <div style={{
          width: 139, height: 5, borderRadius: 100,
          background: statusDark ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.30)',
        }} />
      </div>
      <div style={{ position: 'absolute', inset: 0, zIndex: 10 }}>
        {children}
      </div>
    </div>
  );
}

// Convenience wrapper to fit inside a DCArtboard
function Frame({ dir, theme, children }) {
  return (
    <div style={{ padding: 9 }}>
      <PhoneV2 dir={dir} theme={theme}>{children}</PhoneV2>
    </div>
  );
}

Object.assign(window, { Icon2, I2, ForgeMark, ForgeMarkB, PhoneV2, Frame });
