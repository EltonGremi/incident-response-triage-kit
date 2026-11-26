# Incident Response Triage Kit (Linux & Windows)

Lightweight, zero-dependency triage scripts designed to rapidly collect volatile and system-level artifacts during suspected security incidents, service anomalies, or performance degradation across hybrid Linux and Windows Server environments.

## Key Capabilities
- **Linux (`linux/ir_triage_linux.sh`)**:
  - Captures system uptime, kernel/OS details, logged-in users, and recent auth/syslog entries.
  - Enumerates running processes, listening sockets, and active network connections (`ss`/`netstat`).
  - Checks persistence mechanisms (`cron` jobs, `systemd` services) and SUID/SGID binaries.
  - Packages collected artifacts into a timestamped `.tar.gz` archive with SHA-256 checksum verification.
- **Windows (`windows/Invoke-IRTriage.ps1`)**:
  - Collects OS/system info, active processes with command lines and paths, network connections, and DNS cache/client config.
  - Exports recent `Security`, `System`, and `Application` event logs alongside scheduled tasks and running services.
  - Compresses output into a `.zip` bundle with an accompanying `.sha256` hash file.

## Usage

### Linux
```bash
chmod +x linux/ir_triage_linux.sh
sudo ./linux/ir_triage_linux.sh -o /tmp/ir-triage
```
