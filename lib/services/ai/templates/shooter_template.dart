import '../../../features/workspace/domain/game_spec.dart';
import '../game_design_document.dart';
import '../playability/genre_validator.dart';
import '../playability/shooter_validator.dart';
import 'game_template.dart';

class ShooterTemplate extends GameTemplate {
  @override
  String get genreName => 'Shooter';

  @override
  String get genreNameCN => '射击';

  @override
  GenrePlayabilityValidator get playabilityValidator =>
      ShooterPlayabilityValidator();

  @override
  String buildDesignPrompt(GameSpec spec) {
    final genreNote = spec.genre != null
        ? '(USER SPECIFIED — must follow this)'
        : '[Not specified — be creative, example: top-down bullet hell like Enter the Gungeon]';

    return '''You are designing a 2D shooter game. Output a structured JSON design document.

## Genre: Shooter $genreNote
- Theme: ${spec.theme ?? '[Not specified]'}
- Art Style: ${spec.artStyle ?? '[Not specified]'}
- Core Mechanic: ${spec.coreMechanic ?? '[Not specified]'}
- Player Ability: ${spec.playerAbility ?? '[Not specified]'}
- Goal: ${spec.goal ?? '[Not specified]'}
- Difficulty: ${spec.difficulty ?? 'Medium'}

## Shooter Design Rules
- The player controls a character that **shoots projectiles** at enemies.
- Camera can be top-down (player moves freely) or side-scrolling (player at left, enemies from right).
- Design **3 waves/levels** with increasing enemy count, speed, and HP.
- Enemy types: basic (straight movement), fast (zigzag), tank (more HP).
- **Power-ups** drop from defeated enemies: rapid fire, spread shot, shield.
- Physics: no gravity (or minimal), focus on projectile speed and enemy movement patterns.
- The core loop: dodge enemy projectiles, aim and shoot enemies, collect power-ups → survive waves.

## Required Output JSON Structure
{
  "title": "...",
  "genre": "Shooter",
  "coreLoop": "30-second gameplay loop description",
  "objects": [
    {"name":"player","type":"player","properties":{"width":32,"height":32,"moveSpeed":5,"fireRate":15},"behaviors":["move_8dir","shoot","take_damage"],"visual":"..."},
    {"name":"bullet_player","type":"projectile","properties":{"width":6,"height":12,"speed":8,"damage":10},"behaviors":["linear_move","destroy_off_screen"],"visual":"..."},
    {"name":"enemy_basic","type":"enemy","properties":{"width":30,"height":30,"hp":20,"speed":2,"score":50},"behaviors":["move_down","shoot_at_player"],"visual":"..."},
    {"name":"powerup_spread","type":"powerup","properties":{"width":24,"height":24,"duration":300},"behaviors":["fall_down","collectible"],"visual":"..."}
  ],
  "physics": {"gravity":0,"friction":0.9,"jumpForce":0,"moveSpeed":5},
  "collision": {"platforms":"none — free movement","enemies":"damage player on contact","collectibles":"collect powerup on contact"},
  "scoring": {"pointsPerCollectible":0,"winCondition":"survive all waves","loseCondition":"player HP reaches 0"},
  "states": {"states":["title","playing","waveTransition","gameOver","win"]},
  "levels": [{"platforms":[],"enemies":[...],"collectibles":[...],"spawnPoint":{"x":200,"y":500}}],
  "visual": {"background":"scrolling starfield / grid","colorPalette":"neon on dark background, explosions in orange/red","playerAppearance":"...","effects":"muzzle flash, explosion particles, screen shake on hit"},
  "audioHints": "shoot: short white noise burst; explosion: low rumble; powerup: rising synth; wave clear: triumphant fanfare"
}

Output ONLY valid JSON, no markdown or commentary.''';
  }

