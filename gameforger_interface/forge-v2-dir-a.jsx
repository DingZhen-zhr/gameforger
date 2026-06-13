/* @jsx React.createElement */
// Direction A · iOS 原生派
// Reference: iOS 26 Settings / Reminders / Notes / Messages
// 准则: 分组列表, 大标题, 单一绿色强调, 静谧

// ─────────────────────────────────────────────────────────────
// Atoms
// ─────────────────────────────────────────────────────────────

// iOS large-title nav (scrollable header)
const NavA = ({ title, subtitle, leading, trailing, large = true, prominent }) => (
  <div style={{ padding: '54px 16px 8px' }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', minHeight: 36 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>{leading}</div>
      {!large && <div style={{ position: 'absolute', left: 0, right: 0, textAlign: 'center', fontSize: 17, fontWeight: 600, color: 'var(--text-1)', pointerEvents: 'none' }}>{title}</div>}
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div>
    </div>
    {large && (
      <div style={{ marginTop: 4 }}>
        <div style={{ fontSize: prominent ? 36 : 32, fontWeight: 700, color: 'var(--text-1)', letterSpacing: -0.8, lineHeight: 1.05 }}>{title}</div>
        {subtitle && <div style={{ marginTop: 4, fontSize: 14, color: 'var(--text-2)' }}>{subtitle}</div>}
      </div>
    )}
  </div>
);

// iOS circular icon button (nav)
const IconBtnA = ({ children, accent, size = 32, onClick }) => (
  <button onClick={onClick} style={{
    width: size, height: size, borderRadius: size/2,
    background: accent ? 'var(--accent)' : 'var(--secondary-bg)',
    color: accent ? 'var(--accent-fg)' : 'var(--accent)',
    border: 'none', cursor: 'pointer', padding: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>{children}</button>
);

// iOS grouped section header
const SectionA = ({ children, action }) => (
  <div style={{
    display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
    padding: '8px 32px 8px', fontSize: 13, color: 'var(--text-2)',
    textTransform: 'uppercase', letterSpacing: 0.4, fontWeight: 500,
  }}>
    <span>{children}</span>
    {action && <span style={{ color: 'var(--accent)', textTransform: 'none', fontSize: 14, fontWeight: 500, letterSpacing: 0 }}>{action}</span>}
  </div>
);

// iOS grouped list container
const ListA = ({ children, style = {} }) => (
  <div style={{
    margin: '0 16px', borderRadius: 14, background: 'var(--surface)',
    overflow: 'hidden', ...style,
  }}>{children}</div>
);

// iOS list row
const RowA = ({ icon, iconBg, label, detail, value, last, chev = true, accent, onClick }) => (
  <div onClick={onClick} style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '12px 16px 12px 16px', cursor: onClick ? 'pointer' : 'default',
    borderBottom: last ? 'none' : '0.5px solid var(--line)',
    marginLeft: icon ? 0 : 0,
  }}>
    {icon && (
      <div style={{
        width: 30, height: 30, borderRadius: 7, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: iconBg || 'var(--accent)', color: '#fff',
      }}>{icon}</div>
    )}
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 16, color: accent === 'danger' ? 'var(--bad)' : 'var(--text-1)', fontWeight: 400 }}>{label}</div>
      {detail && <div style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 1 }}>{detail}</div>}
    </div>
    {value && <span style={{ fontSize: 15, color: 'var(--text-2)' }}>{value}</span>}
    {chev && accent !== 'danger' && <I2.Chev size={14} color="var(--text-3)" stroke={2.3}/>}
  </div>
);

// iOS pill chip
const ChipA = ({ children, tone = 'neutral' }) => {
  const tones = {
    neutral: { bg: 'var(--secondary-bg)', fg: 'var(--text-2)' },
    accent:  { bg: 'var(--accent-tint)', fg: 'var(--accent)' },
    good:    { bg: 'rgba(22,163,74,0.12)', fg: 'var(--good)' },
    warn:    { bg: 'rgba(224,168,0,0.12)', fg: 'var(--warn)' },
  };
  const t = tones[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 8px', borderRadius: 999,
      background: t.bg, color: t.fg, fontSize: 11.5, fontWeight: 600,
    }}>{children}</span>
  );
};

