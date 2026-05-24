import '../../../features/workspace/domain/game_spec.dart';
import '../game_design_document.dart';
import '../playability/genre_validator.dart';
import '../playability/puzzle_validator.dart';
import 'game_template.dart';

class PuzzleTemplate extends GameTemplate {
  @override
  String get genreName => 'Puzzle';

  @override
  String get genreNameCN => '解谜';

  @override
  GenrePlayabilityValidator get playabilityValidator =>
      PuzzlePlayabilityValidator();

  @override
  String buildDesignPrompt(GameSpec spec) {
    final genreNote = spec.genre != null
        ? '(USER SPECIFIED — must follow this)'
        : '[Not specified — be creative, example: match-3, sliding puzzle, or grid-based logic]';

    return '''You are designing a 2D puzzle game. Output a structured JSON design document.

## Genre: Puzzle $genreNote
- Theme: ${spec.theme ?? '[Not specified]'}
- Art Style: ${spec.artStyle ?? '[Not specified]'}
- Core Mechanic: ${spec.coreMechanic ?? '[Not specified]'}
- Player Ability: ${spec.playerAbility ?? '[Not specified]'}
- Goal: ${spec.goal ?? '[Not specified]'}
- Difficulty: ${spec.difficulty ?? 'Medium'}

## Puzzle Design Rules
- The player interacts with a **grid** or **set of elements** to solve logic challenges.
- Common patterns: match-3 (swap adjacent tiles), sliding puzzle (rearrange tiles), connection (link matching colors), memory (flip and match pairs), or Sokoban-style (push blocks to targets).
- Design **3-5 levels/puzzles** with increasing complexity.
- No real-time pressure (no enemies chasing the player) — focus on logic and pattern recognition.
- Physics: no gravity, no jumping — pure interaction via click/tap/drag.
- The core loop: observe the puzzle state → plan a move → execute by tapping/swapping → watch the cascade/feedback → repeat until solved.

## Required Output JSON Structure
{
  "title": "...",
  "genre": "Puzzle",
  "coreLoop": "30-second puzzle loop description",
  "objects": [
    {"name":"tile","type":"grid_element","properties":{"width":60,"height":60,"colors":6},"behaviors":["swappable","match_detect","cascade_fall"],"visual":"colored gems with subtle glow"},
    {"name":"grid","type":"board","properties":{"rows":8,"cols":8,"cellSize":64},"behaviors":["contains_tiles","detect_matches","refill"],"visual":"subtle grid lines on dark background"},
    {"name":"cursor","type":"selector","properties":{"width":64,"height":64},"behaviors":["highlight_selected","animate_swap"],"visual":"pulsing border highlight"}
  ],
  "physics": {"gravity":0,"friction":0,"jumpForce":0,"moveSpeed":0},
  "collision": {"platforms":"none","enemies":"none","collectibles":"none"},
  "scoring": {"pointsPerCollectible":0,"winCondition":"clear all obstacles / match target score","loseCondition":"no more valid moves (optional)"},
  "states": {"states":["title","playing","animating","levelComplete","gameOver","win"]},
  "levels": [{"platforms":[],"enemies":[],"collectibles":[],
    "puzzleData": {"gridRows":8,"gridCols":8,"targetScore":1000,"moveLimit":30,"specialTiles":[]},
    "spawnPoint":{"x":0,"y":0}}],
  "visual": {"background":"gradient dark blue/purple","colorPalette":"vibrant jewel tones: ruby red, sapphire blue, emerald green, amber yellow, amethyst purple, diamond white","playerAppearance":"cursor/highlight indicator","effects":"match sparkles, cascade particles, combo text popup"},
  "audioHints": "select: soft click; swap: whoosh; match: ascending chime (pitch varies by combo size); invalid move: low buzz; level complete: victory fanfare"
}

Output ONLY valid JSON, no markdown or commentary.''';
  }

