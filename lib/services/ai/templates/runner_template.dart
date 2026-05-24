import '../../../features/workspace/domain/game_spec.dart';
import '../game_design_document.dart';
import '../playability/genre_validator.dart';
import '../playability/runner_validator.dart';
import 'game_template.dart';

class RunnerTemplate extends GameTemplate {
  @override
  String get genreName => 'Runner';

  @override
  String get genreNameCN => '跑酷';

  @override
  GenrePlayabilityValidator get playabilityValidator =>
      RunnerPlayabilityValidator();

  @override
  String buildDesignPrompt(GameSpec spec) {
    final genreNote = spec.genre != null
        ? '(USER SPECIFIED — must follow this)'
        : '[Not specified — be creative, example: endless side-scrolling runner like Jetpack Joyride]';

    return '''You are designing a 2D endless runner / auto-scroller game. Output a structured JSON design document.

## Genre: Runner $genreNote
- Theme: ${spec.theme ?? '[Not specified]'}
- Art Style: ${spec.artStyle ?? '[Not specified]'}
- Core Mechanic: ${spec.coreMechanic ?? '[Not specified]'}
- Player Ability: ${spec.playerAbility ?? '[Not specified]'}
- Goal: ${spec.goal ?? '[Not specified]'}
- Difficulty: ${spec.difficulty ?? 'Medium'}

## Runner Design Rules
- The world **auto-scrolls** horizontally (or vertically). The player cannot stop moving forward.
- The player controls **jumping** (and optionally ducking/sliding) to avoid obstacles.
- Obstacles come from the right side: pits, spikes, barriers, moving enemies.
- Collectibles (coins/gems) are placed along the path as risk/reward incentives.
- Speed **gradually increases** over time, raising difficulty.
- Physics: gravity pulls the player down, jump is the primary action.
- The core loop: run forward → spot obstacle → time jump/duck → collect items → survive as long as possible.

## Required Output JSON Structure
{
  "title": "...",
  "genre": "Runner",
  "coreLoop": "30-second runner loop description",
  "objects": [
    {"name":"player","type":"player","properties":{"width":30,"height":40,"jumpForce":14,"gravity":0.7},"behaviors":["run","jump","duck","invincible_after_hit"],"visual":"..."},
    {"name":"ground","type":"platform","properties":{"height":20},"behaviors":["scroll_left","solid_top"],"visual":"scrolling ground tiles"},
    {"name":"obstacle_spike","type":"obstacle","properties":{"width":25,"height":30,"damage":1},"behaviors":["scroll_left","damage_player"],"visual":"..."},
    {"name":"coin","type":"collectible","properties":{"width":20,"height":20,"points":10},"behaviors":["scroll_left","collectible","spin_animate"],"visual":"..."}
  ],
  "physics": {"gravity":0.7,"friction":0,"jumpForce":14,"moveSpeed":0},
  "collision": {"platforms":"ground — solid top","enemies":"obstacles damage player","collectibles":"coins collect on contact"},
  "scoring": {"pointsPerCollectible":10,"winCondition":"reach target distance (e.g. 3000m) or endless (high score)","loseCondition":"hit obstacle with 0 HP"},
  "states": {"states":["title","playing","hit_flash","gameOver"]},
  "levels": [{"platforms":[],"enemies":[],"collectibles":[],"spawnPoint":{"x":80,"y":300},
    "runnerData": {"scrollSpeed":4,"speedIncrement":0.002,"obstacleInterval":90,"targetDistance":3000}}],
  "visual": {"background":"parallax scrolling layers (far mountains, mid trees, near ground)","colorPalette":"bright outdoors: sky blue, grass green, warm sun","playerAppearance":"...","effects":"speed lines, dust particles when running, coin sparkle, screen flash on hit"},
  "audioHints": "run: subtle footstep rhythm; jump: rising whoosh; coin: bright ding; hit: crash + temporary mute; milestone: celebratory jingle every 500m"
}

Output ONLY valid JSON, no markdown or commentary.''';
  }

