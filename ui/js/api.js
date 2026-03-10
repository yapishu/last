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

  scrobble(verb, name, image, source, meta) {
    return this.post({
      action: 'scrobble', verb, name, image: image || '', source: source || 'manual',
      meta: meta || {},
    });
  },

  deleteScrobble(sid) {
    return this.post({ action: 'delete', sid });
  },

  setPublic(pub) {
    return this.post({ action: 'set-public', public: pub });
  },

  setWebhookPassword(password) {
    return this.post({ action: 'set-webhook-password', password });
  },

  react(target, sid, type, text) {
    return this.post({ action: 'react', target, sid, type, text: text || '' });
  },

  deleteReact(sid, index) {
    return this.post({ action: 'delete-react', sid, index });
  },

  editReact(sid, index, text) {
    return this.post({ action: 'edit-react', sid, index, text });
  },
};

export default LastAPI;
