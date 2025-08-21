Security checklist (starter)
- Do not hardcode secrets. Use Kubernetes Secrets or Vault.
- Enable HTTPS in front of services (Ingress + cert-manager).
- Scan container images for vulnerabilities (Snyk/Trivy).
- Enforce branch protection and code reviews.
- Rotate keys and PATs regularly.