  @override
  String get codeSkeleton => r'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Puzzle</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#1a1a2e; display:flex; justify-content:center; align-items:center; height:100vh; overflow:hidden; }
  canvas { display:block; border-radius:8px; }
</style>
</head>
<body>
<canvas id="g"></canvas>
<script>
// === SETUP ===
const canvas = document.getElementById('g');
const ctx = canvas.getContext('2d');
const ROWS = {{ROWS}};
const COLS = {{COLS}};
const CELL = {{CELL}};
const COLORS = ['#e74c3c','#3498db','#2ecc71','#f39c12','#9b59b6','#1abc9c'];
const COLOR_NAMES = ['red','blue','green','yellow','purple','teal'];

// Layout
const gridX = 20, gridY = 80;

function resize() {
  canvas.width = Math.min(innerWidth - 16, COLS * CELL + 40);
  canvas.height = Math.min(innerHeight - 16, ROWS * CELL + 120);
}
window.addEventListener('resize', resize);
resize();

// === GAME STATE ===
let state = 'title'; // title | playing | animating | levelComplete | gameOver | win
let score = 0;
let targetScore = 1000;
let movesLeft = 30;
let currentLevel = 0;
let levels = [];

let grid = [];           // grid[row][col] = colorIndex (0-5) or -1 (empty)
let selected = null;     // {row, col} | null
let animations = [];     // active tile animations
let particles = [];

// === INPUT ===
canvas.addEventListener('touchstart', e => {
  // Safety net: restart on touch for title/gameOver/win screens (iOS
  // WKWebView may drop click events in some configurations).
  if (state === 'title' || state === 'gameOver' || state === 'win') {
    e.preventDefault();
    restart();
  }
}, {passive: false});
canvas.addEventListener('click', e => {
  initAudio();
  const rect = canvas.getBoundingClientRect();
  const mx = (e.clientX - rect.left) / (rect.right - rect.left) * canvas.width;
  const my = (e.clientY - rect.top) / (rect.bottom - rect.top) * canvas.height;
  handleClick(mx, my);
});

// === AUDIO ===
let audioCtx = null;
function initAudio() { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); }
function playTone(freq, dur, type='sine', vol=0.08) {
  if (!audioCtx) return;
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.type = type; osc.frequency.value = freq;
  gain.gain.setValueAtTime(vol, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + dur);
  osc.connect(gain); gain.connect(audioCtx.destination);
  osc.start(); osc.stop(audioCtx.currentTime + dur);
}
function sfxSelect() { playTone(440, 0.05, 'sine'); }
function sfxSwap() { playTone(330, 0.08, 'triangle'); }
function sfxMatch(combo) { playTone(523 + combo * 80, 0.1, 'sine'); }
function sfxInvalid() { playTone(120, 0.15, 'sawtooth', 0.05); }
function sfxWin() { playTone(523, 0.1); playTone(659, 0.1); playTone(784, 0.1); playTone(1047, 0.2); }

// === GRID LOGIC ===
function initGrid() {
  grid = [];
  for (let r = 0; r < ROWS; r++) {
    grid[r] = [];
    for (let c = 0; c < COLS; c++) {
      let color;
      do {
        color = Math.floor(Math.random() * COLORS.length);
      } while (wouldMatch(r, c, color));
      grid[r][c] = color;
    }
  }
}

function wouldMatch(r, c, color) {
  if (c >= 2 && grid[r][c-1] === color && grid[r][c-2] === color) return true;
  if (r >= 2 && grid[r-1] && grid[r-1][c] === color && grid[r-2] && grid[r-2][c] === color) return true;
  return false;
}