  @override
  String get codeSkeleton => r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Runner</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#87CEEB; display:flex; justify-content:center; align-items:center; height:100vh; overflow:hidden; }
  canvas { display:block; border-radius:8px; }
</style>
</head>
<body>
<canvas id="g"></canvas>
<script>
// === SETUP ===
const canvas = document.getElementById('g');
const ctx = canvas.getContext('2d');
const GRAVITY = {{GRAVITY}};
const JUMP_FORCE = {{JUMP_FORCE}};
const GROUND_Y_RATIO = 0.78; // ground line at 78% of canvas height

let scrollSpeed = {{SCROLL_SPEED}};
const SPEED_INCREMENT = {{SPEED_INCREMENT}};
const OBSTACLE_INTERVAL = {{OBSTACLE_INTERVAL}};

function resize() {
  canvas.width = Math.min(innerWidth - 16, 420);
  canvas.height = Math.min(innerHeight - 16, 640);
}
window.addEventListener('resize', resize);
resize();

function groundY() { return canvas.height * GROUND_Y_RATIO; }

// === GAME STATE ===
let state = 'title'; // title | playing | hit_flash | gameOver
let score = 0;
let distance = 0;
let playerHP = 1; // 1 = one-hit death, or more with shields
let obstacleTimer = 0;
let coinTimer = 0;

// === PLAYER ===
const player = {
  x: 80, y: 200, width: 30, height: 40,
  vy: 0, grounded: true,
  ducking: false,
  invincible: false, invincibleTimer: 0
};

// === GAME OBJECTS ===
let obstacles = [];
let coins = [];
let particles = [];
let bgLayers = [0, 0, 0]; // parallax offsets

// === INPUT ===
let jumpPressed = false;
let duckPressed = false;

document.addEventListener('keydown', e => {
  if (e.key === 'ArrowUp' || e.key === ' ' || e.key === 'w') jumpPressed = true;
  if (e.key === 'ArrowDown' || e.key === 's') duckPressed = true;
  e.preventDefault();
});
document.addEventListener('keyup', e => {
  if (e.key === 'ArrowUp' || e.key === ' ' || e.key === 'w') jumpPressed = false;
  if (e.key === 'ArrowDown' || e.key === 's') duckPressed = false;
});

canvas.addEventListener('touchstart', e => {
  e.preventDefault();
  // Start/restart game on title or gameOver screen (iOS WKWebView blocks
  // click events after touchstart.preventDefault(), so click-based restart
  // would never fire — we must handle it here).
  if (state === 'title' || state === 'gameOver') { restart(); return; }
  initAudio();
  const t = e.touches[0];
  const rect = canvas.getBoundingClientRect();
  const y = (t.clientY - rect.top) / (rect.bottom - rect.top) * canvas.height;
  if (y < canvas.height * 0.6) jumpPressed = true;
  else duckPressed = true;
});
canvas.addEventListener('touchend', e => {
  e.preventDefault();
  jumpPressed = false;
  duckPressed = false;
});

// === AUDIO ===
let audioCtx = null;
function initAudio() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); }
function playTone(freq, dur, type='square', vol=0.08) {
  if (!audioCtx) return;
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.type = type; osc.frequency.value = freq;
  gain.gain.setValueAtTime(vol, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + dur);
  osc.connect(gain); gain.connect(audioCtx.destination);
  osc.start(); osc.stop(audioCtx.currentTime + dur);
}
function sfxJump() { playTone(350, 0.1, 'triangle'); playTone(550, 0.08, 'triangle'); }
function sfxCoin() { playTone(1320, 0.06, 'square'); playTone(1660, 0.05, 'square'); }
function sfxHit() { playTone(80, 0.25, 'sawtooth', 0.15); }
function sfxMilestone() { playTone(660, 0.08); playTone(880, 0.08); playTone(1100, 0.12); }

// === SPAWNING ===
function spawnObstacle() {
  const types = ['spike', 'barrier', 'double_spike'];
  const type = types[Math.floor(Math.random() * types.length)];
  const gy = groundY();
  let obs;
  switch(type) {
    case 'spike':
      obs = { x: canvas.width + 20, y: gy - 30, width: 25, height: 30, type: 'spike' };
      break;
    case 'barrier':
      obs = { x: canvas.width + 20, y: gy - 50, width: 20, height: 50, type: 'barrier' };
      break;
    case 'double_spike':
      obs = [
        { x: canvas.width + 20, y: gy - 30, width: 25, height: 30, type: 'spike' },
        { x: canvas.width + 55, y: gy - 30, width: 25, height: 30, type: 'spike' },
      ];
      break;
  }
  if (Array.isArray(obs)) obstacles.push(...obs);
  else obstacles.push(obs);
}

function spawnCoin() {
  const gy = groundY();
  const patterns = [
    [{ x: canvas.width + 30, y: gy - 80, width: 20, height: 20 }],
    [{ x: canvas.width + 30, y: gy - 60, width: 20, height: 20 },
     { x: canvas.width + 55, y: gy - 60, width: 20, height: 20 },
     { x: canvas.width + 80, y: gy - 60, width: 20, height: 20 }],
    [{ x: canvas.width + 30, y: gy - 120, width: 20, height: 20 }], // high coin — risk/reward
  ];
  const pattern = patterns[Math.floor(Math.random() * patterns.length)];
  coins.push(...pattern);
}

