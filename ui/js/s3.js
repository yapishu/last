// S3 upload with AWS Signature V4 presigned URLs
// Adapted from boox
const S3Upload = {
  config: null,

  async loadConfig() {
    const res = await fetch('/apps/last/api/s3-config');
    if (!res.ok) throw new Error('Failed to load S3 config');
    this.config = await res.json();
    return this.config;
  },

  async upload(file, onProgress) {
    if (!this.config) await this.loadConfig();
    const c = this.config;
    if (!c.accessKeyId || !c.secretAccessKey || !c.bucket) {
      throw new Error('S3 not configured. Set up storage in your ship.');
    }
    const key = `last/${Date.now()}-${file.name}`;
    const endpoint = c.endpoint || `https://${c.bucket}.s3.amazonaws.com`;
    const host = new URL(endpoint).host;
    const region = c.region || 'us-east-1';
    const service = c.service || 's3';
    const now = new Date();
    const dateShort = now.toISOString().slice(0, 10).replace(/-/g, '');
    const dateLong = dateShort + 'T' + now.toISOString().slice(11, 19).replace(/:/g, '') + 'Z';
    const scope = `${dateShort}/${region}/${service}/aws4_request`;
    const signedHeaders = 'cache-control;content-type;host;x-amz-acl';
    const canonical = [
      'PUT',
      `/${key}`,
      '',
      `cache-control:public, max-age=3600`,
      `content-type:${file.type || 'application/octet-stream'}`,
      `host:${host}`,
      `x-amz-acl:public-read`,
      '',
      signedHeaders,
      'UNSIGNED-PAYLOAD',
    ].join('\n');
    const canonHash = await sha256(canonical);
    const strToSign = `AWS4-HMAC-SHA256\n${dateLong}\n${scope}\n${canonHash}`;
    const kDate = await hmac(`AWS4${c.secretAccessKey}`, dateShort);
    const kRegion = await hmacRaw(kDate, region);
    const kService = await hmacRaw(kRegion, service);
    const kSigning = await hmacRaw(kService, 'aws4_request');
    const sig = await hmacHex(kSigning, strToSign);
    const auth = `AWS4-HMAC-SHA256 Credential=${c.accessKeyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${sig}`;
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('PUT', `${endpoint}/${key}`);
      xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
      xhr.setRequestHeader('Cache-Control', 'public, max-age=3600');
      xhr.setRequestHeader('x-amz-acl', 'public-read');
      xhr.setRequestHeader('Authorization', auth);
      xhr.setRequestHeader('x-amz-date', dateLong);
      xhr.setRequestHeader('x-amz-content-sha256', 'UNSIGNED-PAYLOAD');
      if (onProgress) xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) onProgress(e.loaded / e.total);
      };
      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          const pubBase = c.publicUrlBase || endpoint;
          resolve({ url: `${pubBase}/${key}`, key });
        } else reject(new Error(`Upload failed: ${xhr.status}`));
      };
      xhr.onerror = () => reject(new Error('Upload error'));
      xhr.send(file);
    });
  },
};

async function sha256(str) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
  return [...new Uint8Array(buf)].map(b => b.toString(16).padStart(2, '0')).join('');
}
async function hmac(key, msg) {
  const k = typeof key === 'string' ? new TextEncoder().encode(key) : key;
  const ck = await crypto.subtle.importKey('raw', k, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', ck, new TextEncoder().encode(msg)));
}
async function hmacRaw(key, msg) { return hmac(key, msg); }
async function hmacHex(key, msg) {
  const buf = await hmac(key, msg);
  return [...buf].map(b => b.toString(16).padStart(2, '0')).join('');
}

export default S3Upload;
