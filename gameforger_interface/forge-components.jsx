/* @jsx React.createElement */
// Forge — shared cosmic UI components
// Loaded after React/Babel. Exports to window.

// ─────────────────────────────────────────────────────────────
// Icon bank — line icons, stroke 1.6, currentColor
// ─────────────────────────────────────────────────────────────
const Icon = ({ d, size = 20, stroke = 1.6, fill = "none", color = "currentColor", children, vb = "0 0 24 24" }) =>
  React.createElement('svg', {
    width: size, height: size, viewBox: vb, fill: "none",
    stroke: color, strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round",
  }, children || React.createElement('path', { d, fill }));

const I = {
  Plus:    (p) => <Icon {...p}><path d="M12 5v14M5 12h14"/></Icon>,
  Refresh: (p) => <Icon {...p}><path d="M21 12a9 9 0 1 1-3.2-6.9"/><path d="M21 4v5h-5"/></Icon>,
  Chevron: (p) => <Icon {...p}><path d="M9 6l6 6-6 6"/></Icon>,
  ChevronL:(p) => <Icon {...p}><path d="M15 6l-6 6 6 6"/></Icon>,
  ChevronD:(p) => <Icon {...p}><path d="M6 9l6 6 6-6"/></Icon>,
  More:    (p) => <Icon {...p}><circle cx="5" cy="12" r="1.2" fill="currentColor"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/><circle cx="19" cy="12" r="1.2" fill="currentColor"/></Icon>,
  Close:   (p) => <Icon {...p}><path d="M6 6l12 12M18 6L6 18"/></Icon>,
  Search:  (p) => <Icon {...p}><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></Icon>,
  Send:    (p) => <Icon {...p}><path d="M4 12l16-8-6 18-3-7-7-3z"/></Icon>,
  Sparkle: (p) => <Icon {...p}><path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3z"/></Icon>,
  Wand:    (p) => <Icon {...p}><path d="M4 20l11-11"/><path d="M16 4l1.5 1.5M20 8l-1.5-1.5M19 4l-2 2M16 7l1 1"/></Icon>,
  Grid:    (p) => <Icon {...p}><rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/></Icon>,
  Folder:  (p) => <Icon {...p}><path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/></Icon>,
  Stack:   (p) => <Icon {...p}><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5M3 17l9 5 9-5"/></Icon>,
  Settings:(p) => <Icon {...p}><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.6-2-3.4-2.4.8a7 7 0 0 0-2.1-1.2L14 3h-4l-.4 2.4a7 7 0 0 0-2.1 1.2l-2.4-.8-2 3.4 2 1.6A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.6 2 3.4 2.4-.8c.6.5 1.4.9 2.1 1.2L10 21h4l.4-2.4c.7-.3 1.5-.7 2.1-1.2l2.4.8 2-3.4-2-1.6c.1-.4.1-.8.1-1.2z"/></Icon>,
  Controller:(p)=> <Icon {...p}><path d="M6 8h12a4 4 0 0 1 4 4v2a4 4 0 0 1-7 2.5l-1-1H10l-1 1A4 4 0 0 1 2 14v-2a4 4 0 0 1 4-4z"/><circle cx="9" cy="13" r="0.8" fill="currentColor"/><circle cx="15" cy="13" r="0.8" fill="currentColor"/></Icon>,
  Code:    (p) => <Icon {...p}><path d="M8 6l-5 6 5 6M16 6l5 6-5 6M14 4l-4 16"/></Icon>,
  Chat:    (p) => <Icon {...p}><path d="M21 12a8 8 0 1 1-3-6.2L21 4l-1 4.5A8 8 0 0 1 21 12z"/></Icon>,
  Palette: (p) => <Icon {...p}><path d="M12 3a9 9 0 0 0 0 18c1.5 0 2-1 2-2 0-1.5-1-1.5-1-3 0-1 1-2 2.5-2H18a3 3 0 0 0 3-3 9 9 0 0 0-9-8z"/><circle cx="7.5" cy="11" r="1" fill="currentColor"/><circle cx="11" cy="7" r="1" fill="currentColor"/><circle cx="15.5" cy="8" r="1" fill="currentColor"/></Icon>,
  Info:    (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8.5v.01"/></Icon>,
  Volume:  (p) => <Icon {...p}><path d="M4 9v6h3l5 4V5L7 9H4z"/><path d="M16 8a5 5 0 0 1 0 8M19 5a9 9 0 0 1 0 14"/></Icon>,
  Expand:  (p) => <Icon {...p}><path d="M4 10V4h6M20 14v6h-6M4 14v6h6M20 10V4h-6"/></Icon>,
  Share:   (p) => <Icon {...p}><path d="M12 3v13M7 8l5-5 5 5M5 15v4a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-4"/></Icon>,
  Copy:    (p) => <Icon {...p}><rect x="8" y="8" width="12" height="12" rx="2.5"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/></Icon>,
  Edit:    (p) => <Icon {...p}><path d="M4 20h4l11-11-4-4L4 16v4z"/><path d="M14 5l4 4"/></Icon>,
  Eye:     (p) => <Icon {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></Icon>,
  Trash:   (p) => <Icon {...p}><path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/></Icon>,
  Image:   (p) => <Icon {...p}><rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/><path d="M3 17l5-4 5 4 3-2 5 4"/></Icon>,
  Music:   (p) => <Icon {...p}><path d="M9 18V6l11-2v12"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/></Icon>,
  Wifi:    (p) => <Icon {...p}><path d="M2 9a16 16 0 0 1 20 0M5 13a10 10 0 0 1 14 0M8.5 16.5a5 5 0 0 1 7 0"/><circle cx="12" cy="20" r="0.8" fill="currentColor"/></Icon>,
  WifiOff: (p) => <Icon {...p}><path d="M2 9a16 16 0 0 1 8.5-4.4M22 9a16 16 0 0 0-4.5-3.2M5 13a10 10 0 0 1 4-2.7M19 13a10 10 0 0 0-2.8-1.7M8.5 16.5a5 5 0 0 1 7 0M3 3l18 18"/></Icon>,
  Bolt:    (p) => <Icon {...p}><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/></Icon>,
  Logout:  (p) => <Icon {...p}><path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 17l5-5-5-5M15 12H3"/></Icon>,
  Coin:    (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/><path d="M12 9v6"/></Icon>,
  Key:     (p) => <Icon {...p}><circle cx="8" cy="15" r="4"/><path d="M11 13l9-9M16 7l3 3M14 10l2 2"/></Icon>,
  Joystick:(p) => <Icon {...p}><path d="M12 3v9M9 12h6M5 18l3-2h8l3 2v3H5v-3z"/><circle cx="12" cy="3" r="2"/></Icon>,
  Check:   (p) => <Icon {...p}><path d="M5 12l4 4 10-10"/></Icon>,
  Layers:  (p) => <Icon {...p}><path d="M12 3l10 5-10 5L2 8l10-5zM2 13l10 5 10-5M2 18l10 5 10-5"/></Icon>,
  Compass: (p) => <Icon {...p}><circle cx="12" cy="12" r="9"/><path d="M16 8l-2 6-6 2 2-6 6-2z" fill="currentColor" fillOpacity="0.25"/></Icon>,
};

// ─────────────────────────────────────────────────────────────
// NebulaOrb — the brand mark, abstract rotating cosmic ring
// ─────────────────────────────────────────────────────────────
function NebulaOrb({ size = 96, spin = true }) {
  const ringStyle = (delay = 0) => ({
    position: 'absolute', inset: 0,
    animation: spin ? `forgeSpin 18s linear infinite ${delay}s` : 'none',
  });
  return (
    <div style={{ width: size, height: size, position: 'relative' }}>
      <style>{`
        @keyframes forgeSpin { from{transform:rotate(0)} to{transform:rotate(360deg)} }
        @keyframes forgeSpinR { from{transform:rotate(360deg)} to{transform:rotate(0)} }
        @keyframes forgePulse { 0%,100%{opacity:.9} 50%{opacity:.5} }
      `}</style>
      {/* outer glow */}
      <div style={{
        position: 'absolute', inset: '-15%', borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(123,92,255,0.55) 0%, rgba(79,201,232,0.2) 35%, transparent 65%)',
        filter: 'blur(6px)',
      }} />
      {/* core */}
      <div style={{
        position: 'absolute', inset: '28%', borderRadius: '50%',
        background: 'radial-gradient(circle at 35% 35%, #fff 0%, #c8b8ff 18%, #7b5cff 55%, #2a1a6a 100%)',
        boxShadow: '0 0 24px rgba(123,92,255,0.7), inset -2px -4px 12px rgba(0,0,0,0.5)',
        animation: 'forgePulse 4s ease-in-out infinite',
      }} />
      {/* rings */}
      <svg viewBox="0 0 100 100" style={ringStyle(0)}>
        <ellipse cx="50" cy="50" rx="46" ry="14" stroke="rgba(154,125,255,0.55)" strokeWidth="0.7" fill="none" transform="rotate(-22 50 50)"/>
        <circle cx="96" cy="50" r="1.4" fill="#9beaff" transform="rotate(-22 50 50)"/>
      </svg>
      <svg viewBox="0 0 100 100" style={{...ringStyle(0), animation: spin ? 'forgeSpinR 26s linear infinite' : 'none'}}>
        <ellipse cx="50" cy="50" rx="44" ry="20" stroke="rgba(79,201,232,0.45)" strokeWidth="0.6" fill="none" transform="rotate(35 50 50)"/>
        <circle cx="6" cy="50" r="1.1" fill="#c8b8ff" transform="rotate(35 50 50)"/>
      </svg>
      <svg viewBox="0 0 100 100" style={{...ringStyle(0), animation: spin ? 'forgeSpin 34s linear infinite' : 'none'}}>
        <ellipse cx="50" cy="50" rx="48" ry="6" stroke="rgba(255,255,255,0.18)" strokeWidth="0.5" fill="none" transform="rotate(70 50 50)"/>
      </svg>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Phone — dark cosmic device frame
// ─────────────────────────────────────────────────────────────
function ForgePhone({ children, width = 402, height = 874, scale = 1, frameless = false }) {
  return (
    <div style={{
      width: width * scale, height: height * scale, position: 'relative',
    }}>
      <div style={{
        width, height, position: 'absolute', top: 0, left: 0,
        transform: `scale(${scale})`, transformOrigin: 'top left',
        borderRadius: 54, overflow: 'hidden',
        background: '#000',
        boxShadow: '0 0 0 6px #0a0916, 0 0 0 7px rgba(255,255,255,0.06), 0 40px 80px rgba(0,0,0,0.6), 0 0 40px rgba(123,92,255,0.08)',
        fontFamily: 'var(--font-sf)',
      }}>
        {/* cosmic bg */}
        <div className="forge-bg" />
        {/* dynamic island */}
        <div style={{
          position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
          width: 122, height: 36, borderRadius: 24, background: '#000', zIndex: 100,
        }} />
        {/* status bar */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 50 }}>
          <IOSStatusBar dark />
        </div>
        {/* home indicator */}
        <div style={{
          position: 'absolute', bottom: 8, left: 0, right: 0, zIndex: 90,
          display: 'flex', justifyContent: 'center', pointerEvents: 'none',
        }}>
          <div style={{ width: 139, height: 5, borderRadius: 100, background: 'rgba(255,255,255,0.55)' }} />
        </div>
        {/* content */}
        <div style={{ position: 'absolute', inset: 0, zIndex: 10 }}>
          {children}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Top nav — transparent glass over cosmic bg
// ─────────────────────────────────────────────────────────────
function ForgeNav({ title, leading, trailing, large = false, subtitle }) {
  return (
    <div style={{
      paddingTop: 56, paddingLeft: 20, paddingRight: 20, paddingBottom: 8,
      position: 'relative', zIndex: 5,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        minHeight: 36,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>{leading}</div>
        {!large && <div style={{
          position: 'absolute', left: 0, right: 0, textAlign: 'center',
          fontSize: 17, fontWeight: 600, color: 'var(--forge-text-1)',
          pointerEvents: 'none',
        }}>{title}</div>}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{trailing}</div>
      </div>
      {large && (
        <div style={{ marginTop: 14 }}>
          <div style={{
            fontSize: 32, fontWeight: 700, color: 'var(--forge-text-1)',
            letterSpacing: -0.6, lineHeight: 1.05,
          }}>{title}</div>
          {subtitle && <div style={{
            marginTop: 6, fontSize: 13, color: 'var(--forge-text-3)', letterSpacing: 0.2,
          }}>{subtitle}</div>}
        </div>
      )}
    </div>
  );
}

// Round glass icon button (for nav trailing/leading)
function IconBtn({ children, glow, onClick, size = 36, style = {} }) {
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: size/2,
      background: glow ? 'linear-gradient(180deg, rgba(155,128,255,0.35), rgba(123,92,255,0.18))'
                       : 'rgba(255,255,255,0.06)',
      border: glow ? '0.5px solid rgba(154,125,255,0.5)' : '0.5px solid rgba(255,255,255,0.1)',
      backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)',
      color: 'var(--forge-text-1)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      cursor: 'pointer', padding: 0,
      boxShadow: glow ? '0 4px 16px rgba(123,92,255,0.35), inset 0 1px 0 rgba(255,255,255,0.15)'
                      : 'inset 0 1px 0 rgba(255,255,255,0.05)',
      ...style,
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────
// Tab bar — floating liquid glass capsule
// ─────────────────────────────────────────────────────────────
function ForgeTabBar({ active = 'projects' }) {
  const tabs = [
    { id: 'projects', label: '项目', icon: <I.Stack size={22} stroke={1.7} /> },
    { id: 'gallery',  label: '作品', icon: <I.Grid size={22} stroke={1.7} /> },
    { id: 'control',  label: '控制', icon: <I.Settings size={22} stroke={1.7} /> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 24, left: 0, right: 0,
      display: 'flex', justifyContent: 'center', zIndex: 40,
      pointerEvents: 'none',
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 4,
        padding: 6, borderRadius: 999,
        background: 'rgba(20,18,40,0.55)',
        border: '0.5px solid rgba(255,255,255,0.12)',
        backdropFilter: 'blur(28px) saturate(180%)',
        WebkitBackdropFilter: 'blur(28px) saturate(180%)',
        boxShadow:
          '0 16px 40px rgba(0,0,0,0.55), inset 0 1px 0 rgba(255,255,255,0.1)',
        pointerEvents: 'auto',
      }}>
        {tabs.map(t => {
          const on = t.id === active;
          return (
            <div key={t.id} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 1, padding: '8px 18px', borderRadius: 999,
              minWidth: 70,
              background: on
                ? 'linear-gradient(180deg, rgba(155,128,255,0.32), rgba(79,201,232,0.18))'
                : 'transparent',
              border: on ? '0.5px solid rgba(154,125,255,0.4)' : '0.5px solid transparent',
              boxShadow: on ? '0 4px 16px rgba(123,92,255,0.4), inset 0 1px 0 rgba(255,255,255,0.18)' : 'none',
              color: on ? '#fff' : 'var(--forge-text-3)',
              filter: on ? 'drop-shadow(0 0 6px rgba(154,125,255,0.6))' : 'none',
            }}>
              {t.icon}
              <div style={{ fontSize: 10.5, fontWeight: on ? 600 : 500, marginTop: 2 }}>{t.label}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Generic glass card
// ─────────────────────────────────────────────────────────────
function GlassCard({ children, style = {}, padding = 16, radius = 22, glow = false, stroke = 'default' }) {
  const strokes = {
    default: 'rgba(255,255,255,0.09)',
    violet:  'rgba(154,125,255,0.32)',
    cyan:    'rgba(79,201,232,0.32)',
  };
  return (
    <div style={{
      background: 'rgba(255,255,255,0.045)',
      border: `0.5px solid ${strokes[stroke]}`,
      borderRadius: radius,
      backdropFilter: 'blur(18px) saturate(140%)',
      WebkitBackdropFilter: 'blur(18px) saturate(140%)',
      padding,
      boxShadow: glow
        ? 'inset 0 1px 0 rgba(255,255,255,0.07), 0 8px 28px rgba(123,92,255,0.18)'
        : 'inset 0 1px 0 rgba(255,255,255,0.06), 0 8px 24px rgba(0,0,0,0.32)',
      ...style,
    }}>{children}</div>
  );
}

// Chip — small rounded status pill
function Chip({ children, tone = 'neutral', dot = false, style = {} }) {
  const tones = {
    neutral: { bg: 'rgba(255,255,255,0.07)', bd: 'rgba(255,255,255,0.12)', fg: 'var(--forge-text-2)', dot: '#9a7dff' },
    online:  { bg: 'rgba(91,231,167,0.10)', bd: 'rgba(91,231,167,0.32)', fg: '#9af5c8', dot: '#5be7a7' },
    offline: { bg: 'rgba(255,255,255,0.06)', bd: 'rgba(255,255,255,0.12)', fg: 'var(--forge-text-3)', dot: 'rgba(255,255,255,0.4)' },
    violet:  { bg: 'rgba(154,125,255,0.14)', bd: 'rgba(154,125,255,0.36)', fg: '#cbb8ff', dot: '#9a7dff' },
    cyan:    { bg: 'rgba(79,201,232,0.12)', bd: 'rgba(79,201,232,0.36)', fg: '#9beaff', dot: '#4fc9e8' },
    gold:    { bg: 'rgba(242,195,107,0.14)', bd: 'rgba(242,195,107,0.36)', fg: '#ffd99e', dot: '#f2c36b' },
    draft:   { bg: 'rgba(255,255,255,0.05)', bd: 'rgba(255,255,255,0.12)', fg: 'rgba(244,241,255,0.55)', dot: 'rgba(255,255,255,0.4)' },
  };
  const t = tones[tone] || tones.neutral;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '4px 10px', borderRadius: 999,
      background: t.bg, border: `0.5px solid ${t.bd}`,
      color: t.fg, fontSize: 11, fontWeight: 600, letterSpacing: 0.1,
      ...style,
    }}>
      {dot && <span style={{ width: 6, height: 6, borderRadius: 3, background: t.dot, boxShadow: `0 0 6px ${t.dot}` }} />}
      {children}
    </span>
  );
}

// Energy bar — used for creative dimensions
function EnergyBar({ value = 0.5, color = 'violet', height = 4 }) {
  const colors = {
    violet: 'linear-gradient(90deg, #7b5cff, #9beaff)',
    cyan:   'linear-gradient(90deg, #4fc9e8, #9beaff)',
    gold:   'linear-gradient(90deg, #f2c36b, #ffe7b0)',
  };
  return (
    <div style={{
      height, background: 'rgba(255,255,255,0.08)', borderRadius: 999,
      overflow: 'hidden', position: 'relative',
    }}>
      <div style={{
        width: `${value * 100}%`, height: '100%',
        background: colors[color], borderRadius: 999,
        boxShadow: `0 0 8px rgba(154,125,255,0.6)`,
      }} />
    </div>
  );
}

// Project icon — small nebula seed
function NebulaSeed({ size = 44, hue = 0 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 12,
      background: `
        radial-gradient(circle at 30% 30%, rgba(255,255,255,0.5) 0%, transparent 35%),
        radial-gradient(circle at 70% 70%, rgba(79,201,232,0.4) 0%, transparent 45%),
        linear-gradient(135deg, hsl(${260+hue} 70% 45%) 0%, hsl(${220+hue} 70% 20%) 100%)
      `,
      border: '0.5px solid rgba(255,255,255,0.16)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.18), 0 4px 12px rgba(0,0,0,0.4)',
      position: 'relative', overflow: 'hidden', flexShrink: 0,
    }}>
      <svg viewBox="0 0 44 44" style={{ position: 'absolute', inset: 0 }}>
        <ellipse cx="22" cy="22" rx="18" ry="6" stroke="rgba(255,255,255,0.3)" strokeWidth="0.6" fill="none" transform={`rotate(${-30+hue*3} 22 22)`}/>
        <circle cx="22" cy="22" r="3" fill="rgba(255,255,255,0.95)"/>
      </svg>
    </div>
  );
}

// Star ring loader
function StarRing({ size = 56 }) {
  return (
    <div style={{ width: size, height: size, position: 'relative' }}>
      <style>{`@keyframes forgeRing { to { transform: rotate(360deg) } }`}</style>
      <svg viewBox="0 0 56 56" style={{ animation: 'forgeRing 1.8s linear infinite', filter: 'drop-shadow(0 0 6px rgba(154,125,255,0.7))' }}>
        <defs>
          <linearGradient id="ringG" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#7b5cff"/>
            <stop offset="60%" stopColor="#4fc9e8"/>
            <stop offset="100%" stopColor="transparent"/>
          </linearGradient>
        </defs>
        <circle cx="28" cy="28" r="22" stroke="rgba(255,255,255,0.08)" strokeWidth="2" fill="none"/>
        <circle cx="28" cy="28" r="22" stroke="url(#ringG)" strokeWidth="2.4" fill="none" strokeLinecap="round" strokeDasharray="80 60"/>
      </svg>
    </div>
  );
}

Object.assign(window, {
  Icon, I, NebulaOrb, ForgePhone, ForgeNav, IconBtn, ForgeTabBar,
  GlassCard, Chip, EnergyBar, NebulaSeed, StarRing,
});
