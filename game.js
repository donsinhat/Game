const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

const hud = {
  hpFill: document.getElementById("hp-fill"),
  xpFill: document.getElementById("xp-fill"),
  level: document.getElementById("level"),
  time: document.getElementById("time"),
  kills: document.getElementById("kills"),
  info: document.getElementById("info"),
};

const overlay = document.getElementById("overlay");
const upgradeMenu = document.getElementById("upgrade-menu");
const upgradeList = document.getElementById("upgrade-list");
const gameoverPanel = document.getElementById("gameover");
const restartBtn = document.getElementById("restart-btn");

const keys = new Set();

const state = {
  paused: false,
  awaitingUpgrade: false,
  gameOver: false,
  time: 0,
  kills: 0,
  level: 1,
  xp: 0,
  xpToNext: 30,
  spawnTimer: 0,
  shootTimer: 0,
  lastFrame: performance.now(),
  upgradeChoices: [],
};

const world = {
  width: 0,
  height: 0,
};

let player = null;
let enemies = [];
let bullets = [];
let gems = [];

const rand = (min, max) => Math.random() * (max - min) + min;
const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

function xpForLevel(level) {
  return Math.floor(30 + level * 18 + level * level * 3.2);
}

function makePlayer() {
  return {
    x: world.width / 2,
    y: world.height / 2,
    r: 14,
    speed: 200,
    hp: 100,
    maxHp: 100,
    regen: 0,
    armor: 0,
    fireRate: 0.45,
    bulletSpeed: 420,
    bulletDamage: 16,
    bulletCount: 1,
    pickupRadius: 70,
    lastHit: -999,
    hitCooldown: 0.45,
  };
}

const UPGRADES = [
  {
    id: "rapid",
    name: "Rapid Fire",
    desc: "Shoot 20% faster.",
    apply() {
      player.fireRate = Math.max(0.16, player.fireRate * 0.8);
    },
  },
  {
    id: "damage",
    name: "Sharpened Ammo",
    desc: "Bullet damage +30%.",
    apply() {
      player.bulletDamage *= 1.3;
    },
  },
  {
    id: "speed",
    name: "Light Boots",
    desc: "Move speed +20%.",
    apply() {
      player.speed *= 1.2;
    },
  },
  {
    id: "vitality",
    name: "Vitality",
    desc: "Max HP +25 (heal included).",
    apply() {
      player.maxHp += 25;
      player.hp = Math.min(player.maxHp, player.hp + 25);
    },
  },
  {
    id: "multi",
    name: "Split Shot",
    desc: "Shoot +1 projectile.",
    apply() {
      player.bulletCount += 1;
    },
  },
  {
    id: "magnet",
    name: "Magnet",
    desc: "Pickup radius +30%.",
    apply() {
      player.pickupRadius *= 1.3;
    },
  },
  {
    id: "regen",
    name: "Regen",
    desc: "Regenerate 0.6 HP/s.",
    apply() {
      player.regen += 0.6;
    },
  },
  {
    id: "armor",
    name: "Armor",
    desc: "Reduce contact damage by 12%.",
    apply() {
      player.armor = Math.min(0.6, player.armor + 0.12);
    },
  },
  {
    id: "velocity",
    name: "Quick Rounds",
    desc: "Bullet speed +20%.",
    apply() {
      player.bulletSpeed *= 1.2;
    },
  },
];

