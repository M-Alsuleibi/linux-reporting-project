# Linux Practical Project — System Reporting and Access Control

A Bash-based system metrics reporting service for Rocky/RHEL-like Linux.  
Generates an HTML system status report and serves it through Apache. Includes optional disk-based retention, archiving, HTTPS, and access control.

## What it does
- Generates `/var/www/html/status.html` containing:
  - Hostname
  - IP Address
  - Current Time
  - CPU usage
  - Memory usage
  - Disk usage
  - Top processes
- Serves the page via Apache (`httpd`)
- (Planned) Saves historical copies to `/mnt/metrics`
- (Planned) Archives reports into `/backups`
- (Planned) Restricts access: allow Client A, block Client B
- (Planned) HTTPS via self-signed cert (OpenSSL)

## Requirements
- Rocky Linux 9/10 (or RHEL-like)

## Quick start (on the Main Server)
1 Clone
```bash
sudo dnf install -y git
sudo mkdir -p /opt/linux-reporting-project
sudo git clone https://github.com/M-Alsuleibi/linux-reporting-project.git /opt/linux-reporting-project
cd /opt/linux-reporting-project
```
2 Install prerequisites (manual for now)
```bash
sudo dnf install -y httpd bc
sudo systemctl enable --now httpd
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```
3 Generate the report
```bash
sudo ./scripts/generate_report.sh
```
4 view it 
```
curl http://localhost/status.html
```
