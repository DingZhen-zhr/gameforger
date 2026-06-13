/* @jsx React.createElement */
// Flow screens — Splash, Workspace, Preview

// ─────────────────────────────────────────────────────────────
// SPLASH
// ─────────────────────────────────────────────────────────────
function SplashScreen() {
  return (
    <div style={{ height: '100%', position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      {/* extra deep glow at top */}
      <div style={{
        position: 'absolute', top: '14%', left: '50%', transform: 'translateX(-50%)',
        width: 320, height: 320, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(79,201,232,0.18) 0%, transparent 60%)',
        filter: 'blur(20px)',
      }} />

      <div style={{ marginTop: -40, position: 'relative', zIndex: 2 }}>
        <NebulaOrb size={180} />
      </div>

      <div style={{ marginTop: 38, textAlign: 'center', position: 'relative', zIndex: 2 }}>
        <div style={{
          fontSize: 38, fontWeight: 700, color: 'var(--forge-text-1)',
          letterSpacing: -0.6, fontFamily: 'var(--font-sf)',
        }}>
          Game<span style={{
            background: 'linear-gradient(90deg, #9beaff 0%, #9a7dff 100%)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          }}>Forger</span>
        </div>
        <div style={{
          marginTop: 8, fontSize: 13.5, color: 'var(--forge-text-3)',
          letterSpacing: 1.5,
        }}>把你的游戏创意 · 变成现实</div>
      </div>

      {/* fine star ring loader */}
      <div style={{ position: 'absolute', bottom: 120, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
        <svg width="80" height="80" viewBox="0 0 80 80" style={{ animation: 'forgeRing 2.4s linear infinite' }}>
          <style>{`@keyframes forgeRing { to { transform: rotate(360deg) } }`}</style>
          <defs>
            <linearGradient id="splashRing" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#7b5cff" stopOpacity="0"/>
              <stop offset="50%" stopColor="#9beaff"/>
              <stop offset="100%" stopColor="#7b5cff"/>
            </linearGradient>
          </defs>
          <circle cx="40" cy="40" r="34" stroke="rgba(255,255,255,0.06)" strokeWidth="1" fill="none"/>
          <circle cx="40" cy="40" r="34" stroke="url(#splashRing)" strokeWidth="1.5" fill="none" strokeLinecap="round" strokeDasharray="40 180" transform="rotate(-90 40 40)"/>
          {/* tiny star nodes */}
          <circle cx="40" cy="6" r="1.4" fill="#fff"/>
          <circle cx="74" cy="40" r="1" fill="#9beaff"/>
        </svg>
        <div style={{
          fontSize: 11, color: 'var(--forge-text-3)', letterSpacing: 2,
          textTransform: 'uppercase',
        }}>正在校准锻造台</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// WORKSPACE — chain-of-thought creation deck
// ─────────────────────────────────────────────────────────────
function WorkspaceScreen() {
  const dims = [
    { k: '玩法', v: 0.85, on: 'violet' },
    { k: '故事', v: 0.7, on: 'violet' },
    { k: '美术', v: 0.55, on: 'cyan' },
    { k: '视角', v: 0.9, on: 'violet' },
    { k: '机制', v: 0.45, on: 'cyan' },
    { k: '能力', v: 0.3, on: 'cyan' },
    { k: '目标', v: 0.65, on: 'violet' },
    { k: '音乐', v: 0.1, on: 'cyan' },
    { k: '难度', v: 0.5, on: 'cyan' },
  ];
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Top nav */}
      <div style={{ paddingTop: 56, paddingLeft: 14, paddingRight: 14, paddingBottom: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <IconBtn><I.ChevronL size={16} /></IconBtn>
          <div style={{ flex: 1, textAlign: 'center', minWidth: 0 }}>
            <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--forge-text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              霓虹漂流 · 工作台
            </div>
            <div style={{ fontSize: 10.5, color: 'var(--forge-text-3)', marginTop: 1, letterSpacing: 0.4 }}>9 维度 · 已锁定 5</div>
          </div>
          <button style={{
            height: 36, padding: '0 14px', borderRadius: 12,
            background: 'linear-gradient(180deg, rgba(255,255,255,0.18), rgba(255,255,255,0)), linear-gradient(180deg, #8b6bff, #5a3fe6)',
            border: '0.5px solid rgba(255,255,255,0.2)',
            color: '#fff', fontSize: 13, fontWeight: 600,
            display: 'flex', alignItems: 'center', gap: 5,
            boxShadow: '0 4px 14px rgba(123,92,255,0.5)',
          }}>
            <I.Sparkle size={14} stroke={2.2}/>生成
          </button>
        </div>
      </div>

      {/* Scrollable body */}
      <div className="no-scrollbar" style={{ flex: 1, overflow: 'auto', padding: '0 14px 0' }}>

        {/* Dimensions panel */}
        <GlassCard padding={14} radius={20} style={{ marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--forge-text-2)', letterSpacing: 0.6 }}>
              创意维度 · 能量校准
            </div>
            <Chip tone="violet">58%</Chip>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', columnGap: 12, rowGap: 8 }}>
            {dims.map(d => (
              <div key={d.k}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10.5, color: 'var(--forge-text-2)', marginBottom: 3 }}>
                  <span>{d.k}</span>
                  <span style={{ color: 'var(--forge-text-3)' }}>{Math.round(d.v*100)}</span>
                </div>
                <EnergyBar value={d.v} color={d.on} height={3} />
              </div>
            ))}
          </div>
        </GlassCard>

        {/* Setting cards (compact horizontal hint) */}
        <div style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 8px' }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--forge-text-2)', letterSpacing: 0.5 }}>设定卡片</div>
            <div style={{ fontSize: 11, color: 'var(--forge-text-3)' }}>5 张已锁 · 4 待生成</div>
          </div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto' }} className="no-scrollbar">
            {[
              { k: '玩法', t: '左右滑动 + 长按吸附磁轨' , tone: 'violet', on: true },
              { k: '美术', t: '霓虹合成波 · 紫青双色辉光' , tone: 'cyan', on: true },
              { k: '机制', t: '?' , tone: 'draft', on: false },
            ].map(c => (
              <div key={c.k} style={{
                flex: '0 0 168px', padding: 12, borderRadius: 16,
                background: c.on ? 'rgba(154,125,255,0.07)' : 'rgba(255,255,255,0.035)',
                border: `0.5px solid ${c.on ? 'rgba(154,125,255,0.3)' : 'rgba(255,255,255,0.08)'}`,
                backdropFilter: 'blur(12px)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span style={{ fontSize: 11, color: 'var(--forge-text-3)', letterSpacing: 0.6, textTransform: 'uppercase' }}>{c.k}</span>
                  {c.on ? <Chip tone="violet">已锁</Chip> : <Chip tone="draft">待定</Chip>}
                </div>
                <div style={{ fontSize: 12.5, color: c.on ? 'var(--forge-text-1)' : 'var(--forge-text-3)', lineHeight: 1.45, minHeight: 36 }}>
                  {c.t}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* AI chat */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingBottom: 10 }}>
          {/* AI message */}
          <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <div style={{ width: 26, height: 26, marginTop: 2, flexShrink: 0 }}>
              <NebulaOrb size={26} spin={false}/>
            </div>
            <div style={{
              maxWidth: '78%', padding: '10px 12px', borderRadius: 16, borderTopLeftRadius: 6,
              background: 'rgba(255,255,255,0.05)',
              border: '0.5px solid rgba(255,255,255,0.08)',
              fontSize: 13, color: 'var(--forge-text-1)', lineHeight: 1.5,
            }}>
              已锁定<span style={{color:'#cbb8ff'}}> 玩法 </span>和<span style={{color:'#cbb8ff'}}> 美术</span>。需要先确认<b style={{color:'var(--forge-cyan-300)'}}>核心机制</b>——是要追逐分数，还是探索关卡？
            </div>
          </div>
          {/* user message */}
          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <div style={{
              maxWidth: '72%', padding: '10px 12px', borderRadius: 16, borderTopRightRadius: 6,
              background: 'linear-gradient(180deg, rgba(155,128,255,0.45), rgba(123,92,255,0.28))',
              border: '0.5px solid rgba(154,125,255,0.45)',
              fontSize: 13, color: '#fff', lineHeight: 1.5,
              boxShadow: '0 4px 16px rgba(123,92,255,0.35)',
            }}>
              先做无尽追分，磁轨上有可吸附的能量块，撞墙就 GG
            </div>
          </div>
          {/* AI follow-up with chip choices */}
          <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <div style={{ width: 26, height: 26, marginTop: 2, flexShrink: 0 }}>
              <NebulaOrb size={26} spin={false}/>
            </div>
            <div style={{ maxWidth: '82%' }}>
              <div style={{
                padding: '10px 12px', borderRadius: 16, borderTopLeftRadius: 6,
                background: 'rgba(255,255,255,0.05)',
                border: '0.5px solid rgba(255,255,255,0.08)',
                fontSize: 13, color: 'var(--forge-text-1)', lineHeight: 1.5,
              }}>
                太好了。难度曲线想偏哪边？
              </div>
              <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                {['节奏紧凑 · 短关卡', '渐进 · 速度递增', '硬核 · 一击毙'].map(s => (
                  <button key={s} style={{
                    padding: '6px 10px', borderRadius: 999, fontSize: 11.5,
                    background: 'rgba(79,201,232,0.1)',
                    border: '0.5px solid rgba(79,201,232,0.35)',
                    color: '#9beaff', fontWeight: 500,
                  }}>{s}</button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom: manual card toolbar + input */}
      <div style={{ padding: '0 14px 90px', position: 'relative' }}>
        {/* manual cards horizontal scroll */}
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 8, marginBottom: 8 }} className="no-scrollbar">
          {[
            { l: '玩法', i: <I.Joystick size={13}/> },
            { l: '故事', i: <I.Compass size={13}/> },
            { l: '美术', i: <I.Palette size={13}/> },
            { l: '音乐', i: <I.Music size={13}/> },
            { l: '素材', i: <I.Image size={13}/> },
            { l: '笔记', i: <I.Edit size={13}/> },
          ].map(c => (
            <button key={c.l} style={{
              flexShrink: 0, height: 28, padding: '0 10px', borderRadius: 14,
              background: 'rgba(255,255,255,0.05)',
              border: '0.5px solid rgba(255,255,255,0.1)',
              color: 'var(--forge-text-2)', fontSize: 11.5,
              display: 'flex', alignItems: 'center', gap: 5,
            }}>{c.i}{c.l}</button>
          ))}
        </div>
        {/* Input bar */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: '6px 6px 6px 14px', borderRadius: 22,
          background: 'rgba(255,255,255,0.05)',
          border: '0.5px solid rgba(154,125,255,0.28)',
          backdropFilter: 'blur(18px)',
          boxShadow: '0 0 0 3px rgba(123,92,255,0.06), 0 6px 22px rgba(0,0,0,0.4)',
        }}>
          <div style={{ flex: 1, fontSize: 13.5, color: 'var(--forge-text-3)' }}>
            告诉锻造台下一步…
          </div>
          <button style={{
            width: 38, height: 38, borderRadius: 19,
            background: 'linear-gradient(180deg, rgba(255,255,255,0.18), rgba(255,255,255,0)), linear-gradient(180deg, #8b6bff, #5a3fe6)',
            border: '0.5px solid rgba(255,255,255,0.2)',
            color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(123,92,255,0.5)',
          }}><I.Send size={16} stroke={2.2}/></button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// PREVIEW — debug deck with game canvas + tabs
// ─────────────────────────────────────────────────────────────
function PreviewScreen({ tab = 'code' }) {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Top action bar */}
      <div style={{
        paddingTop: 54, paddingLeft: 12, paddingRight: 12, paddingBottom: 10,
        display: 'flex', alignItems: 'center', gap: 6,
      }}>
        <IconBtn><I.ChevronL size={16}/></IconBtn>
        <div style={{ flex: 1, minWidth: 0, paddingLeft: 4 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--forge-text-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            霓虹漂流 · 预览
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 1 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: '#5be7a7', boxShadow: '0 0 6px #5be7a7' }}/>
            <span style={{ fontSize: 10.5, color: 'var(--forge-text-3)' }}>运行中 · Phaser 3</span>
          </div>
        </div>
        <IconBtn><I.Volume size={15}/></IconBtn>
        <IconBtn><I.Expand size={15}/></IconBtn>
        <IconBtn><I.Share size={14}/></IconBtn>
        <IconBtn><I.More size={16}/></IconBtn>
      </div>

      {/* Game canvas */}
      <div style={{ padding: '0 14px' }}>
        <div style={{
          height: 240, borderRadius: 20, overflow: 'hidden', position: 'relative',
          background: 'linear-gradient(180deg, #110a2a 0%, #04030a 100%)',
          border: '0.5px solid rgba(154,125,255,0.22)',
          boxShadow: '0 12px 36px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05)',
        }}>
          {/* sci-fi grid floor */}
          <svg viewBox="0 0 360 240" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
            <defs>
              <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#7b5cff" stopOpacity="0"/>
                <stop offset="100%" stopColor="#7b5cff" stopOpacity="0.6"/>
              </linearGradient>
              <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5">
                <stop offset="0%" stopColor="#ffb060"/>
                <stop offset="60%" stopColor="#ff5a8b" stopOpacity="0.8"/>
                <stop offset="100%" stopColor="#7b5cff" stopOpacity="0"/>
              </radialGradient>
            </defs>
            {/* sun */}
            <circle cx="180" cy="110" r="60" fill="url(#sun)"/>
            <line x1="160" y1="80" x2="200" y2="80" stroke="#0b0a22" strokeWidth="2"/>
            <line x1="155" y1="90" x2="205" y2="90" stroke="#0b0a22" strokeWidth="2"/>
            <line x1="150" y1="100" x2="210" y2="100" stroke="#0b0a22" strokeWidth="2"/>
            <line x1="145" y1="110" x2="215" y2="110" stroke="#0b0a22" strokeWidth="2"/>
            {/* horizon */}
            <line x1="0" y1="140" x2="360" y2="140" stroke="#9beaff" strokeWidth="0.7"/>
            {/* perspective floor */}
            <g stroke="url(#floor)" strokeWidth="0.7" fill="none">
              {[0,1,2,3,4,5,6,7,8].map(i => (
                <line key={i} x1={-200 + i*100} y1="240" x2="180" y2="140"/>
              ))}
              {[0,1,2,3,4,5,6,7,8].map(i => (
                <line key={i} x1={180 + i*100 - 200} y1="140" x2={560 - i*100} y2="240"/>
              ))}
              {[0,1,2,3,4].map(i => (
                <line key={i} x1="0" y1={150 + i*22} x2="360" y2={150 + i*22}/>
              ))}
            </g>
            {/* player car (placeholder shape) */}
            <g transform="translate(170 195)">
              <rect x="0" y="0" width="20" height="14" rx="3" fill="#9beaff"/>
              <rect x="4" y="-4" width="12" height="6" rx="2" fill="#fff"/>
              <ellipse cx="10" cy="18" rx="14" ry="3" fill="#7b5cff" opacity="0.5"/>
            </g>
            {/* HUD */}
            <g fontFamily="ui-monospace, monospace">
              <text x="14" y="22" fontSize="10" fill="#9beaff">SCORE 02480</text>
              <text x="280" y="22" fontSize="10" fill="#ffd99e">×3</text>
            </g>
            {/* energy chips */}
            <circle cx="80" cy="170" r="3" fill="#5be7a7"/>
            <circle cx="280" cy="180" r="3" fill="#5be7a7"/>
          </svg>
          {/* canvas badge */}
          <div style={{
            position: 'absolute', top: 10, left: 10, padding: '4px 8px', borderRadius: 8,
            background: 'rgba(0,0,0,0.45)', backdropFilter: 'blur(10px)',
            border: '0.5px solid rgba(255,255,255,0.1)',
            fontSize: 9.5, color: 'rgba(255,255,255,0.8)', letterSpacing: 0.8,
            fontFamily: 'var(--font-mono)',
          }}>402 × 240 · 60 FPS</div>
        </div>
      </div>

      {/* Tab strip */}
      <div style={{ padding: '14px 14px 0' }}>
        <div style={{
          display: 'flex', padding: 4, borderRadius: 14,
          background: 'rgba(255,255,255,0.04)',
          border: '0.5px solid rgba(255,255,255,0.08)',
        }}>
          {[
            { id: 'code', label: '代码', i: <I.Code size={13}/> },
            { id: 'chat', label: '对话', i: <I.Chat size={13}/> },
            { id: 'asset', label: '素材', i: <I.Palette size={13}/> },
            { id: 'info', label: '信息', i: <I.Info size={13}/> },
          ].map(t => {
            const on = t.id === tab;
            return (
              <div key={t.id} style={{
                flex: 1, height: 30, borderRadius: 11,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
                fontSize: 12, fontWeight: on ? 600 : 500,
                background: on ? 'rgba(154,125,255,0.18)' : 'transparent',
                border: on ? '0.5px solid rgba(154,125,255,0.4)' : '0.5px solid transparent',
                color: on ? '#fff' : 'var(--forge-text-3)',
                boxShadow: on ? '0 2px 10px rgba(123,92,255,0.3), inset 0 1px 0 rgba(255,255,255,0.1)' : 'none',
              }}>{t.i}{t.label}</div>
            );
          })}
        </div>
      </div>

      {/* Tab content — Code */}
      <div style={{ flex: 1, padding: '12px 14px 16px', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{
              padding: '4px 10px', borderRadius: 8,
              background: 'rgba(255,255,255,0.06)',
              border: '0.5px solid rgba(255,255,255,0.1)',
              fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--forge-text-2)',
              display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <span style={{ width: 8, height: 8, borderRadius: 2, background: '#ff8a4c'}}/>
              index.html
            </div>
            <span style={{ fontSize: 11, color: 'var(--forge-text-3)' }}>248 行 · 9.2 KB</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <IconBtn size={28}><I.Copy size={13}/></IconBtn>
            <IconBtn size={28}><I.Edit size={13}/></IconBtn>
            <button style={{
              height: 28, padding: '0 10px', borderRadius: 10,
              background: 'linear-gradient(180deg, rgba(155,128,255,0.45), rgba(123,92,255,0.28))',
              border: '0.5px solid rgba(154,125,255,0.5)',
              color: '#fff', fontSize: 11.5, fontWeight: 600,
              display: 'flex', alignItems: 'center', gap: 4,
              boxShadow: '0 3px 10px rgba(123,92,255,0.35)',
            }}><I.Check size={12} stroke={2.2}/>应用</button>
          </div>
        </div>
        {/* code block */}
        <div style={{
          flex: 1, borderRadius: 16, overflow: 'hidden',
          background: 'linear-gradient(180deg, #07061a 0%, #04030a 100%)',
          border: '0.5px solid rgba(255,255,255,0.06)',
          fontFamily: 'var(--font-mono)', fontSize: 10.5, lineHeight: 1.55,
          padding: '10px 0',
          position: 'relative',
        }}>
          <CodeView/>
          {/* bottom gradient fade */}
          <div style={{
            position: 'absolute', left: 0, right: 0, bottom: 0, height: 60,
            background: 'linear-gradient(180deg, transparent, #04030a)',
            pointerEvents: 'none',
          }}/>
        </div>
      </div>
    </div>
  );
}

function CodeView() {
  const c = {
    kw: '#cbb8ff', tag: '#9beaff', str: '#ffd99e', com: 'rgba(244,241,255,0.32)',
    fn: '#9beaff', txt: 'rgba(244,241,255,0.85)', num: '#f2c36b', op: 'rgba(244,241,255,0.55)',
  };
  const lines = [
    [{c:c.com, t:'// Neon Drift — main loop'}],
    [{c:c.kw, t:'const'},{c:c.txt, t:' '},{c:c.fn,t:'game'},{c:c.op,t:' = '},{c:c.kw,t:'new'},{c:c.txt,t:' '},{c:c.fn,t:'Phaser.Game'},{c:c.op,t:'({'}],
    [{c:c.txt,t:'  type'},{c:c.op,t:': '},{c:c.fn,t:'Phaser'},{c:c.op,t:'.'},{c:c.tag,t:'WEBGL'},{c:c.op,t:','}],
    [{c:c.txt,t:'  width'},{c:c.op,t:': '},{c:c.num,t:'402'},{c:c.op,t:', '},{c:c.txt,t:'height'},{c:c.op,t:': '},{c:c.num,t:'720'},{c:c.op,t:','}],
    [{c:c.txt,t:'  scene'},{c:c.op,t:': ['},{c:c.fn,t:'PreloadScene'},{c:c.op,t:', '},{c:c.fn,t:'PlayScene'},{c:c.op,t:']'}],
    [{c:c.op,t:'});'}],
    [{c:c.txt,t:''}],
    [{c:c.kw, t:'class'},{c:c.txt, t:' '},{c:c.fn,t:'PlayScene'},{c:c.txt,t:' '},{c:c.kw,t:'extends'},{c:c.txt,t:' '},{c:c.fn,t:'Phaser.Scene'},{c:c.op,t:' {'}],
    [{c:c.fn,t:'  create'},{c:c.op,t:'() {'}],
    [{c:c.kw,t:'    this'},{c:c.op,t:'.'},{c:c.txt,t:'player'},{c:c.op,t:' = '},{c:c.kw,t:'this'},{c:c.op,t:'.physics.add.'},{c:c.fn,t:'sprite'},{c:c.op,t:'('},{c:c.num,t:'201'},{c:c.op,t:', '},{c:c.num,t:'620'},{c:c.op,t:', '},{c:c.str,t:'"car"'},{c:c.op,t:');'}],
    [{c:c.kw,t:'    this'},{c:c.op,t:'.lane '},{c:c.op,t:'= '},{c:c.num,t:'1'},{c:c.op,t:';'}],
    [{c:c.kw,t:'    this'},{c:c.op,t:'.input.on('},{c:c.str,t:'"pointermove"'},{c:c.op,t:', '},{c:c.kw,t:'this'},{c:c.op,t:'.'},{c:c.fn,t:'swipe'},{c:c.op,t:', '},{c:c.kw,t:'this'},{c:c.op,t:');'}],
    [{c:c.op,t:'  }'}],
    [{c:c.op,t:'}'}],
  ];
  return (
    <div style={{ display: 'flex', overflow: 'auto', height: '100%' }}>
      <div style={{
        flexShrink: 0, padding: '0 8px 0 12px', textAlign: 'right',
        color: 'rgba(244,241,255,0.2)', userSelect: 'none', borderRight: '0.5px solid rgba(255,255,255,0.05)',
      }}>
        {lines.map((_, i) => <div key={i}>{i+1}</div>)}
      </div>
      <div style={{ flex: 1, padding: '0 12px', whiteSpace: 'pre', overflowX: 'auto' }}>
        {lines.map((line, i) => (
          <div key={i}>
            {line.map((s, j) => <span key={j} style={{ color: s.c }}>{s.t}</span>)}
            {line.length === 0 && '\u00A0'}
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { SplashScreen, WorkspaceScreen, PreviewScreen });
