# VideoToolKit

# 
```bash
echo "JOBS=$(($(grep cpu.cores /proc/cpuinfo | sort -u | sed 's/[^0-9]//g') + 1))" > .env
```
