/* @jsx React.createElement */
// Three main tab screens — Projects, Gallery, Settings

// ─────────────────────────────────────────────────────────────
// PROJECTS — control-console feel
// ─────────────────────────────────────────────────────────────
function ProjectsScreen() {
  const projects = [
    { name: '霓虹漂流 · Neon Drift', updated: '今天 14:32', tone: 'violet', hue: 0 },
    { name: '星核守卫者', updated: '昨天 21:08', tone: 'cyan', hue: 30 },
    { name: '深渊回响 (草稿)', updated: '3 天前', tone: 'draft', hue: 80 },
    { name: '像素厨房物语', updated: '5 天前', tone: 'neutral', hue: 120 },
    { name: '量子俄罗斯方块', updated: '上周', tone: 'neutral', hue: 200 },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <ForgeNav
        large title="项目"
        trailing={<>
          <IconBtn><I.Search size={18} /></IconBtn>
          <IconBtn><I.More size={18} /></IconBtn>
        </>}
      />
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>

        {/* Status hero */}
        <GlassCard padding={16} radius={22} style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <NebulaOrb size={42} spin={false} />
              <div>
                <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--forge-text-1)' }}>锻造台已就绪</div>
                <div style={{ marginTop: 3, display: 'flex', gap: 6, alignItems: 'center' }}>
                  <Chip tone="online" dot>在线</Chip>
                  <Chip tone="violet">{`已登录 · alex`}</Chip>
                </div>
              </div>
            </div>
            <IconBtn glow><I.Refresh size={16} /></IconBtn>
          </div>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10,
            marginTop: 14, paddingTop: 14, borderTop: '0.5px solid rgba(255,255,255,0.08)',
          }}>
            {[
              { v: '12', l: '总项目' },
              { v: '3', l: '草稿' },
              { v: '8', l: '已生成' },
            ].map(s => (
              <div key={s.l} style={{ textAlign: 'left' }}>
                <div style={{ fontSize: 22, fontWeight: 700, color: 'var(--forge-text-1)', letterSpacing: -0.3 }}>{s.v}</div>
                <div style={{ fontSize: 11, color: 'var(--forge-text-3)', marginTop: 1 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </GlassCard>

        {/* Primary action */}
        <button style={{
          width: '100%', height: 54, borderRadius: 18, marginBottom: 22,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontFamily: 'var(--font-sf)', fontSize: 16, fontWeight: 600, color: '#fff',
          cursor: 'pointer',
          background: 'linear-gradient(180deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #8b6bff, #5a3fe6)',
          border: '0.5px solid rgba(255,255,255,0.18)',
          boxShadow: '0 8px 24px rgba(123,92,255,0.45), inset 0 1px 0 rgba(255,255,255,0.28)',
        }}>
          <I.Plus size={18} stroke={2.2} /> 新建项目
        </button>

        {/* Section header */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 4px 10px',
        }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--forge-text-2)', letterSpacing: 0.5 }}>
            最近项目
          </div>
          <div style={{ fontSize: 12, color: 'var(--forge-text-3)' }}>按更新时间</div>
        </div>

        {/* Project list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {projects.map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: 10,
              background: 'rgba(255,255,255,0.04)',
              border: '0.5px solid rgba(255,255,255,0.07)',
              borderRadius: 18,
              backdropFilter: 'blur(14px)',
            }}>
              <NebulaSeed hue={p.hue} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14.5, fontWeight: 600, color: 'var(--forge-text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {p.name}
                </div>
                <div style={{ fontSize: 11.5, color: 'var(--forge-text-3)', marginTop: 2 }}>更新于 {p.updated}</div>
              </div>
              {p.tone === 'draft' && <Chip tone="draft">草稿</Chip>}
              <I.Chevron size={14} color="rgba(244,241,255,0.4)" stroke={1.8} />
            </div>
          ))}
        </div>
      </div>
      <ForgeTabBar active="projects" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// GALLERY — showcase / showroom feel
// ─────────────────────────────────────────────────────────────
function GalleryScreen() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <ForgeNav
        large title="作品"
        subtitle="可玩宇宙样本 · 24 件已生成"
        trailing={<>
          <IconBtn><I.Search size={18} /></IconBtn>
          <IconBtn><I.More size={18} /></IconBtn>
        </>}
      />
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>

        {/* Featured / latest work */}
        <div style={{ marginBottom: 18 }}>
          <div style={{ fontSize: 11, color: 'var(--forge-text-3)', letterSpacing: 1.2, textTransform: 'uppercase', padding: '0 4px 8px' }}>
            最新生成
          </div>
          <div style={{
            position: 'relative', height: 200, borderRadius: 24, overflow: 'hidden',
            border: '0.5px solid rgba(154,125,255,0.32)',
            background: 'radial-gradient(80% 80% at 30% 20%, rgba(123,92,255,0.45) 0%, rgba(11,10,34,0.3) 50%), linear-gradient(135deg, #1a0e3d 0%, #04030a 100%)',
            boxShadow: '0 12px 36px rgba(123,92,255,0.28), inset 0 1px 0 rgba(255,255,255,0.1)',
          }}>
            {/* abstract game preview */}
            <svg viewBox="0 0 360 200" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
              <defs>
                <radialGradient id="gx1" cx="0.5" cy="0.5" r="0.6">
                  <stop offset="0%" stopColor="#9beaff" stopOpacity="0.9"/>
                  <stop offset="100%" stopColor="#7b5cff" stopOpacity="0"/>
                </radialGradient>
              </defs>
              {[...Array(20)].map((_, i) => (
                <circle key={i} cx={20 + i * 18} cy={100 + Math.sin(i*0.7)*40} r={1 + (i%3)} fill="#fff" opacity={0.5}/>
              ))}
              <circle cx="120" cy="110" r="40" fill="url(#gx1)"/>
              <circle cx="120" cy="110" r="6" fill="#fff"/>
              <path d="M40 170 Q180 130 320 165" stroke="#4fc9e8" strokeWidth="1.5" fill="none" opacity="0.7"/>
              <path d="M40 180 Q180 145 320 175" stroke="#7b5cff" strokeWidth="1" fill="none" opacity="0.5"/>
            </svg>
            <div style={{
              position: 'absolute', left: 0, right: 0, bottom: 0,
              padding: 16, background: 'linear-gradient(180deg, transparent, rgba(0,0,0,0.6))',
            }}>
              <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
                    <Chip tone="cyan" dot>可玩</Chip>
                    <Chip tone="violet">Phaser</Chip>
                  </div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: '#fff', letterSpacing: -0.3 }}>霓虹漂流 · Neon Drift</div>
                  <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.65)', marginTop: 2 }}>5 分钟前生成 · 横版滑行</div>
                </div>
                <button style={{
                  flexShrink: 0, height: 38, padding: '0 16px', borderRadius: 12,
                  background: 'linear-gradient(180deg, rgba(255,255,255,0.16), rgba(255,255,255,0)) , linear-gradient(180deg, #5fd6f0, #2891b0)',
                  border: '0.5px solid rgba(255,255,255,0.2)',
                  color: '#04222a', fontWeight: 600, fontSize: 13,
                  boxShadow: '0 6px 18px rgba(79,201,232,0.4)',
                  display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
                }}><I.Bolt size={14} stroke={2.2} />运行</button>
              </div>
            </div>
          </div>
        </div>

        {/* Recent list */}
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--forge-text-2)', letterSpacing: 0.5, padding: '0 4px 10px' }}>
          全部作品
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            { name: '星核守卫者', meta: '塔防 · 2 小时前', hue: 30, on: false },
            { name: '像素厨房物语', meta: '模拟 · 昨天', hue: 120, on: true },
            { name: '量子俄罗斯方块', meta: '益智 · 3 天前', hue: 200, on: false },
          ].map((w, i) => (
            <div key={i} style={{
              padding: 12, borderRadius: 18,
              background: w.on ? 'rgba(154,125,255,0.08)' : 'rgba(255,255,255,0.04)',
              border: `0.5px solid ${w.on ? 'rgba(154,125,255,0.3)' : 'rgba(255,255,255,0.07)'}`,
              backdropFilter: 'blur(14px)',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                {/* mini preview */}
                <div style={{
                  width: 56, height: 56, borderRadius: 14, flexShrink: 0,
                  background: `radial-gradient(circle at 35% 30%, hsl(${260+w.hue} 80% 60%) 0%, hsl(${220+w.hue} 70% 18%) 70%)`,
                  border: '0.5px solid rgba(255,255,255,0.12)',
                  position: 'relative', overflow: 'hidden',
                }}>
                  <svg viewBox="0 0 56 56" style={{ position: 'absolute', inset: 0 }}>
                    <ellipse cx="28" cy="28" rx="22" ry="7" stroke="rgba(255,255,255,0.4)" strokeWidth="0.6" fill="none" transform={`rotate(${-20+w.hue} 28 28)`}/>
                    <circle cx="28" cy="28" r="3.5" fill="rgba(255,255,255,0.95)"/>
                  </svg>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14.5, fontWeight: 600, color: 'var(--forge-text-1)' }}>{w.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--forge-text-3)', marginTop: 2 }}>{w.meta}</div>
                </div>
                {w.on
                  ? <I.ChevronD size={16} color="var(--forge-text-2)" stroke={2}/>
                  : <I.Chevron size={14} color="rgba(244,241,255,0.4)" stroke={2}/>}
              </div>
              {w.on && (
                <div style={{ marginTop: 12, paddingTop: 12, borderTop: '0.5px dashed rgba(255,255,255,0.1)' }}>
                  <div style={{
                    height: 90, borderRadius: 14, marginBottom: 10,
                    background: 'linear-gradient(135deg, #1f3a1a 0%, #0a1408 100%)',
                    border: '0.5px solid rgba(91,231,167,0.2)',
                    position: 'relative', overflow: 'hidden',
                  }}>
                    <svg viewBox="0 0 320 90" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
                      {/* kitchen-y blocks */}
                      <rect x="20" y="50" width="40" height="30" rx="3" fill="#f2c36b" opacity="0.85"/>
                      <rect x="70" y="40" width="30" height="40" rx="3" fill="#ff5a6b" opacity="0.8"/>
                      <rect x="110" y="55" width="35" height="25" rx="3" fill="#5be7a7" opacity="0.8"/>
                      <circle cx="180" cy="45" r="14" fill="#ffd99e"/>
                      <rect x="0" y="78" width="320" height="12" fill="rgba(0,0,0,0.4)"/>
                    </svg>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button style={{
                      flex: 1, height: 36, borderRadius: 12,
                      background: 'rgba(255,255,255,0.06)',
                      border: '0.5px solid rgba(255,255,255,0.12)',
                      color: 'var(--forge-text-1)', fontSize: 13, fontWeight: 500,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                    }}><I.Code size={14}/>查看代码</button>
                    <button style={{
                      flex: 1.4, height: 36, borderRadius: 12,
                      background: 'linear-gradient(180deg, rgba(155,128,255,0.45), rgba(123,92,255,0.25))',
                      border: '0.5px solid rgba(154,125,255,0.5)',
                      color: '#fff', fontSize: 13, fontWeight: 600,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                      boxShadow: '0 4px 14px rgba(123,92,255,0.35)',
                    }}><I.Expand size={14}/>完整预览</button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
      <ForgeTabBar active="gallery" />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SETTINGS — quiet control core
// ─────────────────────────────────────────────────────────────
function SettingsScreen() {
  const SettingRow = ({ icon, label, detail, tone = 'default', badge, last = false }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
      borderBottom: last ? 'none' : '0.5px solid rgba(255,255,255,0.06)',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 9,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: tone === 'danger'
          ? 'linear-gradient(180deg, rgba(255,90,107,0.22), rgba(255,90,107,0.08))'
          : tone === 'gold'
          ? 'linear-gradient(180deg, rgba(242,195,107,0.22), rgba(242,195,107,0.08))'
          : 'linear-gradient(180deg, rgba(154,125,255,0.28), rgba(123,92,255,0.1))',
        color: tone === 'danger' ? '#ff8a96' : tone === 'gold' ? '#ffd99e' : '#cbb8ff',
        border: `0.5px solid ${tone === 'danger' ? 'rgba(255,90,107,0.3)' : tone === 'gold' ? 'rgba(242,195,107,0.3)' : 'rgba(154,125,255,0.3)'}`,
        flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, fontSize: 15, color: tone === 'danger' ? '#ff8a96' : 'var(--forge-text-1)', fontWeight: 500 }}>
        {label}
      </div>
      {badge}
      {detail && <span style={{ color: 'var(--forge-text-3)', fontSize: 13 }}>{detail}</span>}
      {tone !== 'danger' && <I.Chevron size={13} color="rgba(244,241,255,0.32)" stroke={2}/>}
    </div>
  );
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <ForgeNav large title="控制" trailing={<IconBtn><I.More size={18}/></IconBtn>} />
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>

        {/* User identity card */}
        <GlassCard padding={18} radius={24} style={{ marginBottom: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 60, height: 60, borderRadius: 18, flexShrink: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'radial-gradient(circle at 30% 30%, #9beaff 0%, #7b5cff 50%, #2a1a6a 100%)',
              border: '0.5px solid rgba(255,255,255,0.2)',
              boxShadow: '0 6px 18px rgba(123,92,255,0.4), inset 0 1px 0 rgba(255,255,255,0.2)',
              fontSize: 24, fontWeight: 700, color: '#fff', letterSpacing: -0.5,
            }}>A</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                <div style={{ fontSize: 17, fontWeight: 600, color: 'var(--forge-text-1)' }}>alex</div>
                <Chip tone="online" dot>已登录</Chip>
              </div>
              <div style={{ fontSize: 12.5, color: 'var(--forge-text-3)' }}>alex@gameforger.app</div>
            </div>
            <IconBtn><I.Edit size={15}/></IconBtn>
          </div>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
            marginTop: 14, paddingTop: 14, borderTop: '0.5px solid rgba(255,255,255,0.08)',
          }}>
            <div>
              <div style={{ fontSize: 11, color: 'var(--forge-text-3)', letterSpacing: 0.5 }}>剩余点数</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--forge-gold-500)', letterSpacing: -0.2, marginTop: 2 }}>
                1,240 <span style={{ fontSize: 11, fontWeight: 500, color: 'var(--forge-text-3)' }}>pts</span>
              </div>
            </div>
            <div>
              <div style={{ fontSize: 11, color: 'var(--forge-text-3)', letterSpacing: 0.5 }}>已生成</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--forge-text-1)', letterSpacing: -0.2, marginTop: 2 }}>
                8 <span style={{ fontSize: 11, fontWeight: 500, color: 'var(--forge-text-3)' }}>件作品</span>
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Common section */}
        <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--forge-text-3)', letterSpacing: 1.2, padding: '0 4px 8px', textTransform: 'uppercase' }}>
          常用
        </div>
        <div style={{
          background: 'rgba(255,255,255,0.035)',
          border: '0.5px solid rgba(255,255,255,0.07)',
          borderRadius: 18, marginBottom: 20, overflow: 'hidden',
          backdropFilter: 'blur(14px)',
        }}>
          <SettingRow icon={<I.Key size={16}/>} label="API 配置" detail="4 模型" />
          <SettingRow icon={<I.Coin size={16}/>} label="点数中心" tone="gold" badge={<Chip tone="gold" style={{marginRight:6}}>1,240</Chip>} detail="" last />
        </div>

        {/* System section */}
        <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--forge-text-3)', letterSpacing: 1.2, padding: '0 4px 8px', textTransform: 'uppercase' }}>
          系统
        </div>
        <div style={{
          background: 'rgba(255,255,255,0.035)',
          border: '0.5px solid rgba(255,255,255,0.07)',
          borderRadius: 18, overflow: 'hidden', marginBottom: 12,
          backdropFilter: 'blur(14px)',
        }}>
          <SettingRow icon={<I.Info size={16}/>} label="关于" detail="v 1.4.0" />
          <SettingRow icon={<I.Logout size={16}/>} label="退出登录" tone="danger" last />
        </div>

        <div style={{ textAlign: 'center', fontSize: 11, color: 'var(--forge-text-4)', marginTop: 24, letterSpacing: 0.5 }}>
          GameForger · Forge OS 1.4 · build 2026.05
        </div>
      </div>
      <ForgeTabBar active="control" />
    </div>
  );
}

Object.assign(window, { ProjectsScreen, GalleryScreen, SettingsScreen });