// Bottom tab bar — iOS style, flat (no glass over our content)
const TabBarA = ({ active }) => {
  const tabs = [
    { id: 'projects', label: '项目', icon: <I2.Layers size={24} stroke={1.8}/> },
    { id: 'gallery',  label: '作品', icon: <I2.Grid size={24} stroke={1.8}/> },
    { id: 'control',  label: '我的', icon: <I2.Person size={24} stroke={1.8}/> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 30,
      background: 'var(--surface)',
      borderTop: '0.5px solid var(--line)',
      paddingBottom: 28, paddingTop: 6,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-around' }}>
        {tabs.map(t => {
          const on = t.id === active;
          return (
            <div key={t.id} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              color: on ? 'var(--accent)' : 'var(--text-3)',
              padding: '4px 18px',
            }}>
              {t.icon}
              <div style={{ fontSize: 10.5, fontWeight: on ? 600 : 500 }}>{t.label}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// SCREEN: Splash (A)
// ─────────────────────────────────────────────────────────────
function SplashA({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: 'var(--bg)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, color: 'var(--text-1)' }}>
        <ForgeMark size={56} accent="var(--accent)"/>
      </div>
      <div style={{ marginTop: 22, fontSize: 32, fontWeight: 700, color: 'var(--text-1)', letterSpacing: -0.8 }}>
        GameForger
      </div>
      <div style={{ marginTop: 8, fontSize: 14, color: 'var(--text-2)', letterSpacing: 0.2 }}>
        把你的游戏创意变成现实
      </div>

      <div style={{ position: 'absolute', bottom: 80, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 24, height: 24, borderRadius: 12,
          border: '2px solid var(--text-4)', borderTopColor: 'var(--accent)',
          animation: 'spinA 0.9s linear infinite',
        }}/>
        <style>{`@keyframes spinA { to { transform: rotate(360deg) } }`}</style>
        <div style={{ fontSize: 12, color: 'var(--text-3)' }}>正在加载…</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Projects (A)
// ─────────────────────────────────────────────────────────────
function ProjectsA({ theme }) {
  const projects = [
    { name: '霓虹漂流', meta: '横版滑行 · 今天 14:32', status: '可玩' },
    { name: '星核守卫者', meta: '塔防 · 昨天 21:08', status: '可玩' },
    { name: '深渊回响', meta: '探索 · 3 天前', status: '草稿' },
    { name: '像素厨房物语', meta: '模拟 · 5 天前', status: '可玩' },
    { name: '量子俄罗斯方块', meta: '益智 · 上周', status: '可玩' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavA title="项目" prominent
        trailing={<>
          <IconBtnA><I2.Search size={16} stroke={2.2}/></IconBtnA>
          <IconBtnA accent><I2.Plus size={18} stroke={2.5}/></IconBtnA>
        </>}
      />
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 100 }}>

        {/* Summary card */}
        <div style={{ padding: '6px 16px 18px' }}>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
          }}>
            {[
              { v: '12', l: '总项目', a: false },
              { v: '8',  l: '可玩', a: true },
              { v: '3',  l: '草稿', a: false },
            ].map((s, i) => (
              <div key={i} style={{
                padding: '14px 12px', borderRadius: 14, background: 'var(--surface)',
              }}>
                <div style={{ fontSize: 28, fontWeight: 700, color: s.a ? 'var(--accent)' : 'var(--text-1)', letterSpacing: -0.5, fontVariantNumeric: 'tabular-nums' }}>{s.v}</div>
                <div style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        <SectionA action="按更新时间">最近</SectionA>
        <ListA>
          {projects.map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
              borderBottom: i === projects.length - 1 ? 'none' : '0.5px solid var(--line)',
            }}>
              {/* mini thumb — flat, no glow */}
              <div style={{
                width: 42, height: 42, borderRadius: 10, flexShrink: 0,
                background: p.status === '草稿' ? 'var(--secondary-bg)' : 'var(--accent-tint)',
                border: '0.5px solid var(--line)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: p.status === '草稿' ? 'var(--text-3)' : 'var(--accent)',
              }}>
                <ForgeMark size={22} color="currentColor" accent="currentColor"/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 16, fontWeight: 500, color: 'var(--text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.name}</div>
                <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginTop: 1 }}>{p.meta}</div>
              </div>
              {p.status === '草稿' && <ChipA tone="neutral">草稿</ChipA>}
              <I2.Chev size={14} color="var(--text-3)" stroke={2.3}/>
            </div>
          ))}
        </ListA>

        <SectionA>模板</SectionA>
        <ListA>
          <RowA icon={<I2.Sparkle size={16} stroke={2}/>} iconBg="var(--accent)" label="空白工程" detail="从对话开始" />
          <RowA icon={<I2.Wand size={16} stroke={2}/>} iconBg="#7C7C82" label="从灵感库" detail="50+ 起点" last />
        </ListA>
      </div>
      <TabBarA active="projects"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Gallery (A)
// ─────────────────────────────────────────────────────────────
function GalleryA({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavA title="作品" subtitle="24 件已生成" prominent
        trailing={<IconBtnA><I2.More size={16} stroke={2.2}/></IconBtnA>}
      />

      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 100 }}>

        {/* Featured */}
        <div style={{ padding: '6px 16px 22px' }}>
          <div style={{
            position: 'relative', borderRadius: 22, overflow: 'hidden',
            background: 'var(--surface)', border: '0.5px solid var(--line)',
          }}>
            <div style={{
              height: 190, background: theme === 'dark'
                ? 'linear-gradient(135deg, #0F2F1C 0%, #062711 100%)'
                : 'linear-gradient(135deg, #DCFCE7 0%, #BBF7D0 100%)',
              position: 'relative', overflow: 'hidden',
            }}>
              <svg viewBox="0 0 360 190" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
                {[...Array(12)].map((_, i) => (
                  <circle key={i} cx={30 + i*28} cy={70 + Math.sin(i*0.7)*20} r="2"
                    fill={theme === 'dark' ? '#4ADE80' : '#16A34A'} opacity={0.45 + (i%3)*0.15}/>
                ))}
                <path d="M40 130 Q180 90 320 125" stroke={theme === 'dark' ? '#4ADE80' : '#16A34A'} strokeWidth="1.5" fill="none" opacity="0.7"/>
                <path d="M40 140 Q180 105 320 135" stroke={theme === 'dark' ? '#4ADE80' : '#16A34A'} strokeWidth="1" fill="none" opacity="0.4"/>
              </svg>
            </div>
            <div style={{ padding: 16 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
                <ChipA tone="accent">最新</ChipA>
                <ChipA tone="neutral">Phaser</ChipA>
              </div>
              <div style={{ fontSize: 19, fontWeight: 700, color: 'var(--text-1)', letterSpacing: -0.3 }}>霓虹漂流</div>
              <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 2 }}>5 分钟前生成 · 横版滑行</div>
              <button style={{
                marginTop: 14, width: '100%', height: 44, borderRadius: 12,
                background: 'var(--accent)', color: 'var(--accent-fg)',
                border: 'none', fontSize: 15, fontWeight: 600,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, cursor: 'pointer',
              }}>
                <I2.Play size={14}/>立即试玩
              </button>
            </div>
          </div>
        </div>

        <SectionA action="网格">全部作品</SectionA>
        <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {[
            { name: '星核守卫者', meta: '塔防 · 2小时前', new: true },
            { name: '像素厨房物语', meta: '模拟 · 昨天', new: false },
            { name: '量子方块', meta: '益智 · 3天前', new: false },
            { name: '深渊回响', meta: '草稿', draft: true },
          ].map((w, i) => (
            <div key={i} style={{
              borderRadius: 16, overflow: 'hidden',
              background: 'var(--surface)', border: '0.5px solid var(--line)',
            }}>
              <div style={{
                height: 96, position: 'relative',
                background: w.draft ? 'var(--secondary-bg)' : (theme === 'dark' ? '#142318' : '#ECFDF5'),
              }}>
                {!w.draft && <svg viewBox="0 0 200 96" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
                  {[...Array(8)].map((_, j) => (
                    <circle key={j} cx={20 + j*22} cy={48 + Math.cos(j*0.6+i)*16} r="2"
                      fill={theme === 'dark' ? '#4ADE80' : '#16A34A'} opacity="0.45"/>
                  ))}
                </svg>}
                {w.draft && <div style={{
                  position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'var(--text-3)', fontSize: 11.5, letterSpacing: 0.4,
                }}>草稿</div>}
              </div>
              <div style={{ padding: 10 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{w.name}</div>
                  {w.new && <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--accent)' }}/>}
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-2)', marginTop: 2 }}>{w.meta}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <TabBarA active="gallery"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Settings / Profile (A)
// ─────────────────────────────────────────────────────────────
function SettingsA({ theme }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      <NavA title="我的" prominent
        trailing={<IconBtnA><I2.More size={16} stroke={2.2}/></IconBtnA>}
      />
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', paddingBottom: 100 }}>

        {/* Identity card */}
        <div style={{ padding: '6px 16px 14px' }}>
          <div style={{
            background: 'var(--surface)', borderRadius: 16, padding: 14,
            display: 'flex', alignItems: 'center', gap: 14,
          }}>
            <div style={{
              width: 56, height: 56, borderRadius: 28,
              background: 'var(--accent)', color: 'var(--accent-fg)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22, fontWeight: 700, letterSpacing: -0.5, flexShrink: 0,
            }}>A</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 18, fontWeight: 600, color: 'var(--text-1)' }}>alex</div>
              <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 1 }}>alex@gameforger.app</div>
            </div>
            <I2.Chev size={14} color="var(--text-3)" stroke={2.3}/>
          </div>
        </div>

        {/* Credit + Stats row */}
        <div style={{ padding: '0 16px 16px', display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 10 }}>
          <div style={{
            padding: 14, borderRadius: 14, background: 'var(--surface)',
          }}>
            <div style={{ fontSize: 12, color: 'var(--text-2)', letterSpacing: 0.2 }}>剩余点数</div>
            <div style={{ marginTop: 4, display: 'flex', alignItems: 'baseline', gap: 4 }}>
              <span style={{ fontSize: 26, fontWeight: 700, color: 'var(--text-1)', letterSpacing: -0.4, fontVariantNumeric: 'tabular-nums' }}>1,240</span>
              <span style={{ fontSize: 12, color: 'var(--text-3)' }}>pts</span>
            </div>
            <div style={{
              marginTop: 10, padding: '6px 10px', borderRadius: 8,
              background: 'var(--accent-tint)', color: 'var(--accent)',
              fontSize: 12, fontWeight: 600, textAlign: 'center', cursor: 'pointer',
            }}>充值</div>
          </div>
          <div style={{
            padding: 14, borderRadius: 14, background: 'var(--surface)',
          }}>
            <div style={{ fontSize: 12, color: 'var(--text-2)', letterSpacing: 0.2 }}>已生成</div>
            <div style={{ marginTop: 4, display: 'flex', alignItems: 'baseline', gap: 4 }}>
              <span style={{ fontSize: 26, fontWeight: 700, color: 'var(--text-1)', letterSpacing: -0.4, fontVariantNumeric: 'tabular-nums' }}>8</span>
              <span style={{ fontSize: 12, color: 'var(--text-3)' }}>件</span>
            </div>
            <div style={{ marginTop: 10, fontSize: 11.5, color: 'var(--text-3)' }}>本月 +3</div>
          </div>
        </div>

        <SectionA>常用</SectionA>
        <ListA>
          <RowA icon={<I2.Key size={16}/>} iconBg="#6B7280" label="API 配置" value="4 个模型" />
          <RowA icon={<I2.Bell size={16}/>} iconBg="#F59E0B" label="通知" value="开" />
          <RowA icon={<I2.Palette size={16}/>} iconBg="var(--accent)" label="外观" value={theme === 'dark' ? '深色' : '浅色'} last />
        </ListA>

        <SectionA>系统</SectionA>
        <ListA>
          <RowA icon={<I2.Info size={16}/>} iconBg="#6B7280" label="关于" value="v 1.4.0" />
          <RowA icon={<I2.Logout size={16}/>} iconBg="var(--bad)" label="退出登录" accent="danger" chev={false} last />
        </ListA>

        <div style={{ textAlign: 'center', fontSize: 11.5, color: 'var(--text-3)', marginTop: 22 }}>
          GameForger · 1.4.0 (2026.05)
        </div>
      </div>
      <TabBarA active="control"/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Workspace (A) — chat-driven creation
// ─────────────────────────────────────────────────────────────
function WorkspaceA({ theme }) {
  const dims = [
    { k: '玩法', v: 0.85, locked: true },
    { k: '美术', v: 0.55, locked: true },
    { k: '机制', v: 0.45, locked: false },
    { k: '难度', v: 0.50, locked: false },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      {/* compact nav */}
      <div style={{ paddingTop: 54, padding: '54px 8px 8px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <IconBtnA><I2.ChevL size={16} stroke={2.4}/></IconBtnA>
        <div style={{ flex: 1, textAlign: 'center', minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 600, color: 'var(--text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            霓虹漂流
          </div>
          <div style={{ fontSize: 11, color: 'var(--text-2)', marginTop: 1 }}>5 / 9 维度已锁定</div>
        </div>
        <IconBtnA accent size={32}><I2.Sparkle size={15} stroke={2.2}/></IconBtnA>
      </div>

      {/* Dimensions progress strip */}
      <div style={{ padding: '6px 16px 10px' }}>
        <div style={{
          background: 'var(--surface)', borderRadius: 14, padding: 12,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--text-1)' }}>创意维度</div>
            <span style={{ fontSize: 12, color: 'var(--accent)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>58%</span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 16px' }}>
            {dims.map(d => (
              <div key={d.k} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ width: 6, height: 6, borderRadius: 3, background: d.locked ? 'var(--accent)' : 'var(--text-4)' }}/>
                <span style={{ fontSize: 12, color: 'var(--text-1)', flex: 1 }}>{d.k}</span>
                <span style={{ fontSize: 11, color: 'var(--text-3)', fontVariantNumeric: 'tabular-nums' }}>{Math.round(d.v*100)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Chat */}
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', padding: '4px 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>

        {/* assistant message */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
          <div style={{
            width: 26, height: 26, borderRadius: 13, flexShrink: 0,
            background: 'var(--accent-tint)', color: 'var(--accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <ForgeMark size={16} color="currentColor" accent="currentColor"/>
          </div>
          <div style={{
            maxWidth: '80%', padding: '10px 14px', borderRadius: 18, borderTopLeftRadius: 6,
            background: 'var(--surface)', fontSize: 14.5, color: 'var(--text-1)', lineHeight: 1.5,
          }}>
            已锁定 <strong style={{color: 'var(--accent)'}}>玩法</strong> 和 <strong style={{color: 'var(--accent)'}}>美术</strong>。下一步确认 <strong>核心机制</strong>—— 追逐分数，还是探索关卡？
          </div>
        </div>

        {/* user reply */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            maxWidth: '78%', padding: '10px 14px', borderRadius: 18, borderTopRightRadius: 6,
            background: 'var(--accent)', color: 'var(--accent-fg)', fontSize: 14.5, lineHeight: 1.5,
          }}>
            先做无尽追分，撞墙就 GG
          </div>
        </div>

        {/* assistant follow-up + chips */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
          <div style={{
            width: 26, height: 26, borderRadius: 13, flexShrink: 0,
            background: 'var(--accent-tint)', color: 'var(--accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <ForgeMark size={16} color="currentColor" accent="currentColor"/>
          </div>
          <div style={{ maxWidth: '82%' }}>
            <div style={{
              padding: '10px 14px', borderRadius: 18, borderTopLeftRadius: 6,
              background: 'var(--surface)', fontSize: 14.5, color: 'var(--text-1)', lineHeight: 1.5,
            }}>
              难度曲线想偏哪边？
            </div>
            <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
              {['节奏紧凑', '速度递增', '一击毙'].map(s => (
                <button key={s} style={{
                  padding: '7px 12px', borderRadius: 999, fontSize: 12.5,
                  background: 'var(--secondary-bg)', border: 'none', color: 'var(--text-1)', fontWeight: 500,
                  cursor: 'pointer',
                }}>{s}</button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Input bar */}
      <div style={{ padding: '8px 14px 96px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '6px 6px 6px 14px', borderRadius: 22,
          background: 'var(--surface)',
          border: '0.5px solid var(--line)',
        }}>
          <div style={{ flex: 1, fontSize: 14.5, color: 'var(--text-3)' }}>
            告诉它下一步…
          </div>
          <button style={{
            width: 36, height: 36, borderRadius: 18, border: 'none', cursor: 'pointer',
            background: 'var(--accent)', color: 'var(--accent-fg)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><I2.Send size={15} stroke={2.4}/></button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SCREEN: Preview (A)
// ─────────────────────────────────────────────────────────────
function PreviewA({ theme }) {
  const [tab, setTab] = React.useState('code');
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
      {/* nav */}
      <div style={{ paddingTop: 54, padding: '54px 12px 10px', display: 'flex', alignItems: 'center', gap: 6 }}>
        <IconBtnA><I2.ChevL size={16} stroke={2.4}/></IconBtnA>
        <div style={{ flex: 1, minWidth: 0, paddingLeft: 4 }}>
          <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>霓虹漂流</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 1 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--good)' }}/>
            <span style={{ fontSize: 11, color: 'var(--text-2)', fontFamily: 'var(--font-mono)' }}>RUNNING · Phaser 3</span>
          </div>
        </div>
        <IconBtnA><I2.Volume size={14} stroke={2.2}/></IconBtnA>
        <IconBtnA><I2.Expand size={14} stroke={2.2}/></IconBtnA>
        <IconBtnA><I2.More size={16} stroke={2.2}/></IconBtnA>
      </div>

      {/* canvas */}
      <div style={{ padding: '0 16px' }}>
        <div style={{
          height: 220, borderRadius: 18, overflow: 'hidden', position: 'relative',
          background: '#0B0F08', border: '0.5px solid var(--line)',
        }}>
          {/* synthwave game shot */}
          <svg viewBox="0 0 360 220" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
            <defs>
              <linearGradient id="floorA" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#16A34A" stopOpacity="0"/>
                <stop offset="100%" stopColor="#16A34A" stopOpacity="0.55"/>
              </linearGradient>
              <radialGradient id="sunA" cx="0.5" cy="0.5" r="0.5">
                <stop offset="0%" stopColor="#FFB060"/>
                <stop offset="100%" stopColor="#FF6A3D" stopOpacity="0"/>
              </radialGradient>
            </defs>
            <circle cx="180" cy="95" r="55" fill="url(#sunA)"/>
            <line x1="0" y1="125" x2="360" y2="125" stroke="#4ADE80" strokeWidth="0.7"/>
            <g stroke="url(#floorA)" strokeWidth="0.6" fill="none">
              {[0,1,2,3,4,5,6,7,8].map(i => <line key={i} x1={-200+i*100} y1="220" x2="180" y2="125"/>)}
              {[0,1,2,3,4,5,6,7,8].map(i => <line key={i} x1={180+i*100-200} y1="125" x2={560-i*100} y2="220"/>)}
              {[0,1,2,3].map(i => <line key={i} x1="0" y1={140+i*22} x2="360" y2={140+i*22}/>)}
            </g>
            <g transform="translate(170 175)">
              <rect x="0" y="0" width="20" height="14" rx="3" fill="#4ADE80"/>
              <rect x="4" y="-4" width="12" height="6" rx="2" fill="#fff"/>
            </g>
            <text x="14" y="22" fontSize="10" fill="#4ADE80" fontFamily="ui-monospace, monospace">SCORE 02480</text>
            <text x="290" y="22" fontSize="10" fill="#FFD99E" fontFamily="ui-monospace, monospace">×3</text>
          </svg>
          <div style={{
            position: 'absolute', top: 10, right: 10, padding: '3px 8px', borderRadius: 6,
            background: 'rgba(0,0,0,0.45)', fontSize: 9.5, color: 'rgba(255,255,255,0.8)',
            fontFamily: 'var(--font-mono)', letterSpacing: 0.5,
          }}>402×240 · 60 FPS</div>
        </div>
      </div>

      {/* iOS segmented control */}
      <div style={{ padding: '14px 16px 10px' }}>
        <div style={{
          display: 'flex', padding: 3, borderRadius: 9,
          background: 'var(--secondary-bg)',
        }}>
          {[
            { id: 'code', label: '代码' },
            { id: 'chat', label: '对话' },
            { id: 'asset', label: '素材' },
            { id: 'info', label: '信息' },
          ].map(t => {
            const on = t.id === tab;
            return (
              <div key={t.id} onClick={() => setTab(t.id)} style={{
                flex: 1, height: 28, borderRadius: 7,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 13, fontWeight: on ? 600 : 500,
                background: on ? 'var(--surface)' : 'transparent',
                color: on ? 'var(--text-1)' : 'var(--text-2)',
                boxShadow: on ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                cursor: 'pointer',
              }}>{t.label}</div>
            );
          })}
        </div>
      </div>

      {/* Code panel */}
      <div style={{ flex: 1, padding: '4px 16px 16px', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{
            padding: '4px 9px', borderRadius: 8,
            background: 'var(--secondary-bg)',
            fontFamily: 'var(--font-mono)', fontSize: 11.5, color: 'var(--text-2)',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{ width: 7, height: 7, borderRadius: 2, background: 'var(--accent)'}}/>
            index.html
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <IconBtnA size={28}><I2.Copy size={13}/></IconBtnA>
            <button style={{
              height: 28, padding: '0 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
              background: 'var(--accent)', color: 'var(--accent-fg)', fontSize: 12.5, fontWeight: 600,
              display: 'flex', alignItems: 'center', gap: 4,
            }}><I2.Check size={12} stroke={2.4}/>应用</button>
          </div>
        </div>
        <div style={{
          flex: 1, borderRadius: 12, overflow: 'hidden',
          background: theme === 'dark' ? '#0B0E0C' : '#FAFAF8',
          border: '0.5px solid var(--line)',
          fontFamily: 'var(--font-mono)', fontSize: 11, lineHeight: 1.55,
          padding: '10px 0',
        }}>
          <CodeViewA theme={theme}/>
        </div>
      </div>
    </div>
  );
}

function CodeViewA({ theme }) {
  const dark = theme === 'dark';
  const c = dark ? {
    kw: '#4ADE80', tag: '#A8A095', str: '#E4B454', com: '#5F584C',
    fn: '#7CD0FF', txt: '#E5E5EA', num: '#FF9F7E', op: '#A8A095',
  } : {
    kw: '#16A34A', tag: '#5F584C', str: '#A8761F', com: '#A8A095',
    fn: '#1F6FB8', txt: '#16140E', num: '#B5301E', op: '#5F584C',
  };
  const lines = [
    [{c:c.com, t:'// Neon Drift — main loop'}],
    [{c:c.kw, t:'const'},{c:c.txt, t:' '},{c:c.fn,t:'game'},{c:c.op,t:' = '},{c:c.kw,t:'new'},{c:c.txt,t:' '},{c:c.fn,t:'Phaser.Game'},{c:c.op,t:'({'}],
    [{c:c.txt,t:'  type'},{c:c.op,t:': '},{c:c.fn,t:'Phaser'},{c:c.op,t:'.'},{c:c.tag,t:'WEBGL'},{c:c.op,t:','}],
    [{c:c.txt,t:'  width'},{c:c.op,t:': '},{c:c.num,t:'402'},{c:c.op,t:', '},{c:c.txt,t:'height'},{c:c.op,t:': '},{c:c.num,t:'720'},{c:c.op,t:','}],
    [{c:c.txt,t:'  scene'},{c:c.op,t:': ['},{c:c.fn,t:'PreloadScene'},{c:c.op,t:', '},{c:c.fn,t:'PlayScene'},{c:c.op,t:']'}],
    [{c:c.op,t:'});'}],
    [],
    [{c:c.kw, t:'class'},{c:c.txt, t:' '},{c:c.fn,t:'PlayScene'},{c:c.txt,t:' '},{c:c.kw,t:'extends'},{c:c.txt,t:' '},{c:c.fn,t:'Phaser.Scene'},{c:c.op,t:' {'}],
    [{c:c.fn,t:'  create'},{c:c.op,t:'() {'}],
    [{c:c.kw,t:'    this'},{c:c.op,t:'.player = '},{c:c.kw,t:'this'},{c:c.op,t:'.physics.add.'},{c:c.fn,t:'sprite'},{c:c.op,t:'('},{c:c.num,t:'201'},{c:c.op,t:', '},{c:c.num,t:'620'},{c:c.op,t:', '},{c:c.str,t:'"car"'},{c:c.op,t:');'}],
    [{c:c.op,t:'  }'}],
    [{c:c.op,t:'}'}],
  ];
  return (
    <div style={{ display: 'flex', overflow: 'auto', height: '100%' }}>
      <div style={{
        flexShrink: 0, padding: '0 8px 0 12px', textAlign: 'right',
        color: c.com, userSelect: 'none',
      }}>
        {lines.map((_, i) => <div key={i}>{i+1}</div>)}
      </div>
      <div style={{ flex: 1, padding: '0 12px', whiteSpace: 'pre', overflowX: 'auto' }}>
        {lines.map((line, i) => (
          <div key={i}>
            {line.length ? line.map((s, j) => <span key={j} style={{ color: s.c }}>{s.t}</span>) : '\u00A0'}
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { SplashA, ProjectsA, GalleryA, SettingsA, WorkspaceA, PreviewA });
