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
