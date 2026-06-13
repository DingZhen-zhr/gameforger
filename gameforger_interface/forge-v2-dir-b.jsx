/* @jsx React.createElement */
// Direction B · 编辑工坊派
// Reference: Magazine + Terminal hybrid
// 准则: Serif 大标题, Mono 标签, 米色纸感, 克制森林绿

// ─────────────────────────────────────────────────────────────
// Atoms
// ─────────────────────────────────────────────────────────────

// Editorial nav with mono kicker + serif title
const NavB = ({ kicker, title, subtitle, leading, trailing }) => (
  <div style={{ padding: '54px 18px 10px' }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', minHeight: 28, marginBottom: 8 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>{leading}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{trailing}</div>
    </div>
    {kicker && <div style={{
      fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 1.4,
      textTransform: 'uppercase', color: 'var(--text-3)',
    }}>{kicker}</div>}
    {title && <div style={{
      fontFamily: 'var(--font-display)', fontSize: 44, lineHeight: 1, fontWeight: 400,
      color: 'var(--text-1)', letterSpacing: -1.2, marginTop: kicker ? 4 : 0,
    }}>{title}</div>}
    {subtitle && <div style={{ marginTop: 8, fontSize: 13, color: 'var(--text-2)', lineHeight: 1.5 }}>{subtitle}</div>}
  </div>
);

const IconBtnB = ({ children, accent, onClick }) => (
  <button onClick={onClick} style={{
    width: 36, height: 36, borderRadius: 12,
    background: accent ? 'var(--accent)' : 'transparent',
    color: accent ? 'var(--accent-fg)' : 'var(--text-1)',
    border: accent ? 'none' : '0.5px solid var(--line-strong)',
    cursor: 'pointer', padding: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>{children}</button>
);

// Mono kicker label (used everywhere as a section divider)
const Kicker = ({ children, right, style = {} }) => (
  <div style={{
    display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
    padding: '0 18px 8px', ...style,
  }}>
    <span style={{
      fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 1.6,
      textTransform: 'uppercase', color: 'var(--text-3)',
    }}>{children}</span>
    {right && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10.5, color: 'var(--text-3)', letterSpacing: 0.4 }}>{right}</span>}
  </div>
);

// Editorial chip — squared, mono
const ChipB = ({ children, tone = 'neutral' }) => {
  const tones = {
    neutral: { bg: 'transparent', fg: 'var(--text-2)', bd: 'var(--line-strong)' },
    accent:  { bg: 'var(--accent-tint)', fg: 'var(--accent)', bd: 'var(--accent-line)' },
    warn:    { bg: 'transparent', fg: 'var(--warn)', bd: 'var(--warn)' },
  };
  const t = tones[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '2px 7px', borderRadius: 4,
      background: t.bg, color: t.fg,
      border: `0.5px solid ${t.bd}`,
      fontFamily: 'var(--font-mono)', fontSize: 10.5, fontWeight: 500, letterSpacing: 0.4, textTransform: 'uppercase',
    }}>{children}</span>
  );
};

