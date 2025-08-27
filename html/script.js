const cursor = document.getElementById('cursor');
let visible = false;

window.addEventListener('mousemove', (e) => {
  if (!visible) return;
  cursor.style.left = e.clientX + 'px';
  cursor.style.top = e.clientY + 'px';
  fetch(`https://vixen_focus/mouseMove`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ x: e.clientX, y: e.clientY, w: innerWidth, h: innerHeight })
  });
});

window.addEventListener('mousedown', (e) => {
  if (!visible) return;
  if (e.button === 0) {
    fetch(`https://vixen_focus/mouseClick`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  }
});

window.addEventListener('message', (ev) => {
  if (ev.data.action === 'toggle') {
    visible = ev.data.state;
    cursor.style.display = visible ? 'block' : 'none';
  }
});
