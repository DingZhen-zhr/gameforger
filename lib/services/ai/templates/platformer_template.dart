import '../../../features/workspace/domain/game_spec.dart';
import '../game_design_document.dart';
import '../playability/genre_validator.dart';
import '../playability/platformer_validator.dart';
import 'game_template.dart';

class PlatformerTemplate extends GameTemplate {
  @override
  String get genreName => 'Platformer';

  @override
  String get genreNameCN => '平台跳跃';

  @override
  GenrePlayabilityValidator get playabilityValidator =>
      PlatformerPlayabilityValidator();

  @override
  String buildDesignPrompt(GameSpec spec) {
    final genreNote = spec.genre != null
        ? '(USER SPECIFIED — must follow this)'
        : '[Not specified — be creative, example: precision platformer like Celeste]';

    return '''You are designing a 2D platformer game. Output a structured JSON design document.

## Genre: Platformer $genreNote
- Theme: ${spec.theme ?? '[Not specified]'}
- Art Style: ${spec.artStyle ?? '[Not specified]'}
- Core Mechanic: ${spec.coreMechanic ?? '[Not specified]'}
- Player Ability: ${spec.playerAbility ?? '[Not specified]'}
- Goal: ${spec.goal ?? '[Not specified]'}
- Difficulty: ${spec.difficulty ?? 'Medium'}

## Platformer Design Rules
- The player must navigate platforms using **gravity**, **jumping**, and **horizontal movement**.
- Design **3 levels** with increasing difficulty: introduction → challenge → mastery.
- Each level has **4-7 platforms** at varying heights, **2-4 enemies** (patrol or static), and **3-6 collectibles**.
- Physics: gravity pulls the player down, platforms are solid from the top only (one-way).
- The core loop: jump between platforms, avoid enemies, collect items → reach goal.

## Required Output JSON Structure
{
  "title": "...",
  "genre": "Platformer",
  "coreLoop": "30-second gameplay loop description",
  "objects": [
    {"name":"player","type":"player","properties":{"width":30,"height":40,"moveSpeed":4,"jumpForce":12},"behaviors":["move","jump","collect","damage"],"visual":"..."},
    {"name":"platform","type":"platform","properties":{"width":120,"height":20},"behaviors":["solid_top"],"visual":"..."},
    {"name":"enemy_patrol","type":"enemy","properties":{"width":30,"height":30,"patrolRange":80,"speed":1.5},"behaviors":["patrol","damage_player"],"visual":"..."},
    {"name":"collectible_gem","type":"collectible","properties":{"width":20,"height":20,"points":10},"behaviors":["collectible","bob_animate"],"visual":"..."}
  ],
  "physics": {"gravity":0.6,"friction":0.85,"jumpForce":12,"moveSpeed":4},
  "collision": {"platforms":"solid top (one-way)","enemies":"damage player on contact","collectibles":"collect and destroy on contact"},
  "scoring": {"pointsPerCollectible":10,"winCondition":"collect all gems in all levels","loseCondition":"fall off screen or enemy contact"},
  "states": {"states":["title","playing","levelTransition","gameOver","win"]},
  "levels": [{"platforms":[...],"enemies":[...],"collectibles":[...],"spawnPoint":{"x":50,"y":300}}],
  "visual": {"background":"gradient sky with parallax layers","colorPalette":"vibrant greens, blues, warm golds","playerAppearance":"...","effects":"particles on collect, screen shake on damage, double jump trail"},
  "audioHints": "jump sfx: short rising tone; collect: bright chime; damage: low thud; win: ascending arpeggio"
}

Output ONLY valid JSON, no markdown or commentary.''';
  }

