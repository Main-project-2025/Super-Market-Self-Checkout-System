# Docker Build Troubleshooting Guide

## Current Issue: Network Connectivity to Docker Hub

You're experiencing network timeouts when trying to pull images from Docker Hub. This is preventing the Docker build from completing.

**Error:** `dial tcp: lookup registry-1.docker.io: i/o timeout`

---

## Solutions (Try in Order)

### Solution 1: Check Internet Connection

```bash
# Test basic connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
ping -c 4 registry-1.docker.io

# Test Docker Hub connectivity
curl -I https://registry-1.docker.io/v2/
```

---

### Solution 2: Configure DNS for Docker

Docker might be having DNS issues. Let's configure it to use Google's DNS:

```bash
# Create or edit Docker daemon config
sudo mkdir -p /etc/docker

# Add DNS configuration
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF

# Restart Docker daemon
sudo systemctl restart docker

# Try pulling again
sudo docker pull node:20-slim
```

---

### Solution 3: Use a Different Registry Mirror

If Docker Hub is blocked or slow, use a mirror:

```bash
# Configure Docker to use a mirror
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF

# Restart Docker
sudo systemctl restart docker

# Try again
sudo docker pull node:20-slim
```

---

### Solution 4: Wait and Retry

Sometimes registry servers have temporary issues. Wait a few minutes and retry:

```bash
# Wait 5 minutes, then:
sudo docker compose build
```

---

### Solution 5: Use Offline/Alternative Approach

If network issues persist, you can:

1. **Run Node.js directly without Docker** (temporarily)
2. **Download the image on a different network** and import it
3. **Use a VPN** if Docker Hub is restricted in your region

---

## Quick Network Diagnostics

Run these commands to diagnose the issue:

```bash
# 1. Check if Docker daemon is running
sudo systemctl status docker

# 2. Check DNS resolution
nslookup registry-1.docker.io

# 3. Check firewall
sudo iptables -L -n | grep -i docker

# 4. Test Docker Hub access
curl -v https://registry-1.docker.io/v2/

# 5. Check Docker network settings
docker network ls
docker network inspect bridge
```

---

## Alternative: Run Without Docker (Temporary)

While fixing network issues, you can run the backend normally:

```bash
# Navigate to backend
cd /home/jackedhawk117/mainproject/Super-Market-Self-Checkout-System/backend

# Install dependencies (if not already done)
npm install

# Setup Python environment
cd analytics
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Initialize database
npm run init-db

# Start server
npm start
```

---

## Recommended Next Steps

1. **Try Solution 2** (Configure DNS) - This fixes most network issues
2. **Check your network/firewall** - Ensure Docker Hub isn't blocked
3. **Try later** - Registry might be temporarily down
4. **Use VPN** - If in a region with restricted access

Once network connectivity is restored, the build should complete successfully!

---

## Commands to Retry After Fix

```bash
# Clean start
sudo docker compose down -v
sudo docker system prune -a -f

# Retry build
sudo docker compose build

# Start containers
sudo docker compose up -d

# Check logs
sudo docker compose logs -f
```
