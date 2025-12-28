#!/usr/bin/env node

import http from 'node:http';
import https from 'node:https';
import { URL, URLSearchParams } from 'node:url';
import open from 'open';
import _sodium from 'libsodium-wrappers';

// Configuration from environment
const config = {
  linkedinClientId: process.env.LINKEDIN_CLIENT_ID,
  linkedinClientSecret: process.env.LINKEDIN_CLIENT_SECRET,
  githubToken: process.env.GITHUB_TOKEN,
  githubOrg: process.env.GITHUB_ORG || 'CodingWithCalvin',
  githubRepo: process.env.GITHUB_REPO, // Optional - if set, updates repo secret instead of org secret
  secretName: process.env.SECRET_NAME || 'LINKEDIN_ACCESS_TOKEN',
  port: parseInt(process.env.PORT || '3000', 10),
};

// Validate required config
function validateConfig() {
  const required = ['linkedinClientId', 'linkedinClientSecret', 'githubToken'];
  const missing = required.filter(key => !config[key]);

  if (missing.length > 0) {
    console.error('Missing required environment variables:');
    missing.forEach(key => {
      const envName = key.replace(/([A-Z])/g, '_$1').toUpperCase();
      console.error(`  - ${envName}`);
    });
    console.error('\nRequired environment variables:');
    console.error('  LINKEDIN_CLIENT_ID     - Your LinkedIn app client ID');
    console.error('  LINKEDIN_CLIENT_SECRET - Your LinkedIn app client secret');
    console.error('  GITHUB_TOKEN           - GitHub PAT with admin:org or repo scope');
    console.error('\nOptional environment variables:');
    console.error('  GITHUB_ORG             - GitHub org name (default: CodingWithCalvin)');
    console.error('  GITHUB_REPO            - GitHub repo name (if set, updates repo secret instead of org)');
    console.error('  SECRET_NAME            - Secret name to update (default: LINKEDIN_ACCESS_TOKEN)');
    console.error('  PORT                   - Local server port (default: 3000)');
    process.exit(1);
  }
}

// Start local server to capture OAuth redirect
function startServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      const url = new URL(req.url, `http://localhost:${config.port}`);

      if (url.pathname === '/callback') {
        const code = url.searchParams.get('code');
        const error = url.searchParams.get('error');

        if (error) {
          res.writeHead(400, { 'Content-Type': 'text/html' });
          res.end(`<html><body><h1>Error</h1><p>${error}: ${url.searchParams.get('error_description')}</p></body></html>`);
          server.close();
          reject(new Error(`LinkedIn OAuth error: ${error}`));
          return;
        }

        if (code) {
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end('<html><body><h1>Success!</h1><p>Authorization code received. You can close this window.</p></body></html>');
          server.close();
          resolve(code);
          return;
        }

        res.writeHead(400, { 'Content-Type': 'text/html' });
        res.end('<html><body><h1>Error</h1><p>No authorization code received.</p></body></html>');
      } else {
        res.writeHead(404);
        res.end('Not found');
      }
    });

    server.listen(config.port, () => {
      console.log(`Local server listening on http://localhost:${config.port}`);
    });

    server.on('error', reject);
  });
}

// Build LinkedIn authorization URL
function getAuthUrl() {
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: config.linkedinClientId,
    redirect_uri: `http://localhost:${config.port}/callback`,
    scope: 'openid profile w_member_social',
  });

  return `https://www.linkedin.com/oauth/v2/authorization?${params}`;
}

// Exchange authorization code for access token
async function exchangeCodeForToken(code) {
  const params = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    client_id: config.linkedinClientId,
    client_secret: config.linkedinClientSecret,
    redirect_uri: `http://localhost:${config.port}/callback`,
  });

  return new Promise((resolve, reject) => {
    const req = https.request('https://www.linkedin.com/oauth/v2/accessToken', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.error) {
            reject(new Error(`LinkedIn token error: ${json.error} - ${json.error_description}`));
          } else {
            resolve(json);
          }
        } catch (e) {
          reject(new Error(`Failed to parse LinkedIn response: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(params.toString());
    req.end();
  });
}

// Make GitHub API request
function githubRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path,
      method,
      headers: {
        'Authorization': `Bearer ${config.githubToken}`,
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'linkedin-token-refresh',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    };

    if (body) {
      options.headers['Content-Type'] = 'application/json';
    }

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`GitHub API error (${res.statusCode}): ${data}`));
        } else {
          resolve(data ? JSON.parse(data) : {});
        }
      });
    });

    req.on('error', reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

// Get GitHub public key for secret encryption
async function getPublicKey() {
  const path = config.githubRepo
    ? `/repos/${config.githubOrg}/${config.githubRepo}/actions/secrets/public-key`
    : `/orgs/${config.githubOrg}/actions/secrets/public-key`;

  return githubRequest('GET', path);
}

// Encrypt secret value using libsodium
async function encryptSecret(publicKey, secretValue) {
  await _sodium.ready;
  const sodium = _sodium;

  const binkey = sodium.from_base64(publicKey, sodium.base64_variants.ORIGINAL);
  const binsec = sodium.from_string(secretValue);
  const encBytes = sodium.crypto_box_seal(binsec, binkey);

  return sodium.to_base64(encBytes, sodium.base64_variants.ORIGINAL);
}

// Update GitHub secret
async function updateGitHubSecret(token) {
  console.log('\nFetching GitHub public key...');
  const { key, key_id } = await getPublicKey();

  console.log('Encrypting token...');
  const encryptedValue = await encryptSecret(key, token);

  console.log(`Updating secret ${config.secretName}...`);
  const path = config.githubRepo
    ? `/repos/${config.githubOrg}/${config.githubRepo}/actions/secrets/${config.secretName}`
    : `/orgs/${config.githubOrg}/actions/secrets/${config.secretName}`;

  await githubRequest('PUT', path, {
    encrypted_value: encryptedValue,
    key_id,
    visibility: config.githubRepo ? undefined : 'all',
  });

  console.log('Secret updated successfully!');
}

// Main
async function main() {
  console.log('LinkedIn Token Refresh Tool\n');

  validateConfig();

  // Start server and get auth code
  const serverPromise = startServer();

  const authUrl = getAuthUrl();
  console.log('\nOpening browser for LinkedIn authorization...');
  console.log(`URL: ${authUrl}\n`);

  await open(authUrl);

  console.log('Waiting for authorization...');
  const code = await serverPromise;
  console.log('Authorization code received!');

  // Exchange code for token
  console.log('\nExchanging code for access token...');
  const tokenResponse = await exchangeCodeForToken(code);

  console.log(`\nAccess token received!`);
  console.log(`  Expires in: ${tokenResponse.expires_in} seconds (~${Math.round(tokenResponse.expires_in / 86400)} days)`);

  // Update GitHub secret
  await updateGitHubSecret(tokenResponse.access_token);

  console.log('\nDone! Your LinkedIn access token has been refreshed.');
}

main().catch(err => {
  console.error('\nError:', err.message);
  process.exit(1);
});