  @override
  String get codeSkeleton => r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Shooter</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#000; display:flex; justify-content:center; align-items:center; height:100vh; overflow:hidden; }
  canvas { display:block; }
</style>
</head>
<body>
<canvas id="g"></canvas>
<script>
// === SETUP ===
const canvas = document.getElementById('g');
const ctx = canvas.getContext('2d');
const MOVE_SPEED = {{MOVE_SPEED}};
const FIRE_RATE = {{FIRE_RATE}};

function resize() {
  canvas.width = Math.min(innerWidth - 16, 420);
  canvas.height = Math.min(innerHeight - 16, 640);
}
window.addEventListener('resize', resize);
resize();

// === GAME STATE ===
let state = 'title'; // title | playing | waveTransition | gameOver | win
let score = 0;
let currentWave = 0;
let waveTimer = 0;
const totalWaves = 3;

// === PLAYER ===
const player = {
  x: 200, y: 500, width: 32, height: 32,
  hp: 3, maxHp: 3,
  fireCooldown: 0, powerup: null, powerupTimer: 0,
  invincible: false, invincibleTimer: 0
};

// === GAME OBJECTS ===
let bullets = [];       // player bullets
let enemyBullets = [];  // enemy bullets
let enemies = [];
let powerups = [];
let particles = [];

// === INPUT (touch drag for movement, auto-fire) ===
let touchActive = false;
let touchX = 0, touchY = 0;
let moveX = 0, moveY = 0;

canvas.addEventListener('touchstart', e => {
  e.preventDefault();
  // Start/restart game on title, gameOver, or win (iOS WKWebView blocks
  // click events after touchstart.preventDefault() — handle it here).
  if (state === 'title' || state === 'gameOver' || state === 'win') { restart(); return; }
  initAudio();
  const t = e.touches[0];
  const rect = canvas.getBoundingClientRect();
  touchX = (t.clientX - rect.left) / (rect.right - rect.left) * canvas.width;
  touchY = (t.clientY - rect.top) / (rect.bottom - rect.top) * canvas.height;
  touchActive = true;
});
canvas.addEventListener('touchmove', e => {
  e.preventDefault();
  const t = e.touches[0];
  const rect = canvas.getBoundingClientRect();
  touchX = (t.clientX - rect.left) / (rect.right - rect.left) * canvas.width;
  touchY = (t.clientY - rect.top) / (rect.bottom - rect.top) * canvas.height;
});
canvas.addEventListener('touchend', e => { e.preventDefault(); touchActive = false; moveX = 0; moveY = 0; });

// Keyboard
const keys = {};
document.addEventListener('keydown', e => { keys[e.key] = true; });
document.addEventListener('keyup', e => { keys[e.key] = false; });

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
function sfxShoot() { playTone(800, 0.05, 'square', 0.05); }
function sfxExplosion() { playTone(60, 0.15, 'sawtooth', 0.12); }
function sfxPowerup() { playTone(600, 0.06, 'square'); playTone(900, 0.06, 'square'); playTone(1200, 0.08, 'square'); }
function sfxHit() { playTone(200, 0.1, 'triangle', 0.1); }
function sfxWaveClear() { playTone(523, 0.1, 'square'); playTone(659, 0.1, 'square'); playTone(784, 0.15, 'square'); }

// === WAVE SYSTEM ===
function buildWaves() {
  // WAVES_DATA_PLACEHOLDER — generated from design document
}

function spawnWave(waveIndex) {
  const wave = waves[waveIndex];
  enemies = [];
  wave.enemies.forEach(e => {
    enemies.push({
      x: e.x, y: e.y, width: 30, height: 30,
      hp: e.hp, maxHp: e.hp,
      speed: e.speed, score: e.score,
      type: e.type || 'basic',
      shootTimer: 0, shootInterval: e.shootInterval || 120,
      movePattern: e.movePattern || 'down',
      moveTimer: 0
    });
  });
}

// === UPDATE ===
function update() {
  if (state !== 'playing') return;

  // Player movement
  if (touchActive) {
    const dx = touchX - player.x;
    const dy = touchY - player.y;
    const dist = Math.sqrt(dx*dx + dy*dy);
    if (dist > 2) { moveX = dx / dist; moveY = dy / dist; }
    else { moveX = 0; moveY = 0; }
  } else {
    moveX = 0; moveY = 0;
    if (keys['ArrowLeft'] || keys['a']) moveX = -1;
    if (keys['ArrowRight'] || keys['d']) moveX = 1;
    if (keys['ArrowUp'] || keys['w']) moveY = -1;
    if (keys['ArrowDown'] || keys['s']) moveY = 1;
  }
  player.x += moveX * MOVE_SPEED;
  player.y += moveY * MOVE_SPEED;
  player.x = Math.max(0, Math.min(player.x, canvas.width - player.width));
  player.y = Math.max(0, Math.min(player.y, canvas.height - player.height));

  // Auto-fire
  if (player.fireCooldown > 0) player.fireCooldown--;
  if (player.fireCooldown <= 0) {
    fireBullet();
    player.fireCooldown = player.powerup === 'rapid' ? FIRE_RATE / 3 : FIRE_RATE;
  }

  // Player bullets
  for (const b of bullets) { b.y -= b.speed; }
  bullets = bullets.filter(b => b.y > -10);

  // Enemies
  for (const e of enemies) {
    updateEnemyMovement(e);
    // Enemy shooting
    e.shootTimer++;
    if (e.shootTimer >= e.shootInterval) { enemyShoot(e); e.shootTimer = 0; }
  }

  // Enemy bullets
  for (const b of enemyBullets) { b.y += b.speed; }
  enemyBullets = enemyBullets.filter(b => b.y < canvas.height + 10);

  // Bullet-enemy collision
  for (const b of bullets) {
    for (const e of enemies) {
      if (rectCollide(b, e)) {
        e.hp -= b.damage || 10;
        b.hit = true;
        spawnParticles(e.x + e.width/2, e.y + e.height/2, '#ff6600', 4);
      }
    }
  }
  enemies = enemies.filter(e => {
    if (e.hp <= 0) {
      score += e.score;
      sfxExplosion();
      spawnParticles(e.x + e.width/2, e.y + e.height/2, '#ff9900', 10);
      maybeDropPowerup(e);
      return false;
    }
    return true;
  });
  bullets = bullets.filter(b => !b.hit);

  // Enemy bullet-player collision
  if (!player.invincible) {
    for (const b of enemyBullets) {
      if (rectCollide(b, player)) {
        player.hp--;
        player.invincible = true;
        player.invincibleTimer = 60;
        b.hit = true;
        sfxHit();
        if (player.hp <= 0) { state = 'gameOver'; return; }
        break;
      }
    }
    // Enemy body-player collision
    for (const e of enemies) {
      if (rectCollide(e, player)) {
        player.hp--;
        player.invincible = true;
        player.invincibleTimer = 60;
        sfxHit();
        if (player.hp <= 0) { state = 'gameOver'; return; }
        break;
      }
    }
  }
  enemyBullets = enemyBullets.filter(b => !b.hit);
  if (player.invincible && --player.invincibleTimer <= 0) player.invincible = false;

  // Powerups
  for (const p of powerups) { p.y += 1.5; }
  for (const p of powerups) {
    if (rectCollide(p, player)) {
      player.powerup = p.type;
      player.powerupTimer = p.duration;
      p.collected = true;
      sfxPowerup();
    }
  }
  powerups = powerups.filter(p => !p.collected && p.y < canvas.height + 20);
  if (player.powerup && --player.powerupTimer <= 0) player.powerup = null;

  // Wave completion check
  if (enemies.length === 0) {
    if (currentWave < totalWaves - 1) {
      state = 'waveTransition';
      waveTimer = 90;
    } else {
      state = 'win';
    }
  }

  if (state === 'waveTransition' && --waveTimer <= 0) {
    currentWave++;
    spawnWave(currentWave);
    state = 'playing';
  }

  // Particles
  for (const p of particles) { p.x += p.vx; p.y += p.vy; p.life--; }
  particles = particles.filter(p => p.life > 0);

  // Background scroll
  bgOffset = (bgOffset + 1) % 64;
}

// === DRAW ===
function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  for (const p of powerups) drawPowerup(p);
  for (const b of bullets) drawBullet(b);
  for (const b of enemyBullets) { ctx.fillStyle = '#ff4444'; ctx.fillRect(b.x-2, b.y-4, 4, 8); }
  for (const e of enemies) drawEnemy(e);
  drawPlayer();
  for (const p of particles) drawParticle(p);
  drawUI();
  if (state === 'title') drawOverlay('SHOOTER', 'Tap or press any key to start');
  if (state === 'gameOver') drawOverlay('GAME OVER', 'Score: ' + score + ' — Tap to retry');
  if (state === 'win') drawOverlay('YOU WIN!', 'Score: ' + score + ' — Tap to play again');
  if (state === 'waveTransition') drawOverlay('WAVE ' + (currentWave + 2), 'Get ready...');
}