// Bottom tab bar — editorial flat style
const TabBarB = ({ active }) => {
  const tabs = [
    { id: 'projects', label: 'PROJECTS', icon: <I2.Layers size={20} stroke={1.6}/> },
    { id: 'gallery',  label: 'WORKS', icon: <I2.Grid size={20} stroke={1.6}/> },
    { id: 'control',  label: 'PROFILE', icon: <I2.Person size={20} stroke={1.6}/> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 30,
      background: 'var(--bg)',
      borderTop: '0.5px solid var(--line-strong)',
      paddingBottom: 28, paddingTop: 10,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-around' }}>
        {tabs.map(t => {
          const on = t.id === active;
          return (
            <div key={t.id} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              color: on ? 'var(--accent)' : 'var(--text-3)',
              padding: '0 18px', position: 'relative',
            }}>
              {t.icon}
              <div style={{
                fontFamily: 'var(--font-mono)', fontSize: 9.5, fontWeight: 600, letterSpacing: 0.8,
              }}>{t.label}</div>
              {on && <div style={{
                position: 'absolute', top: -10, width: 14, height: 2,
                background: 'var(--accent)',
              }}/>}
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// SCREEN: Splash (B)
// ─────────────────────────────────────────────────────────────
function SplashB({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', background: 'var(--bg)', padding: '60px 30px 50px' }}>
      <div style={{
        fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 1.6,
        textTransform: 'uppercase', color: 'var(--text-3)', textAlign: 'right',
      }}>ISSUE 1.4 · 2026</div>

      <div>
        <ForgeMarkB size={44} accent="var(--accent)"/>
        <div style={{
          marginTop: 24, fontFamily: 'var(--font-display)',
          fontSize: 78, lineHeight: 0.92, fontWeight: 400, color: 'var(--text-1)', letterSpacing: -2.5,
        }}>
          Game<br/>
          <em style={{ fontStyle: 'italic', color: 'var(--accent)' }}>Forger</em>
        </div>
        <div style={{
          marginTop: 24, paddingTop: 18, borderTop: '0.5px solid var(--line-strong)',
          fontSize: 14, color: 'var(--text-2)', lineHeight: 1.55,
        }}>
          A workshop for ideas that<br/>
          want to become games.
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 10, height: 10, borderRadius: 5,
            border: '1.5px solid var(--text-3)', borderTopColor: 'var(--accent)',
            animation: 'spinB 0.9s linear infinite',
          }}/>
          <style>{`@keyframes spinB { to { transform: rotate(360deg) } }`}</style>
          <span style={{
            fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 0.8,
            color: 'var(--text-3)',
          }}>BOOTING WORKSHOP…</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Projects (B)
// ─────────────────────────────────────────────────────────────
function ProjectsB({ theme }) {
  const projects = [
    { num: '01', name: '霓虹漂流', tag: 'ARCADE', meta: 'TODAY 14:32', state: 'PLAYABLE' },
    { num: '02', name: '星核守卫者', tag: 'TOWER', meta: 'YESTERDAY 21:08', state: 'PLAYABLE' },
    { num: '03', name: '深渊回响', tag: 'EXPLORE', meta: '3 DAYS AGO', state: 'DRAFT' },
    { num: '04', name: '像素厨房物语', tag: 'SIM', meta: '5 DAYS AGO', state: 'PLAYABLE' },
    { num: '05', name: '量子俄罗斯方块', tag: 'PUZZLE', meta: '1 WEEK AGO', state: 'PLAYABLE' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavB kicker="WORKSHOP // PROJECTS" title="Projects."
        leading={<ForgeMarkB size={22} color="var(--text-1)" accent="var(--accent)"/>}
        trailing={<>
          <IconBtnB><I2.Search size={16}/></IconBtnB>
          <IconBtnB accent><I2.Plus size={16} stroke={2.4}/></IconBtnB>
        </>}
      />

      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 110 }}>

        {/* Stats row — editorial */}
        <div style={{ padding: '4px 18px 24px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', borderTop: '0.5px solid var(--line-strong)', borderBottom: '0.5px solid var(--line-strong)' }}>
            {[
              { v: '12', l: 'TOTAL' },
              { v: '08', l: 'PLAYABLE', a: true },
              { v: '03', l: 'DRAFT' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: '14px 0',
                borderLeft: i > 0 ? '0.5px solid var(--line-strong)' : 'none',
                paddingLeft: i > 0 ? 16 : 0,
              }}>
                <div style={{
                  fontFamily: 'var(--font-display)', fontSize: 34, lineHeight: 1,
                  color: s.a ? 'var(--accent)' : 'var(--text-1)', letterSpacing: -1, fontVariantNumeric: 'tabular-nums',
                }}>{s.v}</div>
                <div style={{
                  marginTop: 4, fontFamily: 'var(--font-mono)', fontSize: 9.5,
                  color: 'var(--text-3)', letterSpacing: 1, fontWeight: 600,
                }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        <Kicker right="↓ NEWEST">Recent</Kicker>

        {/* List — index style */}
        <div style={{ padding: '0 18px' }}>
          {projects.map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'baseline', gap: 14, padding: '14px 0',
              borderTop: i === 0 ? '0.5px solid var(--line-strong)' : '0.5px solid var(--line)',
              borderBottom: i === projects.length - 1 ? '0.5px solid var(--line-strong)' : 'none',
            }}>
              <div style={{
                width: 28, fontFamily: 'var(--font-mono)', fontSize: 11,
                color: 'var(--text-3)', letterSpacing: 0.6,
              }}>{p.num}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                  <div style={{
                    fontFamily: 'var(--font-display)', fontSize: 22, lineHeight: 1.1,
                    color: 'var(--text-1)', letterSpacing: -0.4,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  }}>{p.name}</div>
                </div>
                <div style={{
                  marginTop: 4, display: 'flex', alignItems: 'center', gap: 8,
                  fontFamily: 'var(--font-mono)', fontSize: 10.5, color: 'var(--text-3)', letterSpacing: 0.5,
                }}>
                  <span>{p.tag}</span>
                  <span style={{ width: 3, height: 3, borderRadius: 2, background: 'var(--text-4)' }}/>
                  <span>{p.meta}</span>
                </div>
              </div>
              <ChipB tone={p.state === 'DRAFT' ? 'neutral' : 'accent'}>{p.state}</ChipB>
            </div>
          ))}
        </div>
      </div>
      <TabBarB active="projects"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Gallery (B)
// ─────────────────────────────────────────────────────────────
function GalleryB({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavB kicker="WORKSHOP // WORKS" title="Works."
        leading={<ForgeMarkB size={22} color="var(--text-1)" accent="var(--accent)"/>}
        subtitle="24 件已生成 · 18 件已发布"
        trailing={<IconBtnB><I2.More size={16}/></IconBtnB>}
      />

      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 110 }}>

        {/* Featured — magazine cover style */}
        <Kicker right="01 / 24">Featured</Kicker>
        <div style={{ padding: '0 18px 28px' }}>
          <div style={{
            border: '0.5px solid var(--line-strong)', borderRadius: 12, overflow: 'hidden',
            background: 'var(--surface)',
          }}>
            <div style={{
              height: 220, position: 'relative', overflow: 'hidden',
              background: theme === 'dark' ? '#0F1F12' : '#E7F0DC',
            }}>
              <svg viewBox="0 0 360 220" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
                {[...Array(14)].map((_, i) => (
                  <circle key={i} cx={25 + i*24} cy={90 + Math.sin(i*0.8)*22} r="2"
                    fill={theme === 'dark' ? '#5BC078' : '#1E7A3E'} opacity={0.5 + (i%3)*0.15}/>
                ))}
                <path d="M40 150 Q180 110 320 145" stroke={theme === 'dark' ? '#5BC078' : '#1E7A3E'} strokeWidth="1.4" fill="none" opacity="0.7"/>
                <path d="M40 160 Q180 125 320 155" stroke={theme === 'dark' ? '#5BC078' : '#1E7A3E'} strokeWidth="1" fill="none" opacity="0.4"/>
              </svg>
              <div style={{
                position: 'absolute', top: 12, left: 12,
                fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: 1.2,
                color: theme === 'dark' ? '#F4ECD8' : '#16140E',
                background: theme === 'dark' ? 'rgba(0,0,0,0.4)' : 'rgba(255,255,255,0.7)',
                padding: '3px 7px', borderRadius: 4,
              }}>NEWEST · 5 MIN AGO</div>
            </div>
            <div style={{ padding: '20px 18px 18px' }}>
              <div style={{
                fontFamily: 'var(--font-display)', fontSize: 30, lineHeight: 1.05,
                color: 'var(--text-1)', letterSpacing: -0.6, fontStyle: 'italic',
              }}>霓虹漂流</div>
              <div style={{
                marginTop: 8, fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 0.8,
                color: 'var(--text-3)', textTransform: 'uppercase',
              }}>Arcade · Phaser 3 · 9.2 KB</div>
              <div style={{ marginTop: 10, fontSize: 13.5, color: 'var(--text-2)', lineHeight: 1.55 }}>
                左右滑动避开磁轨上的霓虹方块，吸附能量碎片，撞墙就 GG。
              </div>
              <button style={{
                marginTop: 14, height: 40, padding: '0 16px', borderRadius: 8,
                background: 'var(--accent)', color: 'var(--accent-fg)', border: 'none', cursor: 'pointer',
                display: 'inline-flex', alignItems: 'center', gap: 8,
                fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 600, letterSpacing: 1,
              }}>
                <I2.Play size={11}/>PLAY ↗
              </button>
            </div>
          </div>
        </div>

        <Kicker right="↓ DATE">All Works</Kicker>
        <div style={{ padding: '0 18px' }}>
          {[
            { num: '02', name: '星核守卫者', meta: 'TOWER · 2 H AGO' },
            { num: '03', name: '像素厨房物语', meta: 'SIM · YESTERDAY' },
            { num: '04', name: '量子俄罗斯方块', meta: 'PUZZLE · 3 D AGO' },
            { num: '05', name: '深渊回响', meta: 'EXPLORE · DRAFT', draft: true },
          ].map((w, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'baseline', gap: 14, padding: '14px 0',
              borderTop: i === 0 ? '0.5px solid var(--line-strong)' : '0.5px solid var(--line)',
              borderBottom: i === arr.length - 1 ? '0.5px solid var(--line-strong)' : 'none',
            }}>
              <div style={{ width: 28, fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-3)' }}>{w.num}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'var(--font-display)', fontSize: 20, color: 'var(--text-1)', letterSpacing: -0.3, lineHeight: 1.1 }}>
                  {w.name}
                </div>
                <div style={{ marginTop: 3, fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-3)', letterSpacing: 0.6 }}>
                  {w.meta}
                </div>
              </div>
              {w.draft ? <ChipB>DRAFT</ChipB> : <I2.Chev size={14} color="var(--text-2)" stroke={1.8}/>}
            </div>
          ))}
        </div>
      </div>
      <TabBarB active="gallery"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Settings / Profile (B)
// ─────────────────────────────────────────────────────────────
function SettingsB({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavB kicker="WORKSHOP // PROFILE" title="Profile."
        leading={<ForgeMarkB size={22} color="var(--text-1)" accent="var(--accent)"/>}
        trailing={<IconBtnB><I2.More size={16}/></IconBtnB>}
      />

      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 110 }}>

        {/* Identity block — editorial card */}
        <div style={{ padding: '4px 18px 24px' }}>
          <div style={{
            border: '0.5px solid var(--line-strong)', borderRadius: 12, padding: 18,
            background: 'var(--surface)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{
                width: 54, height: 54, borderRadius: 27,
                border: '0.5px solid var(--line-strong)',
                background: 'var(--accent-tint)', color: 'var(--accent)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: 'var(--font-display)', fontSize: 28, fontWeight: 400, fontStyle: 'italic',
              }}>a</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: 'var(--font-display)', fontSize: 22, color: 'var(--text-1)', letterSpacing: -0.3 }}>alex</div>
                <div style={{ marginTop: 2, fontFamily: 'var(--font-mono)', fontSize: 10.5, color: 'var(--text-3)', letterSpacing: 0.4 }}>
                  ALEX@GAMEFORGER.APP
                </div>
              </div>
              <I2.Edit size={16} color="var(--text-2)" stroke={1.6}/>
            </div>

            <div style={{ marginTop: 18, paddingTop: 14, borderTop: '0.5px solid var(--line)', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4 }}>
              <div>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9.5, color: 'var(--text-3)', letterSpacing: 1, fontWeight: 600 }}>CREDITS</div>
                <div style={{
                  marginTop: 4, fontFamily: 'var(--font-display)', fontSize: 28, lineHeight: 1,
                  color: 'var(--accent)', letterSpacing: -0.5, fontVariantNumeric: 'tabular-nums',
                }}>1,240</div>
              </div>
              <div>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 9.5, color: 'var(--text-3)', letterSpacing: 1, fontWeight: 600 }}>SHIPPED</div>
                <div style={{
                  marginTop: 4, fontFamily: 'var(--font-display)', fontSize: 28, lineHeight: 1,
                  color: 'var(--text-1)', letterSpacing: -0.5, fontVariantNumeric: 'tabular-nums',
                }}>08</div>
              </div>
            </div>
          </div>
        </div>

        <Kicker>Configuration</Kicker>
        <div style={{ padding: '0 18px' }}>
          {[
            { l: 'API CONFIGURATION', d: '4 MODELS · CLAUDE / GEMINI / GPT' },
            { l: 'APPEARANCE', d: theme === 'dark' ? 'DARK MODE' : 'LIGHT MODE' },
            { l: 'NOTIFICATIONS', d: 'ON' },
          ].map((r, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 0',
              borderTop: i === 0 ? '0.5px solid var(--line-strong)' : '0.5px solid var(--line)',
              borderBottom: i === arr.length - 1 ? '0.5px solid var(--line-strong)' : 'none',
            }}>
              <div>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11.5, fontWeight: 600, color: 'var(--text-1)', letterSpacing: 0.8 }}>
                  {r.l}
                </div>
                <div style={{ marginTop: 3, fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-3)', letterSpacing: 0.6 }}>
                  {r.d}
                </div>
              </div>
              <I2.Chev size={14} color="var(--text-2)" stroke={1.8}/>
            </div>
          ))}
        </div>

        <div style={{ height: 18 }}/>

        <Kicker>System</Kicker>
        <div style={{ padding: '0 18px' }}>
          {[
            { l: 'ABOUT', d: 'GAMEFORGER 1.4.0 / BUILD 2026.05' },
            { l: 'SIGN OUT', d: 'END SESSION', danger: true },
          ].map((r, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 0',
              borderTop: i === 0 ? '0.5px solid var(--line-strong)' : '0.5px solid var(--line)',
              borderBottom: i === arr.length - 1 ? '0.5px solid var(--line-strong)' : 'none',
            }}>
              <div>
                <div style={{
                  fontFamily: 'var(--font-mono)', fontSize: 11.5, fontWeight: 600,
                  color: r.danger ? 'var(--bad)' : 'var(--text-1)', letterSpacing: 0.8,
                }}>{r.l}</div>
                <div style={{ marginTop: 3, fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-3)', letterSpacing: 0.6 }}>
                  {r.d}
                </div>
              </div>
              {!r.danger && <I2.Chev size={14} color="var(--text-2)" stroke={1.8}/>}
            </div>
          ))}
        </div>

        <div style={{
          textAlign: 'center', marginTop: 30, fontFamily: 'var(--font-mono)', fontSize: 9.5,
          color: 'var(--text-4)', letterSpacing: 1.4,
        }}>GAMEFORGER · WORKSHOP 1.4 · 2026.05</div>
      </div>
      <TabBarB active="control"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Workspace (B) — placeholder, replaced by shared FanWorkspace