function handleClick(mx, my) {
  if (state !== 'playing') return;
  const col = Math.floor((mx - gridX) / CELL);
  const row = Math.floor((my - gridY) / CELL);
  if (row < 0 || row >= ROWS || col < 0 || col >= COLS) { selected = null; return; }

  if (selected === null) {
    selected = {row, col};
    sfxSelect();
  } else {
    const dr = Math.abs(selected.row - row);
    const dc = Math.abs(selected.col - col);
    if ((dr === 1 && dc === 0) || (dr === 0 && dc === 1)) {
      state = 'animating';
      sfxSwap();
      swapTiles(selected.row, selected.col, row, col);
      setTimeout(() => {
        const matches = findMatches();
        if (matches.length > 0) {
          movesLeft--;
          processMatches(matches);
        } else {
          // Swap back
          swapTiles(selected.row, selected.col, row, col);
          sfxInvalid();
          state = 'playing';
        }
        selected = null;
      }, 200);
    } else {
      selected = {row, col};
      sfxSelect();
    }
  }
}

function swapTiles(r1, c1, r2, c2) {
  const tmp = grid[r1][c1];
  grid[r1][c1] = grid[r2][c2];
  grid[r2][c2] = tmp;
}

function findMatches() {
  const matched = new Set();
  // Horizontal
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS - 2; c++) {
      if (grid[r][c] >= 0 && grid[r][c] === grid[r][c+1] && grid[r][c] === grid[r][c+2]) {
        matched.add(`${r},${c}`);
        matched.add(`${r},${c+1}`);
        matched.add(`${r},${c+2}`);
      }
    }
  }
  // Vertical
  for (let r = 0; r < ROWS - 2; r++) {
    for (let c = 0; c < COLS; c++) {
      if (grid[r][c] >= 0 && grid[r][c] === grid[r+1][c] && grid[r][c] === grid[r+2][c]) {
        matched.add(`${r},${c}`);
        matched.add(`${r+1},${c}`);
        matched.add(`${r+2},${c}`);
      }
    }
  }
  return [...matched].map(s => { const [r,c] = s.split(',').map(Number); return {row:r, col:c}; });
}

function processMatches(matches) {
  const combo = Math.floor(matches.length / 3);
  score += matches.length * 10 * combo;
  sfxMatch(combo);

  // Spawn particles at match positions
  matches.forEach(m => {
    const px = gridX + m.col * CELL + CELL/2;
    const py = gridY + m.row * CELL + CELL/2;
    spawnParticles(px, py, COLORS[grid[m.row][m.col]]);
  });

  // Remove matched tiles
  matches.forEach(m => { grid[m.row][m.col] = -1; });

  // Gravity — tiles fall down
  for (let c = 0; c < COLS; c++) {
    let writeRow = ROWS - 1;
    for (let r = ROWS - 1; r >= 0; r--) {
      if (grid[r][c] >= 0) {
        grid[writeRow][c] = grid[r][c];
        if (writeRow !== r) grid[r][c] = -1;
        writeRow--;
      }
    }
  }

  // Refill empty cells
  for (let c = 0; c < COLS; c++) {
    for (let r = 0; r < ROWS; r++) {
      if (grid[r][c] < 0) {
        grid[r][c] = Math.floor(Math.random() * COLORS.length);
      }
    }
  }

  // Check for chain matches
  setTimeout(() => {
    const chain = findMatches();
    if (chain.length > 0) {
      processMatches(chain);
    } else {
      checkWinLose();
      state = 'playing';
    }
  }, 300);
}

function checkWinLose() {
  if (score >= targetScore) {
    if (currentLevel < levels.length - 1) {
      state = 'levelComplete';
      setTimeout(() => { currentLevel++; loadLevel(); state = 'playing'; }, 1500);
    } else {
      state = 'win';
      sfxWin();
    }
  } else if (movesLeft <= 0) {
    state = 'gameOver';
  }
}

// === DRAW ===
function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawGrid();
  drawUI();
  if (state === 'title') drawOverlay('PUZZLE MATCH', 'Tap to start');
  if (state === 'gameOver') drawOverlay('NO MOVES LEFT', 'Score: ' + score + ' — Tap to retry');
  if (state === 'win') drawOverlay('YOU WIN!', 'Final Score: ' + score + ' — Tap to replay');
  if (state === 'levelComplete') drawOverlay('LEVEL COMPLETE!', 'Score: ' + score);
  for (const p of particles) drawParticle(p);
}