function pickUpgrades(count) {
  const pool = [...UPGRADES];
  for (let i = pool.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool.slice(0, count);
}

function showUpgradeMenu() {
  state.awaitingUpgrade = true;
  state.paused = true;
  overlay.classList.remove("hidden");
  upgradeMenu.classList.remove("hidden");
  gameoverPanel.classList.add("hidden");
  upgradeList.innerHTML = "";

  const choices = pickUpgrades(3);
  state.upgradeChoices = choices;

  choices.forEach((choice, index) => {
    const btn = document.createElement("button");
    const title = document.createElement("span");
    const desc = document.createElement("span");
    title.className = "upgrade-title";
    desc.className = "upgrade-desc";
    title.textContent = `${index + 1}. ${choice.name}`;
    desc.textContent = choice.desc;
    btn.append(title, desc);
    btn.addEventListener("click", () => applyUpgrade(index));
    upgradeList.appendChild(btn);
  });
}

function hideUpgradeMenu() {
  state.awaitingUpgrade = false;
  state.paused = false;
  overlay.classList.add("hidden");
  upgradeMenu.classList.add("hidden");
  state.upgradeChoices = [];
}

function showGameOver() {
  state.gameOver = true;
  state.paused = true;
  overlay.classList.remove("hidden");
  upgradeMenu.classList.add("hidden");
  gameoverPanel.classList.remove("hidden");
}

function hideGameOver() {
  state.gameOver = false;
  state.paused = false;
  overlay.classList.add("hidden");
  gameoverPanel.classList.add("hidden");
}

function applyUpgrade(index) {
  const choice = state.upgradeChoices?.[index];
  if (!choice) return;
  choice.apply();
  hideUpgradeMenu();
}

function resetGame() {
  player = makePlayer();
  enemies = [];
  bullets = [];
  gems = [];
  state.time = 0;
  state.kills = 0;
  state.level = 1;
  state.xp = 0;
  state.xpToNext = xpForLevel(1);
  state.spawnTimer = 0;
  state.shootTimer = 0;
  hideGameOver();
  hideUpgradeMenu();
}

function resize() {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  world.width = canvas.width;
  world.height = canvas.height;
  if (player) {
    player.x = clamp(player.x, player.r, world.width - player.r);
    player.y = clamp(player.y, player.r, world.height - player.r);
  }
}

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

function getNearestEnemy() {
  let nearest = null;
  let bestDist = Infinity;
  for (const enemy of enemies) {
    const dx = enemy.x - player.x;
    const dy = enemy.y - player.y;
    const dist = dx * dx + dy * dy;
    if (dist < bestDist) {
      bestDist = dist;
      nearest = enemy;
    }
  }
  return nearest;
}

function spawnEnemy() {
  const margin = 60;
  const side = Math.floor(Math.random() * 4);
  let x = 0;
  let y = 0;
  if (side === 0) {
    x = -margin;
    y = rand(0, world.height);
  } else if (side === 1) {
    x = world.width + margin;
    y = rand(0, world.height);
  } else if (side === 2) {
    x = rand(0, world.width);
    y = -margin;
  } else {
    x = rand(0, world.width);
    y = world.height + margin;
  }

  const difficulty = 1 + state.time / 50;
  const size = 10 + Math.min(12, difficulty * 1.6);
  const hp = 22 + difficulty * 12;
  const speed = 55 + difficulty * 14;
  const damage = 6 + difficulty * 1.6;

  enemies.push({
    x,
    y,
    r: size,
    hp,
    maxHp: hp,
    speed,
    damage,
  });
}

function spawnGem(x, y) {
  gems.push({
    x,
    y,
    r: 5,
    value: 1,
  });
}

function shoot() {
  const target = getNearestEnemy();
  if (!target) return;
  const baseAngle = Math.atan2(target.y - player.y, target.x - player.x);
  const count = player.bulletCount;
  const totalSpread = count === 1 ? 0 : Math.min(0.7, 0.16 + 0.05 * (count - 1));
  const step = count === 1 ? 0 : totalSpread / (count - 1);
  const start = baseAngle - totalSpread / 2;

  for (let i = 0; i < count; i += 1) {
    const angle = start + step * i;
    bullets.push({
      x: player.x,
      y: player.y,
      r: 4,
      vx: Math.cos(angle) * player.bulletSpeed,
      vy: Math.sin(angle) * player.bulletSpeed,
      damage: player.bulletDamage,
      life: 0,
      maxLife: 2.4,
    });
  }
}

function updatePlayer(delta) {
  let moveX = 0;
  let moveY = 0;
  if (keys.has("w") || keys.has("arrowup")) moveY -= 1;
  if (keys.has("s") || keys.has("arrowdown")) moveY += 1;
  if (keys.has("a") || keys.has("arrowleft")) moveX -= 1;
  if (keys.has("d") || keys.has("arrowright")) moveX += 1;

  const length = Math.hypot(moveX, moveY);
  if (length > 0) {
    moveX /= length;
    moveY /= length;
  }

  player.x += moveX * player.speed * delta;
  player.y += moveY * player.speed * delta;
  player.x = clamp(player.x, player.r, world.width - player.r);
  player.y = clamp(player.y, player.r, world.height - player.r);

  if (player.regen > 0) {
    player.hp = Math.min(player.maxHp, player.hp + player.regen * delta);
  }
}

function updateEnemies(delta) {
  const now = state.time;
  for (let i = enemies.length - 1; i >= 0; i -= 1) {
    const enemy = enemies[i];
    const dx = player.x - enemy.x;
    const dy = player.y - enemy.y;
    const dist = Math.hypot(dx, dy) || 1;
    enemy.x += (dx / dist) * enemy.speed * delta;
    enemy.y += (dy / dist) * enemy.speed * delta;

    const postDx = player.x - enemy.x;
    const postDy = player.y - enemy.y;
    const postDist = Math.hypot(postDx, postDy);
    if (postDist < enemy.r + player.r) {
      if (now - player.lastHit > player.hitCooldown) {
        const damage = enemy.damage * (1 - player.armor);
        player.hp = Math.max(0, player.hp - damage);
        player.lastHit = now;
        if (player.hp <= 0) {
          showGameOver();
          return;
        }
      }
    }
  }
}

function updateBullets(delta) {
  for (let i = bullets.length - 1; i >= 0; i -= 1) {
    const bullet = bullets[i];
    bullet.x += bullet.vx * delta;
    bullet.y += bullet.vy * delta;
    bullet.life += delta;

    if (
      bullet.life > bullet.maxLife ||
      bullet.x < -20 ||
      bullet.x > world.width + 20 ||
      bullet.y < -20 ||
      bullet.y > world.height + 20
    ) {
      bullets.splice(i, 1);
      continue;
    }

    for (let j = enemies.length - 1; j >= 0; j -= 1) {
      const enemy = enemies[j];
      const dx = enemy.x - bullet.x;
      const dy = enemy.y - bullet.y;
      const dist = Math.hypot(dx, dy);
      if (dist < enemy.r + bullet.r) {
        enemy.hp -= bullet.damage;
        bullets.splice(i, 1);
        if (enemy.hp <= 0) {
          enemies.splice(j, 1);
          state.kills += 1;
          spawnGem(enemy.x, enemy.y);
        }
        break;
      }
    }
  }
}

function updateGems(delta) {
  for (let i = gems.length - 1; i >= 0; i -= 1) {
    const gem = gems[i];
    const dx = player.x - gem.x;
    const dy = player.y - gem.y;
    const dist = Math.hypot(dx, dy) || 1;

    if (dist < player.pickupRadius) {
      gem.x += (dx / dist) * 220 * delta;
      gem.y += (dy / dist) * 220 * delta;
    }

    const postDx = player.x - gem.x;
    const postDy = player.y - gem.y;
    const postDist = Math.hypot(postDx, postDy);
    if (postDist < gem.r + player.r) {
      state.xp += gem.value;
      gems.splice(i, 1);
    }
  }
}

function checkLevelUp() {
  if (state.awaitingUpgrade) return;
  if (state.xp >= state.xpToNext) {
    state.xp -= state.xpToNext;
    state.level += 1;
    state.xpToNext = xpForLevel(state.level);
    showUpgradeMenu();
  }
}

function updateSpawning(delta) {
  const interval = Math.max(0.35, 1.35 - state.time * 0.012);
  state.spawnTimer += delta;
  while (state.spawnTimer >= interval) {
    spawnEnemy();
    state.spawnTimer -= interval;
  }
}

function updateShooting(delta) {
  if (enemies.length === 0) {
    state.shootTimer = Math.min(state.shootTimer, player.fireRate);
    return;
  }
  state.shootTimer += delta;
  while (state.shootTimer >= player.fireRate) {
    shoot();
    state.shootTimer -= player.fireRate;
  }
}

function updateHud() {
  const hpPct = clamp(player.hp / player.maxHp, 0, 1) * 100;
  const xpPct = clamp(state.xp / state.xpToNext, 0, 1) * 100;
  hud.hpFill.style.width = `${hpPct}%`;
  hud.xpFill.style.width = `${xpPct}%`;
  hud.level.textContent = state.level;
  hud.time.textContent = formatTime(state.time);
  hud.kills.textContent = state.kills;
  if (state.awaitingUpgrade) {
    hud.info.textContent = "Choose an upgrade";
  } else if (state.paused && !state.gameOver) {
    hud.info.textContent = "Paused";
  } else {
    hud.info.textContent = "";
  }
}

function drawCircle(x, y, r, color) {
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fill();
}

function render() {
  ctx.clearRect(0, 0, world.width, world.height);

  ctx.save();
  ctx.globalAlpha = 0.08;
  drawCircle(player.x, player.y, player.pickupRadius, "#8cd8ff");
  ctx.restore();

  for (const gem of gems) {
    drawCircle(gem.x, gem.y, gem.r, "#6bdc68");
  }

  for (const bullet of bullets) {
    drawCircle(bullet.x, bullet.y, bullet.r, "#f6d365");
  }

  for (const enemy of enemies) {
    drawCircle(enemy.x, enemy.y, enemy.r, "#ff5b5b");
  }

  drawCircle(player.x, player.y, player.r + 3, "#1b1f2b");
  drawCircle(player.x, player.y, player.r, "#4f9cff");
}

function gameLoop(now) {
  const delta = Math.min(0.05, (now - state.lastFrame) / 1000);
  state.lastFrame = now;

  if (!state.paused) {
    state.time += delta;
    updatePlayer(delta);
    updateSpawning(delta);
    updateShooting(delta);
    updateBullets(delta);
    updateEnemies(delta);
    updateGems(delta);
    checkLevelUp();
  }

  render();
  updateHud();
  requestAnimationFrame(gameLoop);
}

window.addEventListener("keydown", (event) => {
  const key = event.key.toLowerCase();
  if (["arrowup", "arrowdown", "arrowleft", "arrowright", " "].includes(key)) {
    event.preventDefault();
  }

  if (key === "p") {
    if (!state.awaitingUpgrade && !state.gameOver) {
      state.paused = !state.paused;
    }
  } else if (key === "r") {
    resetGame();
  } else if (state.awaitingUpgrade && ["1", "2", "3"].includes(key)) {
    applyUpgrade(Number(key) - 1);
  }

  keys.add(key);
});

window.addEventListener("keyup", (event) => {
  keys.delete(event.key.toLowerCase());
});

restartBtn.addEventListener("click", () => {
  resetGame();
});

window.addEventListener("resize", resize);

resize();
resetGame();
requestAnimationFrame(gameLoop);
