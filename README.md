# surv-automation

Automation toolkit for Synology + macOS surveillance footage management.

## Components
- **sort_by_date_smb.sh** — moves camera files into Year/Month/Day subfolders
- **sort_by_date_quiet.sh** — silent variant for LaunchAgent
- **mount_surv** — mounts SMB share (`//kaisersuzuki@192.168.68.60/surveillance`)
- **ensure_surv_link.sh** — ensures `/Volumes/surveillance` points to live mount
- **LaunchAgent:** runs health/sort check every 15 minutes
- **newsyslog:** rotates log `/Users/kaisersuzuki/Library/Logs/surv_health_and_sort.log` weekly at 3AM

## Notes
Tested on macOS 14+ with Synology DS-1522+.  
All scripts are POSIX-compliant and safe to re-run.

