<!DOCTYPE html>
<html lang="uz">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Shajara</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Alegreya:wght@500;700&family=PT+Sans:wght@400;700&display=swap" rel="stylesheet">
<style>
  :root{
    --bg:#EEF2F3; --ink:#14243B; --muted:#5B6B7F; --line:#8FA3B5;
    --card:#FFFFFF; --band-a:#E4EBEE; --band-b:#F3F6F7;
    --g1:#B5476B; --g2:#6B4C9A; --g3:#2F5D9E; --g4:#1B8A8F; --g5:#4E8A3E; --g6:#B8860B;
  }
  *{box-sizing:border-box}
  html,body{margin:0}
  body{background:var(--bg);color:var(--ink);font-family:"PT Sans",system-ui,sans-serif;line-height:1.5}
  header{padding:28px 24px 8px;max-width:1100px;margin:0 auto}
  h1{font-family:"Alegreya",Georgia,serif;font-weight:700;font-size:clamp(28px,5vw,44px);margin:0 0 4px}
  .sub{color:var(--muted);margin:0}
  .tools{display:flex;gap:8px;flex-wrap:wrap;max-width:1100px;margin:16px auto 12px;padding:0 24px}
  button{font:inherit;background:var(--card);color:var(--ink);border:1px solid var(--line);border-radius:6px;padding:8px 14px;cursor:pointer}
  button:hover{border-color:var(--ink)}
  button:focus-visible,.node:focus-visible{outline:3px solid var(--g4);outline-offset:2px}
  #stage{overflow:auto;border-top:1px solid var(--line);border-bottom:1px solid var(--line);background:var(--card);max-height:80vh}
  svg{display:block}
  .band-label{font-family:"Alegreya",Georgia,serif;font-weight:700;font-size:16px;fill:var(--muted);text-anchor:middle}
  .name{font-size:15px;font-weight:700;fill:var(--ink)}
  .years{font-size:12px;fill:var(--muted)}
  .node{cursor:pointer}
  .node rect.box{fill:var(--card);stroke-width:1.5}
  .node:hover rect.box,.node.active rect.box{fill:#F1F7F8;stroke-width:2.8}
  .link{fill:none;stroke:var(--line);stroke-width:1.6}
  #detail{max-width:1100px;margin:20px auto 48px;padding:0 24px}
  #detail h2{font-family:"Alegreya",Georgia,serif;margin:0 0 2px;font-size:26px}
  #detail p{margin:4px 0;max-width:70ch}
  .hint{color:var(--muted)}
  @page{size:landscape;margin:12mm}
  @media print{
    .tools,#detail{display:none}
    #stage{max-height:none;overflow:visible;border:0}
    svg{width:100%!important;height:auto!important}
  }
</style>
</head>
<body>

<header>
  <h1 id="title"></h1>
  <p class="sub" id="subtitle"></p>
  <p class="sub">Har bir juftlikda ota yuqorida, ona pastda joylashgan.</p>
</header>

<div class="tools">
  <button id="zin" type="button">Kattalashtirish +</button>
  <button id="zout" type="button">Kichraytirish −</button>
  <button id="zfit" type="button">Ekranga moslash</button>
  <button id="print" type="button">Chop etish</button>
</div>

<div id="stage"></div>

<section id="detail" aria-live="polite">
  <p class="hint">Batafsil ma’lumot uchun shaxs ismini bosing.</p>
</section>

<script>
/* ============================================================
   MA’LUMOTLAR — faqat shu qismni o‘zgartiring.

   P("Ism", "yil", otasi, onasi, "izoh")
   - yil, izoh bo‘sh bo‘lsa "" yozing yoki umuman yozmang.
   - otasi / onasi: yana P(...) yoziladi. Noma’lum bo‘lsa
     null yozing yoki umuman yozmang.
   ============================================================ */
const P = (name, years = "", father = null, mother = null, note = "") =>
  ({ name, years, father, mother, note });

const FAMILY = {
  title: "Muslimaning shajarasi",

  // 1-avlod: bolalar
  children: [
    P("Muslima", "2008"),
    P("Diyora", "2010"),
    P("Abdulaziz", "2015")
  ],

  // Dadasi tomoni
  father: P("Shuxrat", "1984",
    P("Fathulla", "",
      P("Nigmatulla"),
      P("Oytora", "", P("Rahmatxoja"), P("Sharofat"))
    ),
    P("Latofat", "1961",
      P("Ergash", "",
        P("Qosimbek"),
        P("Hadicha", "", P("Yoldosh"))
      ),
      P("Paraxat", "",
        P("Olimbek"),
        P("Pazilat", "", null, P("Anzirat"))
      )
    )
  ),

  // Oyisi tomoni
  mother: P("Nodira", "1987",
    P("Komiljon", "1960",
      P("Xudoybergan", "",
        P("Egamberdi", "", P("Usmon")),
        P("Manzura")
      ),
      P("Muborak", "", P("Muhammadrasul"), P("Zuhra"))
    ),
    P("Xanifa", "1961",
      P("Yoqubjon", "",
        P("Toshkentboy", "", P("Toirboy")),
        P("Mahbuba")
      ),
      P("Salima", "", P("Normat"), P("Bori"))
    )
  )
};

/* ================= CHIZISH KODI (o‘zgartirish shart emas) ================= */
const W = 170, H = 48, HG = 60, PITCH = 60, TOPLABEL = 46, PADB = 24;
const X = d => 38 + d * (W + HG);
const COLORS = ["--g1", "--g2", "--g3", "--g4", "--g5", "--g6"];
const NS = "http://www.w3.org/2000/svg";

function el(name, attrs, text){
  const e = document.createElementNS(NS, name);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (text !== undefined) e.textContent = text;
  return e;
}
function cut(s, n){ return s.length > n ? s.slice(0, n - 1) + "…" : s; }
function color(d){
  return getComputedStyle(document.documentElement).getPropertyValue(COLORS[Math.min(d, COLORS.length - 1)]).trim();
}

let all = [], groups = [], cursor = 0, maxDepth = 0;

function prep(p, depth, child){
  p.depth = depth; p.child = child; p.parents = [];
  maxDepth = Math.max(maxDepth, depth);
  if (p.father){ prep(p.father, depth + 1, p); p.parents.push(p.father); }
  if (p.mother){ prep(p.mother, depth + 1, p); p.parents.push(p.mother); }
  if (p.parents.length){
    p.cy = (p.parents[0].cy + p.parents[p.parents.length - 1].cy) / 2;
    groups.push({ kids: [p], parents: p.parents });
  } else {
    p.cy = cursor; cursor += PITCH;
  }
  all.push(p);
}

function layout(){
  all = []; groups = []; cursor = 0; maxDepth = 0;
  const parents = [];
  if (FAMILY.father){ prep(FAMILY.father, 1, null); parents.push(FAMILY.father); }
  if (FAMILY.mother){ prep(FAMILY.mother, 1, null); parents.push(FAMILY.mother); }
  const kids = FAMILY.children || [];
  const n = kids.length;
  const gcy = parents.length
    ? (parents[0].cy + parents[parents.length - 1].cy) / 2
    : (n - 1) / 2 * PITCH;
  kids.forEach((k, i) => {
    k.depth = 0; k.child = null; k.parents = parents;
    k.cy = gcy + (i - (n - 1) / 2) * PITCH;
    all.push(k);
  });
  if (parents.length && n) groups.push({ kids: kids, parents: parents });
}

let baseW = 0, baseH = 0, scale = 1, svg, activeNode = null;

function build(){
  layout();
  const ys = all.map(p => p.cy);
  const minCy = Math.min(...ys), maxCy = Math.max(...ys);
  const offY = TOPLABEL + 10 + H / 2 - minCy;
  baseW = X(maxDepth) + W + HG / 2 + 8;
  baseH = maxCy + offY + H / 2 + PADB;

  svg = el("svg", { viewBox: `0 0 ${baseW} ${baseH}`, role: "img", "aria-label": FAMILY.title });

  // avlod ustunlari
  for (let d = 0; d <= maxDepth; d++){
    svg.appendChild(el("rect", { x: X(d) - HG / 2, y: 0, width: W + HG, height: baseH,
      fill: d % 2 ? "var(--band-b)" : "var(--band-a)" }));
    svg.appendChild(el("text", { x: X(d) + W / 2, y: 28, class: "band-label" }, (d + 1) + "-avlod"));
  }

  // bog‘lovchi chiziqlar
  groups.forEach(g => {
    const col = g.kids[0].depth;
    const xr = X(col) + W, xl = X(col + 1), xm = xr + HG / 2;
    const yy = g.kids.concat(g.parents).map(n => n.cy + offY);
    let d = `M${xm},${Math.min(...yy)} V${Math.max(...yy)}`;
    g.kids.forEach(k => { d += ` M${xr},${k.cy + offY} H${xm}`; });
    g.parents.forEach(p => { d += ` M${xm},${p.cy + offY} H${xl}`; });
    svg.appendChild(el("path", { d, class: "link" }));
  });

  // shaxslar
  all.forEach(p => {
    const x = X(p.depth), y = p.cy + offY - H / 2, c = color(p.depth);
    const label = p.name + (p.years ? ", " + p.years : "");
    const g = el("g", { class: "node", tabindex: 0, role: "button", "aria-label": label });
    g.appendChild(el("rect", { class: "box", x, y, width: W, height: H, rx: 8, stroke: c }));
    g.appendChild(el("rect", { x, y, width: 6, height: H, rx: 3, fill: c }));
    if (p.years){
      g.appendChild(el("text", { x: x + 16, y: y + 21, class: "name" }, cut(p.name, 21)));
      g.appendChild(el("text", { x: x + 16, y: y + 38, class: "years" }, p.years));
    } else {
      g.appendChild(el("text", { x: x + 16, y: y + H / 2 + 5, class: "name" }, cut(p.name, 21)));
    }
    const open = () => {
      show(p);
      if (activeNode) activeNode.classList.remove("active");
      g.classList.add("active"); activeNode = g;
    };
    g.addEventListener("click", open);
    g.addEventListener("keydown", e => {
      if (e.key === "Enter" || e.key === " "){ e.preventDefault(); open(); }
    });
    svg.appendChild(g);
  });

  const stage = document.getElementById("stage");
  stage.innerHTML = "";
  stage.appendChild(svg);
  document.getElementById("subtitle").textContent = (maxDepth + 1) + " avlod";
  fit();
}

function line(box, text, cls){
  const p = document.createElement("p");
  if (cls) p.className = cls;
  p.textContent = text;
  box.appendChild(p);
}

function show(p){
  const box = document.getElementById("detail");
  box.innerHTML = "";
  const h = document.createElement("h2"); h.textContent = p.name; box.appendChild(h);
  line(box, (p.depth + 1) + "-avlod" + (p.years ? " · " + p.years : ""), "hint");

  const pa = p.depth === 0 ? [FAMILY.father, FAMILY.mother] : [p.father, p.mother];
  const roles = ["ota", "ona"];
  const ptxt = pa.map((x, i) => x ? x.name + " (" + roles[i] + ")" : null).filter(Boolean);
  if (ptxt.length) line(box, "Ota-onasi: " + ptxt.join(", "));

  if (p.depth === 1){
    const names = (FAMILY.children || []).map(c => c.name);
    if (names.length) line(box, "Farzandlari: " + names.join(", "));
  } else if (p.child){
    line(box, "Farzandi: " + p.child.name);
  }
  if (p.note) line(box, p.note);
}

function setScale(s){
  scale = Math.max(0.3, Math.min(2.5, s));
  svg.style.width = (baseW * scale) + "px";
  svg.style.height = (baseH * scale) + "px";
}
function fit(){
  const avail = document.getElementById("stage").clientWidth;
  setScale(Math.min(1, avail / baseW));
}

document.getElementById("title").textContent = FAMILY.title;
document.title = FAMILY.title;
document.getElementById("zin").onclick = () => setScale(scale + 0.15);
document.getElementById("zout").onclick = () => setScale(scale - 0.15);
document.getElementById("zfit").onclick = fit;
document.getElementById("print").onclick = () => window.print();
window.addEventListener("resize", fit);
build();
</script>
</body>
</html>