// === UPDATE ===
let lastMilestone = 0;
function update() {
  if (state !== 'playing') return;

  // Scroll speed ramp
  scrollSpeed += SPEED_INCREMENT;
  distance += scrollSpeed * 0.1;

  // Milestone check
  const currentMilestone = Math.floor(distance / 500);
  if (currentMilestone > lastMilestone) {
    lastMilestone = currentMilestone;
    sfxMilestone();
  }

  // Player physics
  player.vy += GRAVITY;
  player.y += player.vy;
  const gy = groundY();

  // Ducking
  if (duckPressed && player.grounded) {
    player.ducking = true;
    player.height = 25;
    player.y = gy - 25;
  } else {
    player.ducking = false;
    player.height = 40;
  }

  // Ground collision
  if (player.y + player.height >= gy) {
    player.y = gy - player.height;
    player.vy = 0;
    player.grounded = true;
  }

  // Jump
  if (jumpPressed && player.grounded) {
    player.vy = -JUMP_FORCE;
    player.grounded = false;
    sfxJump();
  }

  // Move obstacles and coins left
  for (const o of obstacles) o.x -= scrollSpeed;
  for (const c of coins) c.x -= scrollSpeed;

  // Remove off-screen
  obstacles = obstacles.filter(o => o.x > -60);
  coins = coins.filter(c => c.x > -30);

  // Collision with obstacles
  if (!player.invincible) {
    for (const o of obstacles) {
      if (rectCollide(
        {x: player.x + 4, y: player.y + 4, width: player.width - 8, height: player.height - 8},
        {x: o.x + 3, y: o.y + 3, width: o.width - 6, height: o.height - 6}
      )) {
        playerHP--;
        player.invincible = true;
        player.invincibleTimer = 90;
        sfxHit();
        spawnParticles(player.x + player.width/2, player.y + player.height/2, '#ff4444', 8);
        if (playerHP <= 0) {
          state = 'gameOver';
          return;
        }
        state = 'hit_flash';
        setTimeout(() => { if (state === 'hit_flash') state = 'playing'; }, 300);
        break;
      }
    }
  }
  if (player.invincible && --player.invincibleTimer <= 0) player.invincible = false;

  // Coin collection
  coins = coins.filter(c => {
    if (rectCollide(
      {x: player.x, y: player.y, width: player.width, height: player.height},
      c
    )) {
      score += 10;
      sfxCoin();
      spawnParticles(c.x + 10, c.y + 10, '#ffd700', 5);
      return false;
    }
    c.spinAngle = (c.spinAngle || 0) + 0.1;
    return true;
  });

  // Spawn timer
  obstacleTimer--;
  if (obstacleTimer <= 0) {
    spawnObstacle();
    obstacleTimer = Math.max(40, OBSTACLE_INTERVAL - scrollSpeed * 3 + Math.random() * 30);
  }
  coinTimer--;
  if (coinTimer <= 0) {
    spawnCoin();
    coinTimer = 50 + Math.random() * 60;
  }

  // Particles
  for (const p of particles) { p.x += p.vx - scrollSpeed * 0.3; p.y += p.vy; p.life--; }
  particles = particles.filter(p => p.life > 0);

  // Parallax
  bgLayers[0] = (bgLayers[0] + scrollSpeed * 0.1) % canvas.width;
  bgLayers[1] = (bgLayers[1] + scrollSpeed * 0.3) % canvas.width;
  bgLayers[2] = (bgLayers[2] + scrollSpeed * 0.7) % canvas.width;
}

// === DRAW ===
function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawGround();
  for (const c of coins) drawCoin(c);
  for (const o of obstacles) drawObstacle(o);
  drawPlayer();
  for (const p of particles) drawParticle(p);
  drawUI();
  if (state === 'title') drawOverlay('RUNNER', 'Tap or press any key to start\n↑/top-half = Jump  ↓/bottom-half = Duck');
  if (state === 'gameOver') drawOverlay('GAME OVER', 'Distance: ' + Math.floor(distance) + 'm — Tap to retry');
  if (state === 'hit_flash') { ctx.fillStyle = 'rgba(255,0,0,0.2)'; ctx.fillRect(0,0,canvas.width,canvas.height); }
}

