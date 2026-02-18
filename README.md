# Linux Reporting Project

Automated Linux infrastructure lab that demonstrates:

- Multi-subnet routing
- Firewall segmentation (Client A allowed, Client B blocked)
- NAT via router
- Apache + HTTPS (self-signed)
- Automated system reporting
- Cron automation
- Backup archiving
- Role-based infrastructure orchestration

---

## Architecture Overview

### Network Layout

```
                    Internet (NAT)
                            │
                     ┌──────┴──────┐
                     │  Router VM  │
                     └──────┬──────┘
                            │
            ┌───────────────┼──────────────-─┐
            │               │                │
    ┌───────┴──────┐ ┌──────┴─────-─┐ ┌──────┴─────-─┐
    │   Client A   │ │   Client B   │ │ Main Server  │
    │ 172.16.20.10 │ │ 172.16.30.10 │ │ 172.16.10.10 │
    └──────────────┘ └──────────────┘ └──────────────┘
```    
### Firewall Rules

| Source   | Destination | HTTP | HTTPS | Policy  |
|----------|-------------|------|-------|---------|
| Client A | Server      | ✅   | ✅    | ALLOW   |
| Client B | Server      | ❌   | ❌    | DROP    |

- Server firewall default policy: `DROP`
- Router performs NAT **only** on the uplink interface

---

## Prerequisites

- Rocky Linux / RHEL-based OS
- Static IP configured per role
- Gateway configured to point to router
- Internet access for package installation
- Root (`sudo`) access

---

## Installation

### 1. Install Git
```bash
sudo dnf install -y git
```

### 2. Clone Into `/opt` (Required Location)

This project expects the repository at `/opt/linux-reporting-project`:
```bash
sudo mkdir -p /opt
sudo git clone https://github.com/M-Alsuleibi/linux-reporting-project.git /opt/linux-reporting-project
cd /opt/linux-reporting-project
```

---

## Execution

The project uses role-based orchestration via a single entry point.

### Main Server Setup
```bash
sudo ./run.sh server
```

### Router Setup
```bash
sudo ./run.sh router
```

---

## Network Requirements

**Main Server:**
- Static IP — e.g. `172.16.10.10`
- Gateway pointing to router — e.g. `172.16.10.1`

**Router:**
- Interfaces configured for:
  - `172.16.10.0/24` (Server subnet)
  - `172.16.20.0/24` (Client A subnet)
  - `172.16.30.0/24` (Client B subnet)
  - NAT uplink interface

**Clients (A & B):**
- Gateway must point to the router
- Client A: `172.16.20.10`, gateway `172.16.20.1`
- Client B: `172.16.30.10`, gateway `172.16.30.1`

---

## Future Enhancements

- Environment-variable driven configuration