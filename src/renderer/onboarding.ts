// Interactive first-run walkthrough: permissions → try the shortcut → pick a
// style → done. Talks to main only through window.oioi.
const steps = Array.from(document.querySelectorAll<HTMLElement>(".step"));
const dots = Array.from(document.querySelectorAll<HTMLElement>(".dot"));
const backBtn = document.getElementById("back") as HTMLButtonElement;
const nextBtn = document.getElementById("next") as HTMLButtonElement;

let current = 0;
const LAST = steps.length - 1;

function render(): void {
  steps.forEach((s, i) => s.classList.toggle("active", i === current));
  dots.forEach((d, i) => d.classList.toggle("active", i === current));
  backBtn.disabled = current === 0;
  nextBtn.textContent = current === LAST ? "Finish" : "Next";
  if (current === 1) void refreshPermissions();
}

backBtn.addEventListener("click", () => {
  if (current > 0) {
    current--;
    render();
  }
});
nextBtn.addEventListener("click", () => {
  if (current === LAST) {
    void window.oioi.onboardingDone();
    return;
  }
  current++;
  render();
});

// --- permissions (step 1) ---------------------------------------------------
async function refreshPermissions(): Promise<void> {
  const [acc, screen] = await Promise.all([
    window.oioi.getAccessibility(),
    window.oioi.getScreenPermission(),
  ]);
  markGrant("acc", acc);
  markGrant("screen", screen);
}

function markGrant(perm: string, granted: boolean): void {
  const btn = document.querySelector<HTMLButtonElement>(`.grant[data-perm="${perm}"]`);
  if (!btn) return;
  btn.classList.toggle("granted", granted);
  btn.textContent = granted ? "Granted ✓" : "Grant";
  btn.disabled = granted;
}

document.querySelectorAll<HTMLButtonElement>(".grant").forEach((btn) => {
  btn.addEventListener("click", () => {
    if (btn.dataset.perm === "acc") void window.oioi.openAccessibility();
    else void window.oioi.openScreenSettings();
  });
});
// While the user is granting in System Settings, keep checking.
setInterval(() => {
  if (current === 1) void refreshPermissions();
}, 1500);

// --- try the shortcut (step 2) ----------------------------------------------
window.oioi.onPanelOpened(() => {
  const el = document.getElementById("tryState");
  if (el) {
    el.textContent = "Nice! oioi is open 🎉";
    el.className = "try-done";
  }
});

// --- style picker (step 3) --------------------------------------------------
async function initStyle(): Promise<void> {
  const { panelStyle } = await window.oioi.getSettings();
  selectStyle(panelStyle, false);
}
function selectStyle(style: string, save: boolean): void {
  document.querySelectorAll<HTMLElement>(".style-card").forEach((c) => {
    c.classList.toggle("sel", c.dataset.style === style);
  });
  if (save) void window.oioi.saveSettings({ panelStyle: style === "glass" ? "glass" : "soft" });
}
document.querySelectorAll<HTMLButtonElement>(".style-card").forEach((card) => {
  card.addEventListener("click", () => selectStyle(card.dataset.style ?? "soft", true));
});

void initStyle();
render();
