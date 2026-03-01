const prompt = document.getElementById('prompt');
const entriesContainer = document.getElementById('entries');
const panel = document.getElementById('panel');
const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cz_targetX';
let lastStructureHash = '';
let lastEntryIds = new Set();
const BASE_PANEL_WIDTH = 56;
const MIN_ACTIVE_ROW_WIDTH = 150;
const SCREEN_MARGIN = 10;
const measureCanvas = document.createElement('canvas');
const measureCtx = measureCanvas.getContext('2d');
if (measureCtx) {
  measureCtx.font = '600 15px "Segoe UI", Tahoma, Geneva, Verdana, sans-serif';
}

const measureLabel = (text) => {
  if (!measureCtx) return Math.max(60, String(text || '').length * 8);
  return Math.ceil(measureCtx.measureText(String(text || '')).width);
};

const applyKeySizeClass = (node, keyText) => {
  const length = String(keyText || '').length;
  if (length <= 2) return;
  if (length <= 4) {
    node.classList.add('key-long-2');
    return;
  }
  if (length <= 7) {
    node.classList.add('key-long-3');
    return;
  }
  node.classList.add('key-long-4');
};

let readySent = false;
const sendReady = async () => {
  if (readySent) return;

  try {
    await fetch(`https://${resourceName}/ready`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{}'
    });
    readySent = true;
  } catch (e) {
    // retry handled by interval
  }
};

window.addEventListener('load', () => {
  sendReady();

  let attempts = 0;
  const interval = setInterval(() => {
    attempts += 1;
    sendReady();

    if (readySent || attempts >= 10) {
      clearInterval(interval);
    }
  }, 500);
});

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;

  if (data.action === 'update') {
    const rawX = Number(data.x ?? 0.5);
    const y = Number(data.y ?? 0.5);
    const scale = Number(data.scale ?? 1);
    const entries = Array.isArray(data.entries) ? data.entries : [];
    let maxActiveWidth = MIN_ACTIVE_ROW_WIDTH;
    for (const entry of entries) {
      const labelPx = measureLabel(String(entry.label || 'Interact'));
      const expandWidth = 46 + 20 + 24 + 8 + 10 + labelPx + 12;
      maxActiveWidth = Math.max(maxActiveWidth, Math.max(MIN_ACTIVE_ROW_WIDTH, expandWidth));
    }
    const nextStructureHash = entries
      .map((entry) => `${String(entry.id ?? '')}:${String(entry.key || 'E').toUpperCase()}:${String(entry.label || '')}`)
      .join('|');

    if (nextStructureHash !== lastStructureHash) {
      entriesContainer.innerHTML = '';
      const nextIds = new Set();

      if (entries.length === 0) {
        const row = document.createElement('div');
        row.className = 'entry';

        const keyNode = document.createElement('span');
        keyNode.className = 'entry-key';
        keyNode.textContent = 'E';

        const labelNode = document.createElement('span');
        labelNode.className = 'entry-label';
        labelNode.textContent = '';

        row.appendChild(keyNode);
        row.appendChild(labelNode);
        entriesContainer.appendChild(row);
      } else {
        for (const entry of entries) {
          const id = String(entry.id ?? '');
          nextIds.add(id);

          const row = document.createElement('div');
          row.className = 'entry';
          row.dataset.id = id;
          if (!lastEntryIds.has(id)) row.classList.add('is-new');

          const key = String(entry.key || 'E').toUpperCase();
          const label = String(entry.label || 'Interact');

          const keyNode = document.createElement('span');
          keyNode.className = 'entry-key';
          keyNode.textContent = key;
          applyKeySizeClass(keyNode, key);

          const labelNode = document.createElement('span');
          labelNode.className = 'entry-label';
          labelNode.textContent = label;

          const labelPx = measureLabel(label);
          const expandWidth = 46 + 20 + 24 + 8 + 10 + labelPx + 12;
          row.style.setProperty('--expand-width', `${Math.max(MIN_ACTIVE_ROW_WIDTH, expandWidth)}px`);

          row.appendChild(keyNode);
          row.appendChild(labelNode);
          entriesContainer.appendChild(row);
        }
      }

      lastEntryIds = nextIds;
      lastStructureHash = nextStructureHash;
    }

    const activeIds = new Set(
      entries
        .filter((entry) => !!entry.active)
        .map((entry) => String(entry.id ?? ''))
    );

    const allRows = entriesContainer.querySelectorAll('.entry');
    allRows.forEach((row) => {
      const id = String(row.dataset.id ?? '');
      row.classList.toggle('is-active', activeIds.has(id));
    });
    panel.classList.toggle('has-active', activeIds.size > 0);

    const vw = Math.max(window.innerWidth || 0, 1);
    const halfBase = (BASE_PANEL_WIDTH * scale) / 2;
    const extraRight = Math.max(0, (maxActiveWidth - BASE_PANEL_WIDTH) * scale);
    const minX = (halfBase + SCREEN_MARGIN) / vw;
    const maxX = 1 - ((halfBase + extraRight + SCREEN_MARGIN) / vw);
    const x = Math.min(Math.max(rawX, minX), Math.max(minX, maxX));

    prompt.style.left = `${x * 100}%`;
    prompt.style.top = `${y * 100}%`;
    prompt.style.transform = `translate(-50%, -50%) scale(${scale})`;
    prompt.classList.remove('hidden');
    return;
  }

  if (data.action === 'hide') {
    panel.classList.remove('has-active');
    prompt.classList.add('hidden');
  }
});