function drawBackground() { /* parallax sky, mountains, trees using bgLayers offsets */ }
function drawGround() { /* scrolling ground tiles */ }
function drawPlayer() {
  ctx.fillStyle = player.invincible && Math.floor(Date.now()/100)%2 ? '#fff' : '#ff6600';
  const h = player.ducking ? player.height : player.height;
  ctx.fillRect(player.x, player.y, player.width, h);
}
function drawObstacle(o) {
  ctx.fillStyle = o.type === 'barrier' ? '#8B4513' : '#ff3333';
  ctx.fillRect(o.x, o.y, o.width, o.height);
}
function drawCoin(c) {
  const a = c.spinAngle || 0;
  const scaleX = Math.abs(Math.cos(a));
  ctx.fillStyle = '#ffd700';
  ctx.beginPath();
  ctx.ellipse(c.x + 10, c.y + 10, 10 * scaleX, 10, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#ffec80';
  ctx.beginPath();
  ctx.ellipse(c.x + 10, c.y + 10, 5 * scaleX, 5, 0, 0, Math.PI * 2);
  ctx.fill();
}
function drawParticle(p) { ctx.fillStyle = p.color; ctx.globalAlpha = p.life / 25; ctx.fillRect(p.x, p.y, 3, 3); ctx.globalAlpha = 1; }
function drawUI() {
  ctx.fillStyle = '#fff';
  ctx.font = 'bold 18px sans-serif';
  ctx.textAlign = 'left';
  ctx.fillText(Math.floor(distance) + 'm', 12, 30);
  ctx.textAlign = 'right';
  ctx.fillText('Score: ' + score, canvas.width - 12, 30);
}
function drawOverlay(title, subtitle) {
  ctx.fillStyle = 'rgba(0,0,0,0.6)';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#fff';
  ctx.font = 'bold 32px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(title, canvas.width/2, canvas.height/2 - 20);
  ctx.font = '14px sans-serif';
  const lines = subtitle.split('\n');
  lines.forEach((l, i) => ctx.fillText(l, canvas.width/2, canvas.height/2 + 20 + i * 22));
}

function rectCollide(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x &&
         a.y < b.y + b.height && a.y + a.height > b.y;
}

// === PARTICLE SYSTEM ===
function spawnParticles(x, y, color, count) {
  for (let i = 0; i < count; i++) particles.push({
    x, y, vx: (Math.random()-0.5)*5, vy: (Math.random()-0.5)*5 - 3,
    life: 15 + Math.random()*15, color
  });
}

// === GAME LOOP ===
function gameLoop() {
  update();
  draw();
  requestAnimationFrame(gameLoop);
}

// === RESTART ===
function restart() {
  initAudio();
  score = 0; distance = 0; scrollSpeed = {{SCROLL_SPEED}};
  playerHP = 1; lastMilestone = 0;
  player.y = groundY() - player.height;
  player.vy = 0; player.grounded = true;
  player.invincible = false; player.invincibleTimer = 0;
  obstacles = []; coins = []; particles = [];
  obstacleTimer = 1; coinTimer = 30;
  state = 'playing';
}
canvas.addEventListener('click', () => {
  if (state === 'title' || state === 'gameOver') restart();
});
document.addEventListener('keydown', e => {
  // Any key press restarts from title/gameOver — no exclusion list needed
  // since the playing-state guard already prevents mid-game interference.
  if (state === 'title' || state === 'gameOver') { restart(); e.preventDefault(); }
});

gameLoop();
</script>
</body>
</html>''';

  @override
  List<String> get requiredCodeElements => const [
        'scrollSpeed',
        'SPEED_INCREMENT',
        'obstacles',
        'coins',
        'groundY',
        'jumpPressed',
        'distance',
        'requestAnimationFrame',
        'sfxJump',
        'sfxCoin',
      ];

  @override
  Map<String, double> get defaultPhysics => const {
        'gravity': 0.7,
        'friction': 0.0,
        'jumpForce': 14.0,
        'moveSpeed': 0.0,
      };

  @override
  List<String> getCodeGenConstraints(GameDesignDocument doc) {
    final constraints = <String>[
      'This is an ENDLESS RUNNER — the world auto-scrolls left. The player cannot stop or move backward.',
      'The player can JUMP (tap top half / ArrowUp / Space) and DUCK (tap bottom half / ArrowDown).',
      'Gravity pulls the player down; jumping is the primary avoidance mechanic.',
      'Obstacles: spikes (low, jump over), barriers (tall, duck under or jump), double spikes (wider gap).',
      'Scroll speed increases gradually over time (speed += 0.002 per frame), making the game harder.',
      'Coins placed in patterns: flat row (safe), arc (tempting but risky near obstacles), high single (risk/reward).',
      'Distance tracking in meters; milestones every 500m with a celebratory jingle.',
      'Parallax scrolling background: 3 layers (far mountains 0.1x, mid trees 0.3x, near ground 0.7x).',
      'Include Web Audio API: jump whoosh, coin ding, hit crash, milestone jingle.',
      'One-hit death with invincibility flash; game over shows distance + score.',
      'Mobile: top 60% of screen = jump, bottom 40% = duck.',
    ];
    return constraints;
  }

}