  @override
  String get codeSkeleton => r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Platformer</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#111; display:flex; justify-content:center; align-items:center; height:100vh; overflow:hidden; }
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
const FRICTION = {{FRICTION}};
const JUMP_FORCE = {{JUMP_FORCE}};
const MOVE_SPEED = {{MOVE_SPEED}};

function resize() {
  canvas.width = Math.min(innerWidth - 16, 420);
  canvas.height = Math.min(innerHeight - 16, 640);
}
window.addEventListener('resize', resize);
resize();

// === GAME STATE ===
let state = 'title'; // title | playing | levelTransition | gameOver | win
let score = 0;
let currentLevel = 0;
let levels = [];

// === PLAYER ===
const player = {
  x: 50, y: 300, width: 30, height: 40,
  vx: 0, vy: 0, grounded: false, facingRight: true,
  invincible: false, invincibleTimer: 0
};

// === GAME OBJECTS ===
let platforms = [];
let enemies = [];
let collectibles = [];
let particles = [];

// === INPUT ===
const keys = {};
document.addEventListener('keydown', e => { keys[e.key] = true; e.preventDefault(); });
document.addEventListener('keyup', e => { keys[e.key] = false; });

canvas.addEventListener('touchstart', e => {
  e.preventDefault();
  // Start/restart game on title, gameOver, or win screen (iOS WKWebView
  // blocks click events after touchstart.preventDefault(), so click-based
  // restart would never fire — we must handle it here).
  if (state === 'title' || state === 'gameOver' || state === 'win') { restart(); return; }
  const t = e.touches[0];
  const rect = canvas.getBoundingClientRect();
  const x = (t.clientX - rect.left) / (rect.right - rect.left) * canvas.width;
  if (x < canvas.width / 3) keys['ArrowLeft'] = true;
  else if (x < canvas.width * 2/3) keys['ArrowUp'] = true;
  else keys['ArrowRight'] = true;
});
canvas.addEventListener('touchend', e => {
  e.preventDefault();
  keys['ArrowLeft'] = false;
  keys['ArrowUp'] = false;
  keys['ArrowRight'] = false;
});

// === AUDIO ===
let audioCtx = null;
function initAudio() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); }
function playTone(freq, dur, type='square', vol=0.1) {
  if (!audioCtx) return;
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.type = type; osc.frequency.value = freq;
  gain.gain.setValueAtTime(vol, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + dur);
  osc.connect(gain); gain.connect(audioCtx.destination);
  osc.start(); osc.stop(audioCtx.currentTime + dur);
}
function sfxJump() { playTone(400, 0.1, 'square'); playTone(600, 0.08, 'square'); }
function sfxCollect() { playTone(880, 0.08, 'square'); playTone(1320, 0.06, 'square'); }
function sfxHurt() { playTone(150, 0.2, 'sawtooth', 0.15); }
function sfxWin() { playTone(523, 0.12, 'square'); playTone(659, 0.1, 'square'); playTone(784, 0.15, 'square'); }

// === LEVEL INIT ===
function buildLevels() {
  // LEVELS_DATA_PLACEHOLDER — generated from design document
}

