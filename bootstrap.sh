#!/usr/bin/env bash
set -e
echo "Bootstrapping IntelliSec repository structure..."

mkdir -p backend/src frontend/src .github/workflows k8s helm/templates docs scripts

# backend files
cat > backend/package.json <<'EOF'
{
  "name": "intellisec-backend",
  "version": "0.1.0",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "node ./scripts/run_tests.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.4.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF

cat > backend/src/index.js <<'EOF'
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({status: 'ok', service: 'intellisec-backend'}));

app.get('/api/info', (req, res) => {
  res.json({
    name: 'IntelliSec',
    version: '0.1.0',
    description: 'AI-driven Security Platform - backend'
  });
});

// Simple LLM adapter stub (replace with real integration)
app.post('/api/llm/scan', async (req, res) => {
  const {text} = req.body;
  // stub response
  res.json({summary: `Scanned text length=${text ? text.length : 0}`, findings: []});
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`IntelliSec backend listening on ${port}`));
EOF

cat > backend/Dockerfile <<'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 4000
CMD ["node", "src/index.js"]
EOF

# frontend files
cat > frontend/package.json <<'EOF'
{
  "name": "intellisec-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.4.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.0.0"
  }
}
EOF

cat > frontend/src/main.jsx <<'EOF'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './index.css'

createRoot(document.getElementById('root')).render(<App />)
EOF

cat > frontend/src/App.jsx <<'EOF'
import React, {useEffect, useState} from "react";
import axios from "axios";

export default function App(){
  const [info, setInfo] = useState(null);
  useEffect(()=>{ axios.get('/api/info').then(r=>setInfo(r.data)).catch(()=>{}) },[]);
  return (
    <div style={{fontFamily:'system-ui, Arial, sans-serif', padding:24}}>
      <h1>IntelliSec</h1>
      <p>AI-driven Security Platform — demo frontend</p>
      <pre>{info ? JSON.stringify(info, null, 2) : 'Loading...'}</pre>
    </div>
  )
}
EOF

cat > frontend/src/index.css <<'EOF'
body { margin: 0; padding: 0; background: #f7f9fc; color: #111; }
EOF

cat > frontend/Dockerfile <<'EOF'
FROM node:18-alpine as build
WORKDIR /app
COPY package.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# docker-compose
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "4000:4000"
    environment:
      - PORT=4000

  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    depends_on:
      - backend
EOF

# GitHub Actions
cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    services:
      docker:
        image: docker:20.10.21
        options: --privileged
    steps:
      - uses: actions/checkout@v4
      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: 18
      - name: Install backend deps
        working-directory: ./backend
        run: npm ci
      - name: Run backend lint/test (placeholder)
        working-directory: ./backend
        run: echo "No tests yet"
      - name: Build frontend
        working-directory: ./frontend
        run: |
          npm ci
          npm run build
      - name: Build and push Docker images (optional)
        if: ${{ github.event_name == 'push' }}
        run: echo "Add docker image build/push steps here"
EOF

# k8s manifests
cat > k8s/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: intellisec-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: intellisec-backend
  template:
    metadata:
      labels:
        app: intellisec-backend
    spec:
      containers:
        - name: backend
          image: intellisec/backend:latest
          ports:
            - containerPort: 4000
EOF

cat > k8s/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: intellisec-backend
spec:
  selector:
    app: intellisec-backend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 4000
  type: ClusterIP
EOF

# Helm chart (minimal)
cat > helm/Chart.yaml <<'EOF'
apiVersion: v2
name: intellisec
description: IntelliSec Helm chart
type: application
version: 0.1.0
appVersion: "0.1.0"
EOF

cat > helm/values.yaml <<'EOF'
replicaCount: 2
image:
  repository: intellisec/backend
  tag: latest
service:
  type: ClusterIP
  port: 80
EOF

cat > helm/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "intellisec.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "intellisec.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "intellisec.name" . }}
    spec:
      containers:
        - name: backend
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 4000
EOF

cat > helm/templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "intellisec.fullname" . }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "intellisec.name" . }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 4000
EOF

cat > helm/templates/_helpers.tpl <<'EOF'
{{- define "intellisec.name" -}}
intellisec
{{- end -}}

{{- define "intellisec.fullname" -}}
{{- printf "%s" (include "intellisec.name" .) -}}
{{- end -}}
EOF

# docs
cat > docs/RUNBOOK.md <<'EOF'
Runbook - IntelliSec (basic)

Local quickstart:
1. docker-compose up --build
2. Backend: http://localhost:4000/health
3. Frontend: http://localhost:3000

To create a production release:
- Build containers and push to registry
- Update Helm values.image.repository/tag
- helm upgrade --install intellisec ./helm -n intellisec --create-namespace

Monitoring and logs:
- Backend exposes /health
- Use centralized logging (ELK/Prometheus/Grafana)...

Backup/Restore:
- No persistent data in skeleton. Add DB backups to runbook once DB added.
EOF

cat > docs/SECURITY.md <<'EOF'
Security checklist (starter)
- Do not hardcode secrets. Use Kubernetes Secrets or Vault.
- Enable HTTPS in front of services (Ingress + cert-manager).
- Scan container images for vulnerabilities (Snyk/Trivy).
- Enforce branch protection and code reviews.
- Rotate keys and PATs regularly.
EOF

# scripts
cat > scripts/build_release.sh <<'EOF'
#!/usr/bin/env bash
set -e
# Builds Docker images and creates a release tarball
docker build -t intellisec/backend:local -f backend/Dockerfile backend
docker build -t intellisec/frontend:local -f frontend/Dockerfile frontend
mkdir -p release
docker save intellisec/backend:local -o release/backend.tar
docker save intellisec/frontend:local -o release/frontend.tar
tar -czf release/intellisec-release.tar.gz release
echo "Release created at release/intellisec-release.tar.gz"
EOF
chmod +x scripts/build_release.sh

cat > scripts/run_tests.js <<'EOF'
console.log("No tests yet. Add unit/e2e tests here.");
EOF

# top-level Dev files
cat > .env.example <<'EOF'
PORT=4000
NODE_ENV=development
EOF

cat > docs/OPERATIONS.md <<'EOF'
Operations notes:
- Add SLOs and alerts for /health failures and response time
- Use rolling updates for deployments
EOF

# bootstrap done
cat > .created <<'EOF'
This repository skeleton was generated by bootstrap.sh
EOF

echo "Bootstrap complete. Files created."

