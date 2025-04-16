## 🛠️ Advanced Configuration
### Customizing Attack Parameters

Edit the config/attack-profiles.json file to define common attack patterns:
```json
{
  "profile": "home-network",
  "scan": {
    "timeout": 0.5,
    "ports": [22, 80, 443, 8080]
  },
  "mitm": {
    "interval": 5,
    "protocols": ["http", "dns"]
  }
}
```
## Scheduling Automated Operations

**Use the built-in scheduler for time-based operations:**

  **Run reconnaissance every 30 minutes, store results: **
```bash
sudo ./scheduler.sh --task "scan.sh --stealth" --interval 30m --output results/
```