// === UPDATE ===
function update() {
  if (state !== 'playing') return;

  // Player input
  if (keys['ArrowLeft']) { player.vx = -MOVE_SPEED; player.facingRight = false; }
  else if (keys['ArrowRight']) { player.vx = MOVE_SPEED; player.facingRight = true; }
  else player.vx *= FRICTION;

  if ((keys['ArrowUp'] || keys[' ']) && player.grounded) {
    player.vy = -JUMP_FORCE;
    player.grounded = false;
    sfxJump();
  }

  // Gravity
  player.vy += GRAVITY;
  player.y += player.vy;
  player.x += player.vx;

  // Platform collision — one-way (solid top)
  player.grounded = false;
  for (const p of platforms) {
    if (player.vx + player.x < p.x + p.w && player.x + player.width > p.x) {
      // Landing on top
      if (player.vy >= 0 &&
          player.y + player.height >= p.y &&
          player.y + player.height - player.vy <= p.y) {
        player.y = p.y - player.height;
        player.vy = 0;
        player.grounded = true;
      }
    }
  }

  // Fall off screen
  if (player.y > canvas.height + 50) { state = 'gameOver'; sfxHurt(); return; }
  // Clamp horizontal
  player.x = Math.max(0, Math.min(player.x, canvas.width - player.width));

  // Enemy update
  for (const e of enemies) {
    if (e.behavior === 'patrol') {
      e.x += e.speed;
      if (e.x <= e.patrolMin || e.x >= e.patrolMax) e.speed *= -1;
    }
    // Enemy collision
    if (!player.invincible &&
        player.x < e.x + e.w && player.x + player.width > e.x &&
        player.y < e.y + e.h && player.y + player.height > e.y) {
      player.invincible = true;
      player.invincibleTimer = 60;
      player.vy = -8;
      sfxHurt();
    }
  }
  if (player.invincible && --player.invincibleTimer <= 0) player.invincible = false;

  // Collectible update
  collectibles = collectibles.filter(c => {
    if (player.x < c.x + c.w && player.x + player.width > c.x &&
        player.y < c.y + c.h && player.y + player.height > c.y) {
      score += c.points;
      sfxCollect();
      spawnParticles(c.x + c.w/2, c.y + c.h/2, c.color);
      return false;
    }
    c.bobT = (c.bobT || 0) + 0.05;
    return true;
  });

  // Check win — all collectibles in current level gathered
  if (collectibles.length === 0) {
    if (currentLevel < levels.length - 1) { currentLevel++; loadLevel(currentLevel); }
    else { state = 'win'; sfxWin(); }
  }

  // Particles
  for (const p of particles) { p.x += p.vx; p.y += p.vy; p.life--; }
  particles = particles.filter(p => p.life > 0);
}

// === DRAW ===
function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // Background
  drawBackground();
  // Platforms
  for (const p of platforms) drawPlatform(p);
  // Enemies
  for (const e of enemies) drawEnemy(e);
  // Collectibles
  for (const c of collectibles) drawCollectible(c);
  // Player
  drawPlayer();
  // Particles
  for (const p of particles) drawParticle(p);
  // UI
  drawUI();
  // Overlays
  if (state === 'title') drawOverlay('GAME TITLE', 'Tap or press any key to start');
  if (state === 'gameOver') drawOverlay('GAME OVER', 'Score: ' + score + ' — Tap to retry');
  if (state === 'win') drawOverlay('YOU WIN!', 'Score: ' + score + ' — Tap to play again');
}

// Drawing helpers
function drawBackground() { /* gradient + parallax */ }
function drawPlatform(p) { /* colored rect */ }
function drawEnemy(e) { /* colored shape */ }
function drawCollectible(c) { /* animated gem */ }
function drawPlayer() { /* character with facing direction */ }
function drawParticle(p) { /* fading dot */ }
function drawUI() { /* score display */ }
function drawOverlay(title, subtitle) { /* centered text overlay */ }

// === GAME LOOP ===
function gameLoop() {
  update();
  draw();
  requestAnimationFrame(gameLoop);
}

