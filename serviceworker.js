var staticCacheName = "pwa-v" + new Date().getTime();
var filesToCache = [
    "public/img/pwa/icon-192x192.png",
    "public/img/pwa/icon-512x512.png",
];

/*
// Cache on install
self.addEventListener("install", event => {
    this.skipWaiting();
    event.waitUntil(
        caches.open(staticCacheName)
            .then(cache => {
                return cache.addAll(filesToCache);
            })
    )
});
*/
/*
// Clear cache on activate
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(cacheName => (cacheName.startsWith("pwa-")))
                    .filter(cacheName => (cacheName !== staticCacheName))
                    .map(cacheName => caches.delete(cacheName))
            );
        })
    );
});*/

// Always fetch from network — the app uses filemtime query strings (?v=<mtime>)
// for cache-busting, so serving stale Cache Storage entries would break deploys.
self.addEventListener("fetch", (event) => {
    event.respondWith(fetch(event.request));
});