function fireBullet() {
  const b = { x: player.x + player.width/2 - 3, y: player.y, width: 6, height: 12, speed: 8, damage: 10 };
  bullets.push(b);
  if (player.powerup === 'spread') {
    bullets.push({...b, x: b.x - 12, damage: 6});
    bullets.push({...b, x: b.x + 12, damage: 6});
  }
  sfxShoot();
}

function enemyShoot(e) {
  const b = { x: e.x + e.width/2 - 3, y: e.y + e.height, width: 6, height: 10, speed: 3.5 };
  enemyBullets.push(b);
}

function updateEnemyMovement(e) {
  e.moveTimer++;
  switch(e.movePattern) {
    case 'zigzag': e.x += Math.sin(e.moveTimer * 0.05) * 2; break;
    case 'sine': e.x += Math.sin(e.moveTimer * 0.03) * 3; break;
    default: break; // straight down
  }
  e.y += e.speed;
  if (e.y > canvas.height + 50) e.y = -40;
  e.x = Math.max(10, Math.min(e.x, canvas.width - e.width - 10));
}

function maybeDropPowerup(e) {
  if (Math.random() < 0.20) {
    const types = ['rapid', 'spread', 'shield'];
    powerups.push({
      x: e.x + e.width/2 - 12, y: e.y, width: 24, height: 24,
      type: types[Math.floor(Math.random() * types.length)],
      duration: 300
    });
  }
}