// === RESTART ===
function restart() {
  initAudio();
  score = 0; currentLevel = 0;
  buildLevels(); loadLevel(0);
  state = 'playing';
}
canvas.addEventListener('click', () => {
  if (state === 'title' || state === 'gameOver' || state === 'win') restart();
});
document.addEventListener('keydown', e => {
  if ((state === 'title' || state === 'gameOver' || state === 'win') && e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') restart();
});

function loadLevel(i) {
  const lvl = levels[i];
  platforms = lvl.platforms;
  enemies = lvl.enemies;
  collectibles = lvl.collectibles.map(c => ({...c, bobT: 0}));
  player.x = lvl.spawnX; player.y = lvl.spawnY;
  player.vx = 0; player.vy = 0;
}

function spawnParticles(x, y, color) {
  for (let i = 0; i < 6; i++) particles.push({
    x, y, vx: (Math.random()-0.5)*3, vy: (Math.random()-0.5)*3 - 2,
    life: 20 + Math.random()*10, color
  });
}

// Kick off
buildLevels();
loadLevel(0);
gameLoop();
</script>
</body>
</html>''';

  @override
  List<String> get requiredCodeElements => const [
        'GRAVITY',
        'player.vy',
        'player.grounded',
        'jump',
        'platforms',
        'collectibles',
        'requestAnimationFrame',
        'sfxJump',
        'sfxCollect',
      ];

  @override
  Map<String, double> get defaultPhysics => const {
        'gravity': 0.6,
        'friction': 0.85,
        'jumpForce': 12.0,
        'moveSpeed': 4.0,
      };

  @override
  List<String> getCodeGenConstraints(GameDesignDocument doc) {
    final physics = doc.physics;
    final gravity = physics.gravity;
    final jumpForce = physics.jumpForce;
    final moveSpeed = physics.moveSpeed;

    // Calculate reachability limits
    final maxJumpHeight = (jumpForce * jumpForce) / (2 * gravity);
    final airTime = 2 * jumpForce / gravity;
    final maxJumpDistance = moveSpeed * airTime;

    final constraints = <String>[
      'This is a PLATFORMER — gravity pulls the player down, platforms are one-way solid from the top.',
      'The player must be able to jump (vy = -JUMP_FORCE) only when grounded (player.grounded == true).',
      '',
      '╔══════════════════════════════════════════════════════════════╗',
      '║  CRITICAL: PHYSICS GEOMETRY — HARD MATHEMATICAL LIMITS      ║',
      '╠══════════════════════════════════════════════════════════════╣',
      '${'║  GRAVITY    = $gravity (pixels per frame²)'.padRight(61)}║',
      '${'║  JUMP_FORCE = $jumpForce (initial upward velocity)'.padRight(61)}║',
      '${'║  MOVE_SPEED = $moveSpeed (horizontal pixels per frame)'.padRight(61)}║',
      '║                                                            ║',
      '${'║  MAX JUMP HEIGHT   = ${maxJumpHeight.toInt()} pixels (vertical)'.padRight(61)}║',
      '${'║  MAX JUMP DISTANCE = ${maxJumpDistance.toInt()} pixels (horizontal)'.padRight(61)}║',
      '║                                                            ║',
      '║  HARD CONSTRAINT: Every consecutive platform pair (A→B)    ║',
      '║  MUST satisfy BOTH:                                        ║',
      '${'║    (a.y - b.y) ≤ ${maxJumpHeight.toInt()}px  (vertical gap)'.padRight(61)}║',
      '${'║    (b.x - a.right) ≤ ${maxJumpDistance.toInt()}px  (horizontal gap)'.padRight(61)}║',
      '║                                                            ║',
      '║  VIOLATING THESE LIMITS = LITERALLY UNPLAYABLE GAME.       ║',
      '║  Before writing code, mentally verify EVERY platform pair.  ║',
      '╚══════════════════════════════════════════════════════════════╝',
      '',
      'Platforms must be at varying heights WITHIN the above limits.',
      'Enemies patrol horizontally between min/max bounds; touching them damages the player.',
      'Collectibles bob up and down (sine wave animation) and give points on contact.',
      'Include Web Audio API sound effects: jump tone, collect chime, hurt thud, win arpeggio.',
      'Three distinct levels with increasing difficulty (wider gaps within limits, faster enemies, more platforms).',
      'Mobile touch: left third = left, middle third = jump, right third = right.',
      'The game must detect win (all collectibles in all levels) and game over (fall or enemy hit).',
      'When defining platform positions, add a comment after each platform: // reachable: Δy=Xpx Δx=Ypx (max ${maxJumpHeight.toInt()}/${maxJumpDistance.toInt()})',
    ];
    return constraints;
  }

}