function drawGrid() {
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const x = gridX + c * CELL + 2;
      const y = gridY + r * CELL + 2;
      const color = grid[r][c] >= 0 ? COLORS[grid[r][c]] : '#222';
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.roundRect(x, y, CELL - 4, CELL - 4, 8);
      ctx.fill();
    }
  }
  // Selected highlight
  if (selected) {
    const sx = gridX + selected.col * CELL;
    const sy = gridY + selected.row * CELL;
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.roundRect(sx + 1, sy + 1, CELL - 2, CELL - 2, 8);
    ctx.stroke();
  }
}

function drawBackground() { /* gradient background */ }
function drawUI() { /* score, target, moves left */ }
function drawOverlay(title, subtitle) { /* centered overlay */ }
function drawParticle(p) { /* sparkle */ }

// === PARTICLE SYSTEM ===
function spawnParticles(x, y, color) {
  for (let i = 0; i < 4; i++) particles.push({
    x, y, vx: (Math.random()-0.5)*4, vy: (Math.random()-0.5)*4 - 2,
    life: 15 + Math.random()*10, color
  });
}

// === LEVEL SYSTEM ===
function buildLevels() {
  // PUZZLE_DATA_PLACEHOLDER — generated from design document
}

function loadLevel() {
  const lvl = levels[currentLevel];
  targetScore = lvl.targetScore;
  movesLeft = lvl.moveLimit;
  initGrid();
  selected = null;
}

// === GAME LOOP ===
function gameLoop() {
  if (state !== 'title') {
    for (const p of particles) { p.x += p.vx; p.y += p.vy; p.life--; }
    particles = particles.filter(p => p.life > 0);
  }
  draw();
  requestAnimationFrame(gameLoop);
}

// === RESTART ===
function restart() {
  initAudio();
  score = 0; currentLevel = 0;
  buildLevels(); loadLevel();
  state = 'playing';
}
canvas.addEventListener('click', e => {
  if (state === 'title' || state === 'gameOver' || state === 'win') restart();
});

buildLevels();
loadLevel();
gameLoop();
</script>
</body>
</html>''';

  @override
  List<String> get requiredCodeElements => const [
        'grid',
        'ROWS',
        'COLS',
        'findMatches',
        'swapTiles',
        'processMatches',
        'selected',
        'movesLeft',
        'requestAnimationFrame',
      ];

  @override
  Map<String, double> get defaultPhysics => const {
        'gravity': 0.0,
        'friction': 0.0,
        'jumpForce': 0.0,
        'moveSpeed': 0.0,
      };

  @override
  List<String> getCodeGenConstraints(GameDesignDocument doc) {
    final constraints = <String>[
      'This is a PUZZLE game — no physics, no enemies, no time pressure. Pure logical interaction.',
      'Implement a grid-based puzzle: match-3, sliding tiles, memory matching, or Sokoban-style.',
      'Click/tap to select and interact with grid elements. Support swapping adjacent tiles.',
      'Detect matches (3+ in a row/column), remove matched tiles, apply gravity + refill.',
      'Score based on match size: basic match = 30pts, 4-tile = 60pts, 5-tile = 100pts, chain bonus ×2.',
      'Move limit per level (20-40 moves). Target score increases per level.',
      '3-5 levels with increasing target scores and fewer starting matches on the board.',
      'Include Web Audio API: select click, swap whoosh, match chime (pitch by combo), invalid buzz, win fanfare.',
      'Visual: rounded-rect gems with jewel-tone colors (red, blue, green, yellow, purple, teal) on dark background.',
      'Particle effects on match: sparkles in the matched tile color.',
    ];
    return constraints;
  }

}