// ─────────────────────────────────────────────────────────────
function WorkspaceB({ theme }) {
  return (
    <div style={{ height: '100%', background: 'var(--bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-3)' }}>
      Workspace B placeholder
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Preview (B)
// ─────────────────────────────────────────────────────────────
function PreviewB({ theme }) {
  const [tab, setTab] = React.useState('code');
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <div style={{ paddingTop: 54, padding: '54px 14px 10px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <IconBtnB><I2.ChevL size={16}/></IconBtnB>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontFamily: 'var(--font-mono)', fontSize: 9.5, letterSpacing: 1.2,
            color: 'var(--text-3)',
          }}>PREVIEW // RUN.01</div>
          <div style={{
            fontFamily: 'var(--font-display)', fontSize: 22, lineHeight: 1.1,
            color: 'var(--text-1)', letterSpacing: -0.3, fontStyle: 'italic',
          }}>霓虹漂流</div>
        </div>
        <IconBtnB><I2.Volume size={14}/></IconBtnB>
        <IconBtnB><I2.Expand size={14}/></IconBtnB>
      </div>

      {/* Status strip */}
      <div style={{
        padding: '6px 18px', display: 'flex', alignItems: 'center', gap: 14,
        borderTop: '0.5px solid var(--line-strong)',
        borderBottom: '0.5px solid var(--line-strong)',
        fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: 0.8, color: 'var(--text-3)',
      }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--good)' }}/>
          RUNNING
        </span>
        <span>PHASER 3</span>
        <span style={{ marginLeft: 'auto' }}>60 FPS</span>
      </div>

      {/* canvas */}
      <div style={{ padding: '14px 18px 8px' }}>
        <div style={{
          height: 200, borderRadius: 10, overflow: 'hidden', position: 'relative',
          background: '#0B0F08', border: '0.5px solid var(--line-strong)',
        }}>
          <svg viewBox="0 0 360 200" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
            <defs>
              <linearGradient id="floorB" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#5BC078" stopOpacity="0"/>
                <stop offset="100%" stopColor="#5BC078" stopOpacity="0.55"/>
              </linearGradient>
              <radialGradient id="sunB" cx="0.5" cy="0.5" r="0.5">
                <stop offset="0%" stopColor="#FFB060"/>
                <stop offset="100%" stopColor="#FF6A3D" stopOpacity="0"/>
              </radialGradient>
            </defs>
            <circle cx="180" cy="85" r="50" fill="url(#sunB)"/>
            <line x1="0" y1="115" x2="360" y2="115" stroke="#5BC078" strokeWidth="0.7"/>
            <g stroke="url(#floorB)" strokeWidth="0.6" fill="none">
              {[0,1,2,3,4,5,6,7,8].map(i => <line key={i} x1={-200+i*100} y1="200" x2="180" y2="115"/>)}
              {[0,1,2,3,4,5,6,7,8].map(i => <line key={i} x1={180+i*100-200} y1="115" x2={560-i*100} y2="200"/>)}
            </g>
            <g transform="translate(170 158)">
              <rect x="0" y="0" width="20" height="14" rx="3" fill="#5BC078"/>
              <rect x="4" y="-4" width="12" height="6" rx="2" fill="#fff"/>
            </g>
          </svg>
        </div>
      </div>

      {/* Tab strip */}
      <div style={{
        display: 'flex', padding: '0 18px', gap: 18,
        borderBottom: '0.5px solid var(--line-strong)', marginTop: 6,
      }}>
        {[
          { id: 'code', label: 'CODE' },
          { id: 'chat', label: 'CHAT' },
          { id: 'asset', label: 'ASSETS' },
          { id: 'info', label: 'META' },
        ].map(t => {
          const on = t.id === tab;
          return (
            <div key={t.id} onClick={() => setTab(t.id)} style={{
              padding: '10px 0', cursor: 'pointer', position: 'relative',
              fontFamily: 'var(--font-mono)', fontSize: 11, fontWeight: 600, letterSpacing: 1,
              color: on ? 'var(--text-1)' : 'var(--text-3)',
            }}>
              {t.label}
              {on && <div style={{ position: 'absolute', left: 0, right: 0, bottom: -1, height: 2, background: 'var(--accent)' }}/>}
            </div>
          );
        })}
      </div>

      {/* Code panel */}
      <div style={{ flex: 1, padding: '14px 18px 16px', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{
            fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 0.6,
            color: 'var(--text-2)', display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{ width: 6, height: 6, background: 'var(--accent)' }}/>
            index.html · 248 LINES
          </div>
          <button style={{
            height: 26, padding: '0 12px', border: 'none', cursor: 'pointer',
            background: 'var(--accent)', color: 'var(--accent-fg)',
            fontFamily: 'var(--font-mono)', fontSize: 10.5, fontWeight: 600, letterSpacing: 0.8,
            borderRadius: 4,
          }}>APPLY ↵</button>
        </div>
        <div style={{
          flex: 1, borderRadius: 6, overflow: 'hidden',
          background: theme === 'dark' ? '#0A0907' : '#FAF7F0',
          border: '0.5px solid var(--line-strong)',
          fontFamily: 'var(--font-mono)', fontSize: 10.5, lineHeight: 1.55,
          padding: '10px 0',
        }}>
          <CodeViewA theme={theme}/>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SplashB, ProjectsB, GalleryB, SettingsB, WorkspaceB, PreviewB });
