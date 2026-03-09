import LastAPI from './api.js';
import S3Upload from './s3.js';

const App = {
  view: 'feed',
  feed: null,
  peers: null,
  stats: null,
  pals: null,
  settings: null,
  verbFilter: '',
  feedPage: 0,
  friendsPage: 0,
  pageSize: 20,

  async init() {
    const saved = localStorage.getItem('last-page-size');
    if (saved) this.pageSize = parseInt(saved, 10);
    this.render();
    await this.loadFeed();
  },

  async loadFeed() {
    try {
      this.feed = await LastAPI.getFeed();
      this.settings = await LastAPI.getSettings();
      this.render();
    } catch (e) {
      console.error('Failed to load feed:', e);
    }
  },

  async loadPeers() {
    try {
      this.peers = await LastAPI.getPeers();
      this.render();
    } catch (e) {
      console.error('Failed to load peers:', e);
    }
  },

  async loadStats() {
    try {
      this.stats = await LastAPI.getStats();
      this.render();
    } catch (e) {
      console.error('Failed to load stats:', e);
    }
  },

  async loadPals() {
    try {
      this.pals = await LastAPI.getPals();
    } catch (e) {
      this.pals = { pals: [] };
    }
  },

  setView(v) {
    this.view = v;
    this.feedPage = 0;
    this.friendsPage = 0;
    if (v === 'feed' && !this.feed) this.loadFeed();
    if (v === 'friends' && !this.peers) this.loadPeers();
    if (v === 'stats' && !this.stats) this.loadStats();
    this.render();
  },

  paginate(items, page) {
    const start = page * this.pageSize;
    return items.slice(start, start + this.pageSize);
  },

  renderPagination(total, page, pageKey) {
    const totalPages = Math.ceil(total / this.pageSize);
    if (totalPages <= 1 && total <= 20) return '';
    return `
      <div class="pagination">
        <button class="pg-prev" data-page-key="${pageKey}" ${page <= 0 ? 'disabled' : ''}>&lsaquo; prev</button>
        <span class="page-info">${page + 1} / ${totalPages}</span>
        <button class="pg-next" data-page-key="${pageKey}" ${page >= totalPages - 1 ? 'disabled' : ''}>next &rsaquo;</button>
        <select class="page-size-select" data-page-key="${pageKey}">
          <option value="20" ${this.pageSize === 20 ? 'selected' : ''}>20</option>
          <option value="100" ${this.pageSize === 100 ? 'selected' : ''}>100</option>
        </select>
      </div>
    `;
  },

  render() {
    const el = document.getElementById('app');
    el.innerHTML = `
      ${this.renderNav()}
      <div class="content">
        ${this.view === 'feed' ? this.renderFeed() : ''}
        ${this.view === 'friends' ? this.renderFriends() : ''}
        ${this.view === 'stats' ? this.renderStats() : ''}
        ${this.view === 'settings' ? this.renderSettings() : ''}
      </div>
    `;
    this.bindEvents();
  },

  renderNav() {
    const ship = this.settings?.ship || '';
    const tabs = [
      ['feed', 'Feed'],
      ['friends', 'Friends'],
      ['stats', 'Stats'],
      ['settings', 'Settings'],
    ];
    return `
      <header class="header">
        <div class="header-left">
          <h1 class="logo">%last</h1>
          <span class="ship-name">${esc(ship)}</span>
        </div>
        <nav class="tabs">
          ${tabs.map(([id, label]) =>
            `<button class="tab ${this.view === id ? 'active' : ''}" data-view="${id}">${label}</button>`
          ).join('')}
        </nav>
      </header>
    `;
  },

  renderFeed() {
    if (!this.feed) return '<div class="loading">Loading...</div>';
    const all = this.feed.scrobbles;
    const page = this.paginate(all, this.feedPage);
    return `
      <div class="scrobble-form">
        <div class="form-row">
          <input type="text" id="sc-verb" placeholder="verb (e.g. listening, watching, playing)" class="input verb-input" list="verb-suggestions" />
          <datalist id="verb-suggestions">
            <option value="listening">
            <option value="watching">
            <option value="playing">
            <option value="reading">
          </datalist>
        </div>
        <div class="form-row">
          <input type="text" id="sc-name" placeholder="what are you scrobbling?" class="input name-input" />
        </div>
        <div class="form-row form-row-split">
          <input type="text" id="sc-image" placeholder="image url (optional)" class="input image-input" />
          <label class="upload-btn" id="upload-label">
            <input type="file" id="sc-file" accept="image/*" style="display:none" />
            upload
          </label>
          <button id="sc-submit" class="btn btn-primary">scrobble</button>
        </div>
        <div id="upload-status" class="upload-status"></div>
      </div>
      <div class="feed-list">
        ${all.length === 0 ?
          '<div class="empty">No scrobbles yet. Record what you\'re up to!</div>' :
          page.map(sc => this.renderScrobbleCard(sc, this.feed.ship, true)).join('')
        }
      </div>
      ${this.renderPagination(all.length, this.feedPage, 'feed')}
    `;
  },

  renderScrobbleCard(sc, ship, canDelete) {
    const time = timeAgo(sc.when * 1000);
    const reactions = sc.reactions || [];
    const likes = reactions.filter(r => r.type === 'like');
    const comments = reactions.filter(r => r.type === 'comment');
    return `
      <div class="scrobble-card" data-sid="${sc.sid}">
        ${sc.image ? `<div class="sc-image"><img src="${esc(sc.image)}" alt="" loading="lazy" /></div>` : ''}
        <div class="sc-body">
          <div class="sc-meta">
            <span class="sc-ship">${esc(ship)}</span>
            <span class="sc-verb">${esc(sc.verb)}</span>
            <span class="sc-time">${time}</span>
            ${sc.source && sc.source !== 'manual' ? `<span class="sc-source">${esc(sc.source)}</span>` : ''}
          </div>
          <div class="sc-name">${esc(sc.name)}</div>
          <div class="sc-actions">
            <button class="sc-like-btn" data-ship="${esc(ship)}" data-sid="${sc.sid}" title="Like">
              ${likes.length > 0 ? `<span class="like-count">${likes.length}</span>` : ''}
              &#9825;
            </button>
            <button class="sc-comment-btn" data-ship="${esc(ship)}" data-sid="${sc.sid}" title="Comment">
              ${comments.length > 0 ? `<span class="comment-count">${comments.length}</span>` : ''}
              &#9997;
            </button>
            ${canDelete ? `<button class="sc-delete-btn" data-sid="${sc.sid}" title="Delete">&times;</button>` : ''}
          </div>
          ${comments.length > 0 ? `
            <div class="sc-comments">
              ${comments.map(c => `
                <div class="sc-comment">
                  <span class="comment-from">${esc(c.from)}</span>
                  <span class="comment-text">${esc(c.text)}</span>
                </div>
              `).join('')}
            </div>
          ` : ''}
        </div>
      </div>
    `;
  },

  renderFriends() {
    if (!this.peers) return '<div class="loading">Loading...</div>';
    const peerEntries = Object.entries(this.peers.peers || {});
    const allVerbs = new Set();
    for (const [, items] of peerEntries) {
      for (const sc of items) allVerbs.add(sc.verb);
    }
    let merged = [];
    for (const [ship, items] of peerEntries) {
      for (const sc of items) {
        merged.push({ ...sc, ship });
      }
    }
    if (this.verbFilter) {
      merged = merged.filter(sc => sc.verb === this.verbFilter);
    }
    merged.sort((a, b) => b.when - a.when);
    const page = this.paginate(merged, this.friendsPage);

    return `
      <div class="filter-bar">
        <select id="verb-filter" class="input filter-select">
          <option value="">all verbs</option>
          ${[...allVerbs].sort().map(v => `<option value="${esc(v)}" ${this.verbFilter === v ? 'selected' : ''}>${esc(v)}</option>`).join('')}
        </select>
        <button class="btn btn-small" id="refresh-peers">refresh</button>
      </div>
      <div class="feed-list">
        ${merged.length === 0 ?
          '<div class="empty">No friend scrobbles yet. Add mutual pals to see their activity.</div>' :
          page.map(sc => this.renderScrobbleCard(sc, sc.ship, false)).join('')
        }
      </div>
      ${this.renderPagination(merged.length, this.friendsPage, 'friends')}
    `;
  },

  renderStats() {
    if (!this.stats) return '<div class="loading">Loading...</div>';
    const s = this.stats;
    return `
      <div class="stats-grid">
        <div class="stat-card stat-total">
          <div class="stat-number">${s.total}</div>
          <div class="stat-label">total scrobbles</div>
        </div>
        ${Object.entries(s['by-verb'] || {}).map(([verb, count]) => `
          <div class="stat-card">
            <div class="stat-number">${count}</div>
            <div class="stat-label">${esc(verb)}</div>
          </div>
        `).join('')}
      </div>
      <div class="top-items">
        <h3 class="section-title">Top Items</h3>
        ${(s['top-items'] || []).length === 0 ? '<div class="empty">No data yet.</div>' : ''}
        <div class="top-list">
          ${(s['top-items'] || []).map((item, i) => `
            <div class="top-item">
              <span class="top-rank">${i + 1}</span>
              <span class="top-name">${esc(item.name)}</span>
              <span class="top-count">${item.count}</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  },

  renderSettings() {
    const pub = this.settings?.public ?? true;
    const whPass = this.settings?.['webhook-password'] || '';
    const webhookUrl = `${location.origin}/apps/last/api/webhook`;
    return `
      <div class="settings-section">
        <h3 class="section-title">Settings</h3>
        <div class="setting-row">
          <label>Public feed</label>
          <button class="btn ${pub ? 'btn-on' : 'btn-off'}" id="toggle-public">
            ${pub ? 'on' : 'off'}
          </button>
        </div>
        <p class="setting-hint">When on, mutual pals can subscribe to your scrobbles.</p>
        <div class="setting-row">
          <label>Webhook endpoint</label>
          <code class="webhook-url">${esc(webhookUrl)}</code>
        </div>
        <p class="setting-hint">POST {verb, name, image} to scrobble from external services. Uses HTTP Basic Auth.</p>
        <div class="setting-row">
          <label>Webhook password</label>
          <input type="text" id="wh-password" class="input" placeholder="leave blank for +code" value="${esc(whPass)}" style="flex:1;max-width:200px" />
          <button class="btn" id="save-wh-password">save</button>
        </div>
        <p class="setting-hint">Username: anything. Password: ${whPass ? 'custom password' : 'your +code (default)'}.</p>
      </div>
    `;
  },

  bindEvents() {
    // nav tabs
    document.querySelectorAll('.tab').forEach(t => {
      t.onclick = () => this.setView(t.dataset.view);
    });
    // pagination
    document.querySelectorAll('.pg-prev').forEach(btn => {
      btn.onclick = () => {
        const key = btn.dataset.pageKey;
        if (key === 'feed') { this.feedPage = Math.max(0, this.feedPage - 1); }
        if (key === 'friends') { this.friendsPage = Math.max(0, this.friendsPage - 1); }
        this.render();
        window.scrollTo(0, 0);
      };
    });
    document.querySelectorAll('.pg-next').forEach(btn => {
      btn.onclick = () => {
        const key = btn.dataset.pageKey;
        if (key === 'feed') { this.feedPage++; }
        if (key === 'friends') { this.friendsPage++; }
        this.render();
        window.scrollTo(0, 0);
      };
    });
    document.querySelectorAll('.page-size-select').forEach(sel => {
      sel.onchange = () => {
        this.pageSize = parseInt(sel.value, 10);
        localStorage.setItem('last-page-size', String(this.pageSize));
        this.feedPage = 0;
        this.friendsPage = 0;
        this.render();
      };
    });
    // scrobble form
    const submit = document.getElementById('sc-submit');
    if (submit) {
      submit.onclick = async () => {
        const verb = document.getElementById('sc-verb').value.trim();
        const name = document.getElementById('sc-name').value.trim();
        const image = document.getElementById('sc-image').value.trim();
        if (!verb || !name) return;
        submit.disabled = true;
        submit.textContent = '...';
        try {
          await LastAPI.scrobble(verb, name, image, 'manual');
          this.feed = null;
          this.feedPage = 0;
          await this.loadFeed();
        } catch (e) {
          console.error(e);
        }
        submit.disabled = false;
        submit.textContent = 'scrobble';
      };
    }
    // file upload
    const fileInput = document.getElementById('sc-file');
    if (fileInput) {
      fileInput.onchange = async (e) => {
        const file = e.target.files[0];
        if (!file) return;
        const status = document.getElementById('upload-status');
        status.textContent = 'Uploading...';
        try {
          const result = await S3Upload.upload(file, (pct) => {
            status.textContent = `Uploading... ${Math.round(pct * 100)}%`;
          });
          document.getElementById('sc-image').value = result.url;
          status.textContent = 'Uploaded!';
          setTimeout(() => { status.textContent = ''; }, 2000);
        } catch (err) {
          status.textContent = `Upload failed: ${err.message}`;
        }
      };
    }
    // delete
    document.querySelectorAll('.sc-delete-btn').forEach(btn => {
      btn.onclick = async () => {
        if (!confirm('Delete this scrobble?')) return;
        try {
          await LastAPI.deleteScrobble(btn.dataset.sid);
          this.feed = null;
          await this.loadFeed();
        } catch (e) { console.error(e); }
      };
    });
    // like
    document.querySelectorAll('.sc-like-btn').forEach(btn => {
      btn.onclick = async () => {
        try {
          await LastAPI.react(btn.dataset.ship, btn.dataset.sid, 'like', '');
          if (this.view === 'feed') { this.feed = null; await this.loadFeed(); }
          else { this.peers = null; await this.loadPeers(); }
        } catch (e) { console.error(e); }
      };
    });
    // comment
    document.querySelectorAll('.sc-comment-btn').forEach(btn => {
      btn.onclick = async () => {
        const text = prompt('Comment:');
        if (!text) return;
        try {
          await LastAPI.react(btn.dataset.ship, btn.dataset.sid, 'comment', text);
          if (this.view === 'feed') { this.feed = null; await this.loadFeed(); }
          else { this.peers = null; await this.loadPeers(); }
        } catch (e) { console.error(e); }
      };
    });
    // verb filter
    const filter = document.getElementById('verb-filter');
    if (filter) {
      filter.onchange = () => {
        this.verbFilter = filter.value;
        this.friendsPage = 0;
        this.render();
      };
    }
    // refresh peers
    const refresh = document.getElementById('refresh-peers');
    if (refresh) {
      refresh.onclick = async () => {
        this.peers = null;
        this.render();
        await this.loadPeers();
      };
    }
    // toggle public
    const togglePub = document.getElementById('toggle-public');
    if (togglePub) {
      togglePub.onclick = async () => {
        const newVal = !(this.settings?.public ?? true);
        try {
          await LastAPI.setPublic(newVal);
          this.settings.public = newVal;
          this.render();
        } catch (e) { console.error(e); }
      };
    }
    // save webhook password
    const saveWh = document.getElementById('save-wh-password');
    if (saveWh) {
      saveWh.onclick = async () => {
        const pass = document.getElementById('wh-password').value.trim();
        try {
          await LastAPI.setWebhookPassword(pass);
          this.settings['webhook-password'] = pass;
          this.render();
        } catch (e) { console.error(e); }
      };
    }
  },
};

function esc(s) {
  if (!s) return '';
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

function timeAgo(ts) {
  const diff = Date.now() - ts;
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(ts).toLocaleDateString();
}

document.addEventListener('DOMContentLoaded', () => App.init());
