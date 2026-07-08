const CACHE = 'king-v6';
const SHELL = ['./', './index.html', './manifest.webmanifest', './bg-king.webp', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Permite que el cliente ordene la activación inmediata si hay un SW en espera
self.addEventListener('message', e => {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Supabase: siempre red, nunca caché
  if (url.hostname.endsWith('supabase.co') || url.hostname.endsWith('supabase.in')) return;
  // Navegación + index.html: network-first (siempre la versión más reciente; caché solo si no hay red)
  if (e.request.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('index.html')) {
    e.respondWith(
      fetch(e.request)
        .then(r => { caches.open(CACHE).then(c => c.put(e.request, r.clone())); return r; })
        .catch(() => caches.match(e.request))
    );
  } else {
    // Resto (manifest, fuentes, etc.): cache-first con fallback a red
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
  }
});
