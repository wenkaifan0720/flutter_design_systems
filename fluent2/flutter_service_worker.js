// The gallery that lived here is now a page of the Flutter Design Systems docs. This worker replaces the gallery's
// service worker and removes itself, so a browser that cached the gallery loads the redirect page instead.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    for (const client of await self.clients.matchAll({ type: 'window' })) client.navigate(client.url);
  })());
});