function rectCollide(a, b) {
  return a.x < b.x + b.width && a.x + a.width > b.x &&
         a.y < b.y + b.height && a.y + a.height > b.y;
}

// Drawing helpers
let bgOffset = 0;
function drawBackground() { /* scrolling grid/starfield */ }
function drawPlayer() { /* ship with invincibility flash */ }
function drawBullet(b) { ctx.fillStyle = '#ffff44'; ctx.fillRect(b.x, b.y, b.width, b.height); }
function drawEnemy(e) { /* colored shape with HP bar */ }
function drawPowerup(p) { /* glowing icon */ }
function drawParticle(p) { /* fading dot */ }
function drawUI() { /* HP hearts, score */ }
function drawOverlay(title, subtitle) { /* centered text */ }

// === GAME LOOP ===
function gameLoop() { update(); draw(); requestAnimationFrame(gameLoop); }

// === RESTART ===
function restart() {
  initAudio();
  score = 0; currentWave = 0;
  player.hp = player.maxHp; player.x = 200; player.y = 500;
  player.powerup = null; player.powerupTimer = 0;
  player.invincible = false; player.invincibleTimer = 0;
  bullets = []; enemyBullets = []; powerups = []; particles = [];
  buildWaves(); spawnWave(0);
  state = 'playing';
}
canvas.addEventListener('click', () => {
  if (state === 'title' || state === 'gameOver' || state === 'win') restart();
});
document.addEventListener('keydown', e => {
  // Any key press restarts from title/gameOver/win — no exclusion needed
  // since the playing-state guard prevents mid-game interference.
  if (state === 'title' || state === 'gameOver' || state === 'win') { restart(); e.preventDefault(); }
});

buildWaves();
spawnWave(0);
gameLoop();
</script>
</body>
</html>''';

  @override
  List<String> get requiredCodeElements => const [
        'bullets',
        'enemyBullets',
        'player.hp',
        'fireBullet',
        'enemyShoot',
        'powerup',
        'requestAnimationFrame',
        'sfxShoot',
        'sfxExplosion',
      ];

  @override
  Map<String, double> get defaultPhysics => const {
        'gravity': 0.0,
        'friction': 0.9,
        'jumpForce': 0.0,
        'moveSpeed': 5.0,
      };

  @override
  List<String> getCodeGenConstraints(GameDesignDocument doc) {
    final constraints = <String>[
      'This is a SHOOTER — player auto-fires (or fires on tap), enemies approach from top/sides.',
      'No gravity needed; player moves freely in 2D (8-directional or horizontal only).',
      'Player has HP (3-5 hearts); game over when HP reaches 0.',
      'Enemy types: basic (moves straight down), zigzag (sine-wave horizontal), tank (more HP, slower).',
      'Power-ups drop with ~20% chance from defeated enemies: rapid fire, spread shot, temporary shield.',
      'Three waves with escalating difficulty: more enemies, faster speed, more bullets.',
      'Include Web Audio API sounds: shoot blip, explosion rumble, power-up rising tone, hit thud.',
      'Mobile: touch-drag moves player (ship follows finger), auto-fires continuously.',
      'Visual style: neon bullets on dark background, explosion particles, HP bar/hearts for player.',
    ];
    return constraints;
  }

}
