// LastAPI: communicates with the %last agent via HTTP
const LastAPI = {
  base: '/apps/last/api',

  async get(path) {
    const res = await fetch(`${this.base}/${path}`);
    if (!res.ok) throw new Error(`GET ${path}: ${res.status}`);
    return res.json();
  },

  async post(action) {
    const res = await fetch(`${this.base}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(action),
    });
    if (!res.ok) throw new Error(`POST: ${res.status}`);
    return res.json();
  },

  getFeed()     { return this.get('feed'); },
  getPeers()    { return this.get('peers'); },
  getStats()    { return this.get('stats'); },
  getPals()     { return this.get('pals'); },
  getSettings() { return this.get('settings'); },
  getS3Config() { return this.get('s3-config'); },

  scrobble(verb, name, image, source) {
    return this.post({
      action: 'scrobble', verb, name, image: image || '', source: source || 'manual',
    });
  },

  deleteScrobble(sid) {
    return this.post({ action: 'delete', sid });
  },

  setPublic(pub) {
    return this.post({ action: 'set-public', public: pub });
  },

  react(target, sid, type, text) {
    return this.post({ action: 'react', target, sid, type, text: text || '' });
  },
};

export default LastAPI;
