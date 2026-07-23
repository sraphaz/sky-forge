/** Partículas do funil ascendente — portado de Sky Forge Landing.dc.html */

export function initLandingParticles(canvas: HTMLCanvasElement) {
  const ctx = canvas.getContext("2d");
  if (!ctx) return () => {};

  const c = canvas;
  const context = ctx;
  let raf = 0;
  const dpr = Math.min(window.devicePixelRatio || 1, 2);

  const resize = () => {
    c.width = c.offsetWidth * dpr;
    c.height = c.offsetHeight * dpr;
  };

  resize();
  window.addEventListener("resize", resize);

  type Particle = {
    a: number;
    r: number;
    y: number;
    sp: number;
    rot: number;
    sz: number;
    teal: boolean;
  };

  const rand = (a: number, b: number) => a + Math.random() * (b - a);
  const spawn = (y: number): Particle => ({
    a: rand(0, Math.PI * 2),
    r: rand(0.06, 0.46),
    y,
    sp: rand(0.00035, 0.0011),
    rot: rand(0.0015, 0.005),
    sz: rand(0.7, 2.2),
    teal: Math.random() < 0.35,
  });

  const particles = Array.from({ length: 90 }, () => spawn(Math.random()));

  const tick = () => {
    const W = c.width;
    const H = c.height;
    context.clearRect(0, 0, W, H);
    const dark = document.documentElement.getAttribute("data-mk-theme") !== "light";
    const blue = dark ? "150,195,255" : "46,111,224";
    const teal = dark ? "110,230,200" : "15,169,139";

    for (const p of particles) {
      p.y += p.sp;
      p.a += p.rot + (0.5 - p.r) * 0.002;
      if (p.y > 1.05) Object.assign(p, spawn(0), { y: -0.02 });
      const cone = 1 - p.y * 0.6;
      const x = W / 2 + Math.cos(p.a) * p.r * W * cone;
      const py = H - p.y * H;
      const depth = 0.35 + 0.65 * ((Math.sin(p.a) + 1) / 2);
      const alpha = Math.sin(Math.PI * Math.min(Math.max(p.y, 0), 1)) * (dark ? 0.55 : 0.4) * depth;
      context.beginPath();
      context.arc(x, py, p.sz * dpr * depth, 0, Math.PI * 2);
      context.fillStyle = `rgba(${p.teal ? teal : blue},${alpha.toFixed(3)})`;
      context.fill();
    }
    raf = requestAnimationFrame(tick);
  };

  tick();

  return () => {
    cancelAnimationFrame(raf);
    window.removeEventListener("resize", resize);
  };
}

export function initMarketingThemeToggle() {
  const root = document.documentElement;
  const stored = typeof localStorage !== "undefined" ? localStorage.getItem("sf-mk-theme") : null;
  if (stored === "light") root.setAttribute("data-mk-theme", "light");

  const btn = document.getElementById("mk-theme-toggle");
  const label = document.getElementById("mk-theme-toggle-label");
  const updateLabel = () => {
    if (label) label.textContent = root.getAttribute("data-mk-theme") === "light" ? "Claro" : "Escuro";
  };
  updateLabel();

  if (!btn || btn.dataset.bound === "true") return;
  btn.dataset.bound = "true";
  btn.addEventListener("click", () => {
    const isLight = root.getAttribute("data-mk-theme") === "light";
    const next = isLight ? "dark" : "light";
    if (next === "light") root.setAttribute("data-mk-theme", "light");
    else root.removeAttribute("data-mk-theme");
    localStorage.setItem("sf-mk-theme", next);
    updateLabel();
  });
}
