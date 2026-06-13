/* @jsx React.createElement */
// Shared FanWorkspace
// 顶部: 风扇式卡轮 (绕底部支点旋转, 不堆叠, 侧卡可读)
// 底部: 对话区, 可由用户向上拖拽展开覆盖卡片
// 两种 variant: 'a' (iOS 原生派 sans-serif) / 'b' (编辑工坊派 serif+mono)

function FanWorkspace({ theme, variant = 'a' }) {
  // ── Data ───────────────────────────────────────────────────
  const cards = [
    { k: '玩法', en: 'GAMEPLAY', t: '左右滑动 + 长按吸附磁轨', locked: true },
    { k: '美术', en: 'ART',      t: '霓虹合成波 · 紫青双色辉光', locked: true },
    { k: '故事', en: 'STORY',    t: '一名疯狂赛车手穿越异次元高速', locked: true },
    { k: '视角', en: 'CAMERA',   t: '第三人称跟随 · 略微俯视', locked: true },
    { k: '目标', en: 'GOAL',     t: '尽可能远 · 累积分数 · 无尽模式', locked: true },
    { k: '机制', en: 'MECHANIC', t: '可吸附的能量碎片 + 撞墙判定？', locked: false, draft: true },
    { k: '能力', en: 'ABILITY',  t: '?', locked: false },
    { k: '音乐', en: 'AUDIO',    t: '?', locked: false },
    { k: '难度', en: 'DIFFICULTY', t: '?', locked: false },
  ];

  // ── State ──────────────────────────────────────────────────
  const [active, setActive] = React.useState(2);
  const [chatExpanded, setChatExpanded] = React.useState(false);

  // Carousel drag (horizontal)
  const carRef = React.useRef({ x: null });
  const [carDx, setCarDx] = React.useState(0);

  // Chat sheet drag (vertical)
  const chatRef = React.useRef({ y: null });
  const [chatDy, setChatDy] = React.useState(0);

  // ── Carousel handlers ──────────────────────────────────────
  const onCarDown = (e) => {
    carRef.current.x = e.clientX;
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onCarMove = (e) => {
    if (carRef.current.x === null) return;
    setCarDx(e.clientX - carRef.current.x);
  };
  const onCarUp = (e) => {
    const dx = e.clientX - (carRef.current.x ?? e.clientX);
    if (dx > 50 && active > 0) setActive(active - 1);
    else if (dx < -50 && active < cards.length - 1) setActive(active + 1);
    setCarDx(0);
    carRef.current.x = null;
  };

  // ── Chat drag handlers ─────────────────────────────────────
  const onChatDown = (e) => {
    chatRef.current.y = e.clientY;
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onChatMove = (e) => {
    if (chatRef.current.y === null) return;
    setChatDy(e.clientY - chatRef.current.y);
  };
  const onChatUp = (e) => {
    const dy = chatDy;
    if (chatExpanded && dy > 50) setChatExpanded(false);
    else if (!chatExpanded && dy < -50) setChatExpanded(true);
    setChatDy(0);
    chatRef.current.y = null;
  };

  // ── Layout sizing ──────────────────────────────────────────
  // total content area inside phone ~ 790
  // nav grows naturally now; cards area follows
  const cardsH_split = 360;
  const cardsH_collapsed = 122;  // peek strip
  // live offset during drag for natural feel
  const liveOffset = chatDy + (chatExpanded ? 0 : 0);
  const cardsH = chatExpanded
    ? Math.min(cardsH_split, cardsH_collapsed + Math.max(0, liveOffset))
    : Math.max(cardsH_collapsed, cardsH_split + Math.min(0, liveOffset));

  const isSerif = variant === 'b';

  // ── Render ─────────────────────────────────────────────────
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: 'var(--bg)', overflow: 'hidden', position: 'relative',
    }}>

      {/* ── Nav ─ generous top breathing room ─────────────── */}
      <div style={{
        padding: '58px 18px 16px',
        display: 'flex', alignItems: 'center', gap: 12,
        boxSizing: 'border-box', flexShrink: 0,
      }}>
        <button style={btnIcon(variant)}>
          <I2.ChevL size={16} stroke={2.4}/>
        </button>
        <div style={{ flex: 1, minWidth: 0 }}>
          {isSerif ? (
            <>
              <div style={{
                fontFamily: 'var(--font-mono)', fontSize: 9.5, letterSpacing: 1.3,
                color: 'var(--text-3)', fontWeight: 600,
              }}>WORKSPACE · 5 / 9 LOCKED</div>
              <div style={{
                marginTop: 3,
                fontFamily: 'var(--font-display)', fontSize: 26, lineHeight: 1.05,
                color: 'var(--text-1)', letterSpacing: -0.6, fontStyle: 'italic',
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
              }}>霓虹漂流</div>
            </>
          ) : (
            <>
              <div style={{ fontSize: 11, color: 'var(--text-2)', letterSpacing: 0.4, fontWeight: 500 }}>
                5 / 9 维度已锁定
              </div>
              <div style={{
                marginTop: 1, fontSize: 18, fontWeight: 600, color: 'var(--text-1)',
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
              }}>霓虹漂流</div>
            </>
          )}
        </div>
        {/* Labeled GENERATE button — replaces mystery sparkle */}
        {isSerif ? (
          <button style={{
            height: 36, padding: '0 13px', borderRadius: 8,
            background: 'var(--accent)', color: 'var(--accent-fg)',
            border: 'none', cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 6,
            fontFamily: 'var(--font-mono)', fontSize: 10.5, fontWeight: 700, letterSpacing: 1.4,
          }}>
            <I2.Sparkle size={12} stroke={2.4}/>GENERATE
          </button>
        ) : (
          <button style={{
            height: 32, padding: '0 12px', borderRadius: 16,
            background: 'var(--accent)', color: 'var(--accent-fg)',
            border: 'none', cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 5,
            fontSize: 13, fontWeight: 600,
          }}>
            <I2.Sparkle size={13} stroke={2.4}/>生成
          </button>
        )}
      </div>

      {/* ── Cards area (height animated) ────────────────── */}
      <div style={{
        height: cardsH,
        transition: chatRef.current.y === null ? 'height 380ms cubic-bezier(.2,.9,.3,1.1)' : 'none',
        position: 'relative', flexShrink: 0,
      }}>
        <FanCarousel
          cards={cards}
          active={active}
          carDx={carDx}
          dragging={carRef.current.x !== null}
          onCarDown={onCarDown}
          onCarMove={onCarMove}
          onCarUp={onCarUp}
          variant={variant}
          collapsed={chatExpanded}
          height={cardsH}
        />

        {/* Pagination dots */}
        <div style={{
          position: 'absolute', bottom: 6, left: 0, right: 0,
          display: 'flex', justifyContent: 'center', gap: 5,
          opacity: chatExpanded ? 0 : 1, transition: 'opacity 200ms',
          pointerEvents: chatExpanded ? 'none' : 'auto',
        }}>
          {cards.map((_, i) => (
            <span key={i} onClick={() => setActive(i)} style={{
              width: i === active ? 18 : 5, height: 5, borderRadius: 3,
              background: i === active ? 'var(--accent)' : 'var(--text-4)',
              transition: 'all 280ms', cursor: 'pointer',
            }}/>
          ))}
        </div>
      </div>

      {/* ── Chat region (flex remainder) ────────────────── */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        background: isSerif ? 'var(--surface)' : 'var(--surface)',
        borderTop: `0.5px solid ${isSerif ? 'var(--line-strong)' : 'var(--line)'}`,
        borderTopLeftRadius: isSerif ? 0 : 22,
        borderTopRightRadius: isSerif ? 0 : 22,
        boxShadow: isSerif ? 'none' : '0 -8px 24px rgba(0,0,0,0.06)',
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Drag handle — owns vertical pointer events */}
        <div
          onPointerDown={onChatDown} onPointerMove={onChatMove} onPointerUp={onChatUp}
          style={{
            padding: '8px 0 4px', display: 'flex', flexDirection: 'column', alignItems: 'center',
            cursor: 'ns-resize', touchAction: 'none', userSelect: 'none', flexShrink: 0,
          }}
        >
          <div style={{
            width: 38, height: 4, borderRadius: 2,
            background: chatExpanded ? 'var(--accent)' : 'var(--text-4)',
            transition: 'background 200ms',
          }}/>
          {isSerif ? (
            <div style={{
              marginTop: 6, fontFamily: 'var(--font-mono)', fontSize: 9.5, letterSpacing: 1.2,
              color: 'var(--text-3)',
            }}>{chatExpanded ? '↓ DRAG TO COLLAPSE' : '↑ DRAG UP TO CHAT'}</div>
          ) : (
            <div style={{ marginTop: 4, fontSize: 11, color: 'var(--text-3)' }}>
              {chatExpanded ? '下拉收起' : '上拉对话'}
            </div>
          )}
        </div>

        {/* Chat messages */}
        <div className="no-scrollbar" style={{
          flex: 1, overflow: 'auto', padding: '4px 16px',
          display: 'flex', flexDirection: 'column', gap: 12,
        }}>
          <ChatMsg variant={variant} side="ai">
            已锁定 <strong style={{color: 'var(--accent)'}}>玩法</strong> 和 <strong style={{color: 'var(--accent)'}}>美术</strong>。下一步确认 <strong>核心机制</strong> —— 追逐分数，还是探索关卡？
          </ChatMsg>
          <ChatMsg variant={variant} side="user">
            先做无尽追分，撞墙就 GG
          </ChatMsg>

          {chatExpanded && (
            <>
              <ChatMsg variant={variant} side="ai">
                好。我会把<strong>机制</strong>固定为：无尽奔跑 · 可吸附能量块 · 撞墙即终结。难度曲线想偏哪边？
              </ChatMsg>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', paddingLeft: variant === 'a' ? 34 : 0 }}>
                {['节奏紧凑', '速度递增', '一击毙'].map(s => (
                  <button key={s} style={chipBtn(variant)}>{s}</button>
                ))}
              </div>
              <ChatMsg variant={variant} side="user">
                选速度递增，每 30 秒上一档
              </ChatMsg>
              <ChatMsg variant={variant} side="ai">
                ✓ 难度卡片已生成。还需要确认音乐风格 —— 我推荐 <strong style={{color:'var(--accent)'}}>合成波 / 鼓机驱动</strong>，节奏与提速同步。
              </ChatMsg>
            </>
          )}
        </div>

        {/* Input row */}
        <div style={{ padding: '8px 14px 28px', flexShrink: 0 }}>
          <div style={inputWrap(variant)}>
            <div style={{ flex: 1, fontSize: 14, color: 'var(--text-3)' }}>
              {chatExpanded ? '继续这个想法…' : '告诉它下一步…'}
            </div>
            <button style={sendBtn(variant)}>
              <I2.Send size={15} stroke={2.4}/>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// FanCarousel — cards orbit a pivot below the carousel
// ─────────────────────────────────────────────────────────────
function FanCarousel({ cards, active, carDx, dragging, onCarDown, onCarMove, onCarUp, variant, collapsed, height }) {
  // Effective position uses live drag for buttery feel
  const liveActive = active - carDx / 180;

  const isSerif = variant === 'b';
  const cardW = 250;
  const cardH = collapsed ? 130 : 240;

  return (
    <div
      onPointerDown={onCarDown} onPointerMove={onCarMove} onPointerUp={onCarUp}
      style={{
        position: 'absolute', inset: 0,
        touchAction: 'pan-y', cursor: dragging ? 'grabbing' : 'grab',
        overflow: 'hidden',
      }}
    >
      {/* Render visible cards only */}
      {cards.map((card, i) => {
        const offset = i - liveActive;
        const abs = Math.abs(offset);
        if (abs > 2.6) return null;

        // Fan geometry — pivot is 180% down from card
        const rot = offset * 18;     // ±18° per slot
        const tx = offset * 150;     // ±150px per slot
        const ty = abs * abs * 22;   // arc dip
        const scale = collapsed ? 0.6 : (1 - Math.min(abs, 2) * 0.10);
        const opacity = 1 - Math.min(abs, 2) * 0.35;

        return (
          <div key={i} style={{
            position: 'absolute',
            top: collapsed ? -40 : 18,
            left: '50%',
            width: cardW, height: cardH, marginLeft: -cardW/2,
            transform: `translateX(${tx}px) translateY(${ty}px) rotate(${rot}deg) scale(${scale})`,
            transformOrigin: '50% 180%',
            opacity,
            zIndex: 100 - Math.round(abs * 10),
            transition: dragging
              ? 'none'
              : 'transform 420ms cubic-bezier(.2,.9,.3,1.15), opacity 300ms, height 380ms cubic-bezier(.2,.9,.3,1.1), top 380ms cubic-bezier(.2,.9,.3,1.1)',
            pointerEvents: abs < 0.5 ? 'auto' : 'none',
          }}>
            <SettingCard card={card} variant={variant} isActive={abs < 0.5} collapsed={collapsed}/>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// SettingCard
// ─────────────────────────────────────────────────────────────
function SettingCard({ card, variant, isActive, collapsed }) {
  const isSerif = variant === 'b';
  const locked = card.locked;
  return (
    <div style={{
      width: '100%', height: '100%',
      background: 'var(--surface)',
      border: locked
        ? `0.5px solid ${isSerif ? 'var(--accent-line)' : 'var(--accent-line)'}`
        : `0.5px solid var(--line-strong)`,
      borderRadius: isSerif ? 12 : 22,
      padding: collapsed ? '14px 16px' : '18px 18px',
      boxSizing: 'border-box',
      display: 'flex', flexDirection: 'column',
      boxShadow: isActive
        ? (isSerif ? 'none' : '0 12px 32px rgba(0,0,0,0.10)')
        : 'none',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {isSerif ? (
            <div style={{
              fontFamily: 'var(--font-mono)', fontSize: 10.5, letterSpacing: 1.4,
              color: 'var(--text-3)', fontWeight: 600,
            }}>{card.en}</div>
          ) : (
            <div style={{ fontSize: 12, color: 'var(--text-2)', fontWeight: 500, letterSpacing: 0.4 }}>
              {card.k} · {card.en}
            </div>
          )}
        </div>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          padding: '2px 7px',
          borderRadius: isSerif ? 4 : 999,
          background: locked ? 'var(--accent-tint)' : 'var(--secondary-bg)',
          color: locked ? 'var(--accent)' : 'var(--text-3)',
          fontFamily: isSerif ? 'var(--font-mono)' : 'var(--font-ui)',
          fontSize: isSerif ? 9.5 : 10.5,
          fontWeight: 600,
          letterSpacing: isSerif ? 1 : 0.4,
          textTransform: isSerif ? 'uppercase' : 'none',
        }}>
          {locked && <span style={{
            width: 5, height: 5, borderRadius: 3, background: 'var(--accent)',
          }}/>}
          {locked ? (isSerif ? 'LOCKED' : '已锁') : (card.draft ? (isSerif ? 'DRAFT' : '草稿') : (isSerif ? 'EMPTY' : '待定'))}
        </div>
      </div>

      {/* Big dimension name */}
      <div style={{
        marginTop: collapsed ? 6 : 14,
        fontFamily: isSerif ? 'var(--font-display)' : 'var(--font-ui)',
        fontSize: collapsed ? 24 : (isSerif ? 40 : 30),
        fontWeight: isSerif ? 400 : 700,
        lineHeight: 1, letterSpacing: isSerif ? -1.2 : -0.6,
        color: 'var(--text-1)',
        fontStyle: isSerif ? 'italic' : 'normal',
      }}>{card.k}</div>

      {/* Description fills */}
      {!collapsed && (
        <div style={{
          marginTop: 'auto',
          fontSize: 14, lineHeight: 1.55,
          color: locked ? 'var(--text-1)' : 'var(--text-3)',
          fontStyle: card.t === '?' ? 'italic' : 'normal',
        }}>
          {card.t}
        </div>
      )}

      {/* Bottom footer for active card */}
      {!collapsed && (
        <div style={{
          marginTop: 12, paddingTop: 10, borderTop: `0.5px dashed var(--line)`,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span style={{
            fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-3)', letterSpacing: 0.5,
          }}>
            {locked ? 'TAP TO EDIT' : 'TAP TO FILL'}
          </span>
          <I2.Chev size={12} color="var(--text-3)" stroke={2}/>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ChatMsg
// ─────────────────────────────────────────────────────────────
function ChatMsg({ side, variant, children }) {
  const isSerif = variant === 'b';
  if (side === 'ai') {
    return (
      <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start' }}>
        <div style={{
          width: 26, height: 26, borderRadius: isSerif ? 6 : 13, flexShrink: 0,
          background: 'var(--accent-tint)', color: 'var(--accent)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: isSerif ? '0.5px solid var(--accent-line)' : 'none',
        }}>
          {isSerif ? <ForgeMarkB size={15} color="currentColor" accent="currentColor"/>
                   : <ForgeMark size={16} color="currentColor" accent="currentColor"/>}
        </div>
        <div style={{
          maxWidth: '80%', padding: isSerif ? '10px 12px' : '10px 14px',
          background: isSerif ? 'transparent' : 'var(--secondary-bg)',
          border: isSerif ? '0.5px solid var(--line-strong)' : 'none',
          borderRadius: isSerif ? 8 : 18, borderTopLeftRadius: isSerif ? 8 : 6,
          fontSize: 14, color: 'var(--text-1)', lineHeight: 1.5,
        }}>{children}</div>
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
      <div style={{
        maxWidth: '78%', padding: isSerif ? '10px 12px' : '10px 14px',
        background: 'var(--accent)', color: 'var(--accent-fg)',
        borderRadius: isSerif ? 8 : 18, borderTopRightRadius: isSerif ? 8 : 6,
        fontSize: 14, lineHeight: 1.5,
      }}>{children}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Style helpers
// ─────────────────────────────────────────────────────────────
function btnIcon(variant) {
  const isSerif = variant === 'b';
  return {
    width: isSerif ? 36 : 32, height: isSerif ? 36 : 32,
    borderRadius: isSerif ? 10 : 16,
    background: isSerif ? 'transparent' : 'var(--secondary-bg)',
    color: isSerif ? 'var(--text-1)' : 'var(--accent)',
    border: isSerif ? '0.5px solid var(--line-strong)' : 'none',
    cursor: 'pointer', padding: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}
function btnAccent(variant) {
  const isSerif = variant === 'b';
  return {
    width: isSerif ? 36 : 32, height: isSerif ? 36 : 32,
    borderRadius: isSerif ? 10 : 16,
    background: 'var(--accent)', color: 'var(--accent-fg)',
    border: 'none', cursor: 'pointer', padding: 0,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}
function chipBtn(variant) {
  const isSerif = variant === 'b';
  return {
    padding: isSerif ? '6px 12px' : '7px 12px',
    borderRadius: isSerif ? 6 : 999,
    background: isSerif ? 'transparent' : 'var(--secondary-bg)',
    border: isSerif ? '0.5px solid var(--line-strong)' : 'none',
    color: 'var(--text-1)',
    fontFamily: isSerif ? 'var(--font-mono)' : 'var(--font-ui)',
    fontSize: isSerif ? 11 : 12.5,
    letterSpacing: isSerif ? 0.6 : 0,
    fontWeight: 500, cursor: 'pointer',
  };
}
function inputWrap(variant) {
  const isSerif = variant === 'b';
  return {
    display: 'flex', alignItems: 'center', gap: 8,
    padding: '6px 6px 6px 14px',
    borderRadius: isSerif ? 8 : 22,
    background: 'var(--bg)',
    border: '0.5px solid var(--line-strong)',
  };
}
function sendBtn(variant) {
  const isSerif = variant === 'b';
  return {
    width: 36, height: 36, borderRadius: isSerif ? 6 : 18, border: 'none', cursor: 'pointer',
    background: 'var(--accent)', color: 'var(--accent-fg)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}

Object.assign(window, { FanWorkspace });
