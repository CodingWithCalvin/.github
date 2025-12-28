# LinkedIn Token Refresh Tool

CLI tool to refresh LinkedIn OAuth access token and automatically update the GitHub secret.

## Prerequisites

1. A LinkedIn App with OAuth 2.0 configured
   - Add `http://localhost:3000/callback` to your app's redirect URLs
2. A GitHub Personal Access Token (PAT) with:
   - `admin:org` scope (for org-level secrets), OR
   - `repo` scope (for repo-level secrets)

## Installation

```bash
cd tools/linkedin-token-refresh
npm install
```

## Usage

Set the required environment variables and run:

```bash
# Required
export LINKEDIN_CLIENT_ID="your-client-id"
export LINKEDIN_CLIENT_SECRET="your-client-secret"
export GITHUB_TOKEN="ghp_your_pat_token"

# Optional (defaults shown)
export GITHUB_ORG="CodingWithCalvin"
export SECRET_NAME="LINKEDIN_ACCESS_TOKEN"
export PORT="3000"

# For repo-level secret instead of org-level:
export GITHUB_REPO="codingwithcalvin.net"

npm start
```

### Windows (PowerShell)

```powershell
$env:LINKEDIN_CLIENT_ID="your-client-id"
$env:LINKEDIN_CLIENT_SECRET="your-client-secret"
$env:GITHUB_TOKEN="ghp_your_pat_token"

npm start
```

## What it does

1. Starts a local HTTP server on port 3000
2. Opens your browser to LinkedIn's authorization page
3. You log in and authorize the app
4. LinkedIn redirects back to localhost with an authorization code
5. The tool exchanges the code for an access token
6. The token is encrypted and uploaded to GitHub as a secret

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LINKEDIN_CLIENT_ID` | Yes | - | LinkedIn app client ID |
| `LINKEDIN_CLIENT_SECRET` | Yes | - | LinkedIn app client secret |
| `GITHUB_TOKEN` | Yes | - | GitHub PAT with appropriate scope |
| `GITHUB_ORG` | No | `CodingWithCalvin` | GitHub organization name |
| `GITHUB_REPO` | No | - | If set, updates repo secret instead of org secret |
| `SECRET_NAME` | No | `LINKEDIN_ACCESS_TOKEN` | Name of the secret to update |
| `PORT` | No | `3000` | Local server port |

## Token Expiration

LinkedIn access tokens expire after 60 days. Run this tool before expiration to refresh.
