# Docker Learning Guide for Backend Development

> [!TIP]
> This guide will teach you Docker fundamentals using your actual backend project as a real-world example!

## Table of Contents
1. [What is Docker?](#what-is-docker)
2. [Core Docker Concepts](#core-docker-concepts)
3. [Understanding Our Project's Docker Setup](#understanding-our-projects-docker-setup)
4. [Step-by-Step Walkthrough](#step-by-step-walkthrough)
5. [Common Docker Commands](#common-docker-commands)
6. [Troubleshooting](#troubleshooting)

---

## What is Docker?

**Docker** is a platform that packages your application and all its dependencies into a **container**. Think of it like shipping containers for software:

- 🏠 **Without Docker**: "It works on my machine!" (but not on production/colleague's machine)
- 📦 **With Docker**: Your app runs the same everywhere - development, testing, production

### Why Use Docker?

1. **Consistency**: Same environment everywhere (no more "works on my machine")
2. **Isolation**: Keep different projects separate (Node.js 16 here, Node.js 20 there)
3. **Easy Deployment**: Ship the entire container to production
4. **Quick Setup**: New team member? Just run `docker-compose up`

---

## Core Docker Concepts

### 1. **Docker Image** 📸
- A **blueprint** or **template** for your application
- Contains your code, runtime (Node.js/Python), and dependencies
- Like a recipe that describes how to build your app
- **Analogy**: A class in programming (the definition)

### 2. **Docker Container** 🚢
- A **running instance** of an image
- Your actual application running in an isolated environment
- **Analogy**: An object in programming (instance of a class)
- You can run multiple containers from the same image

### 3. **Dockerfile** 📝
- A text file with instructions to build an image
- Lists all the steps: install Node.js, copy files, install dependencies, etc.
- **Analogy**: A recipe card with step-by-step cooking instructions

### 4. **Docker Compose** 🎼
- A tool to manage multi-container applications
- Define all services in one `docker-compose.yml` file
- Start everything with one command: `docker-compose up`
- **Analogy**: An orchestra conductor managing multiple musicians

### 5. **Volume** 💾
- Persistent storage for containers
- Data survives even when containers are deleted
- **Your use case**: SQLite database needs to persist!
- **Analogy**: An external hard drive that survives computer restarts

### 6. **Port Mapping** 🔌
- Connect container ports to host ports
- Format: `host_port:container_port`
- Example: `3000:3000` means port 3000 on your computer → port 3000 in container
- **Analogy**: Phone number forwarding

---

## Understanding Our Project's Docker Setup

### Our Backend Architecture

```
┌─────────────────────────────────────┐
│   Your Computer (Host)              │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Docker Container            │  │
│  │                              │  │
│  │  ┌────────────────────────┐  │  │
│  │  │  Node.js (v20)         │  │  │
│  │  │  - Express API Server  │  │  │
│  │  └────────────────────────┘  │  │
│  │                              │  │
│  │  ┌────────────────────────┐  │  │
│  │  │  Python (3.11)         │  │  │
│  │  │  - ML Analytics        │  │  │
│  │  │  - Recommendations     │  │  │
│  │  └────────────────────────┘  │  │
│  │                              │  │
│  │  ┌────────────────────────┐  │  │
│  │  │  SQLite Database       │  │  │
│  │  │  (Volume Mounted)      │  │  │
│  │  └────────────────────────┘  │  │
│  │                              │  │
│  │  Port 3000 ───────────────┼──┼──► localhost:3000
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Why Multi-Stage Build?

Our Dockerfile uses a **multi-stage build** to:
1. Keep the final image smaller (no build tools in production)
2. Organize Python and Node.js setup clearly
3. Improve build caching (rebuild only what changed)

---

## Step-by-Step Walkthrough

### Step 1: Understanding the Dockerfile

Let's break down each section:

#### **Line 1-3: Base Image**
```dockerfile
FROM node:20-slim
```
- **FROM**: Start with a pre-built image
- **node:20-slim**: Official Node.js 20 image (lightweight version)
- Like downloading a virtual machine with Node.js pre-installed

#### **Line 5-9: Install Python**
```dockerfile
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv
```
- **RUN**: Execute a command during image build
- **apt-get**: Package manager (like `npm` but for system tools)
- We need Python for ML analytics scripts

#### **Line 11-12: Set Working Directory**
```dockerfile
WORKDIR /app
```
- **WORKDIR**: Set the current directory inside the container
- All subsequent commands run from `/app`
- Like `cd /app` but permanent

#### **Line 14-16: Copy Package Files**
```dockerfile
COPY package*.json ./
```
- **COPY**: Copy files from your computer → container
- Copy `package.json` and `package-lock.json` first
- Why first? Better caching! If package.json doesn't change, Docker reuses this layer

#### **Line 18-19: Install Node Dependencies**
```dockerfile
RUN npm install --production
```
- Install Node.js dependencies
- `--production`: Skip dev dependencies (smaller image)

#### **Line 21-23: Setup Python Environment**
```dockerfile
COPY analytics/requirements.txt ./analytics/
RUN pip3 install --no-cache-dir -r analytics/requirements.txt
```
- Copy Python requirements
- Install Python packages
- `--no-cache-dir`: Don't save download cache (smaller image)

#### **Line 25-26: Copy Application Code**
```dockerfile
COPY . .
```
- Copy all remaining files
- Done last so code changes don't invalidate previous cache layers

#### **Line 28-29: Expose Port**
```dockerfile
EXPOSE 3000
```
- **EXPOSE**: Document which port the app uses
- Doesn't actually publish the port (that's in docker-compose)
- Like a label saying "this app uses port 3000"

#### **Line 31-35: Start Command**
```dockerfile
CMD ["sh", "-c", "npm run init-db && npm start"]
```
- **CMD**: Default command when container starts
- Runs database initialization, then starts server
- Like the command you normally run: `npm start`

---

### Step 2: Understanding docker-compose.yml

```yaml
version: '3.8'
```
- Version of docker-compose syntax (use 3.8 for modern features)

```yaml
services:
  backend:
```
- **services**: Define containers to run
- **backend**: Name of our service (you choose this)

```yaml
    build:
      context: .
      dockerfile: Dockerfile
```
- **build**: Build image from Dockerfile
- **context**: Where to find files (current directory)
- **dockerfile**: Which Dockerfile to use

```yaml
    ports:
      - "3000:3000"
```
- **ports**: Map ports from container to host
- `3000:3000` means `localhost:3000` → `container:3000`

```yaml
    volumes:
      - ./database:/app/database
```
- **volumes**: Mount host directory → container directory
- Database persists on your computer, survives container restarts
- Like a shared folder between your computer and container

```yaml
    environment:
      - NODE_ENV=production
```
- **environment**: Set environment variables
- Override values from config.env if needed

```yaml
    restart: unless-stopped
```
- **restart**: Restart policy
- Container auto-restarts if it crashes (unless you manually stop it)

```yaml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```
- **healthcheck**: Verify container is working
- Every 30 seconds, check if API responds
- Mark unhealthy after 3 failed attempts

---

### Step 3: Understanding .dockerignore

```
node_modules/
```
- Don't copy `node_modules` to container
- Why? We'll install fresh dependencies inside container
- Like `.gitignore` but for Docker

---

## Common Docker Commands

### Building and Running

```bash
# Build the image
docker build -t supermarket-backend .
#      │      │        │              │
#      │      │        │              └─ Build context (current directory)
#      │      │        └─ Name (tag) for the image
#      │      └─ Flag for "tag"
#      └─ Command to build

# Run with docker-compose (RECOMMENDED)
docker-compose up
#              └─ Start all services defined in docker-compose.yml

# Run in background (detached mode)
docker-compose up -d
#                 └─ Detached mode

# Stop containers
docker-compose down
```

### Viewing Logs

```bash
# View logs (all services)
docker-compose logs

# Follow logs (live updates)
docker-compose logs -f

# Logs for specific service
docker-compose logs backend
```

### Inspecting Containers

```bash
# List running containers
docker-compose ps

# Execute command inside running container
docker-compose exec backend sh
#                │      │       └─ Command to run (shell)
#                │      └─ Service name
#                └─ Execute in running container

# Example: Check database inside container
docker-compose exec backend ls -la /app/database
```

### Managing Images and Containers

```bash
# List all images
docker images

# Remove an image
docker rmi supermarket-backend

# List all containers (including stopped)
docker ps -a

# Remove stopped containers
docker-compose rm

# Remove everything and rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### Debugging

```bash
# View container resource usage
docker stats

# Inspect container details
docker inspect <container_id>

# Check container health
docker-compose ps
```

---

## Troubleshooting

### Problem: Port Already in Use

**Error**: `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Solution**:
```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "3001:3000"  # Use port 3001 on host instead
```

---

### Problem: Volume Permission Issues

**Error**: `EACCES: permission denied, open '/app/database/checkout.db'`

**Solution**:
```bash
# Fix permissions on host
chmod -R 755 ./database

# Or run container as your user
docker-compose exec --user $(id -u):$(id -g) backend sh
```

---

### Problem: Image Build Fails

**Error**: Package installation errors

**Solution**:
```bash
# Clear Docker cache and rebuild
docker-compose build --no-cache

# Check Dockerfile for typos
# Verify package names in package.json and requirements.txt
```

---

### Problem: Database Not Persisting

**Error**: Data lost after `docker-compose down`

**Check**:
```bash
# Verify volume is mounted
docker-compose config

# Check if volume exists
docker volume ls

# Inspect volume
docker volume inspect <volume_name>
```

**Ensure** in docker-compose.yml:
```yaml
volumes:
  - ./database:/app/database  # Bind mount (recommended for dev)
```

---

## Next Steps: Practice Exercises

### Exercise 1: View Container Internals
```bash
# Start the container
docker-compose up -d

# Shell into the container
docker-compose exec backend sh

# Once inside, explore:
ls -la                    # See files
node --version            # Check Node.js version
python3 --version         # Check Python version
cat package.json          # View files
exit                      # Leave container
```

### Exercise 2: Test API in Container
```bash
# Start container
docker-compose up -d

# Test health endpoint
curl http://localhost:3000/api/health

# View logs
docker-compose logs -f backend
```

### Exercise 3: Modify and Rebuild
```bash
# Make a change to server.js (add a console.log)

# Rebuild and restart
docker-compose down
docker-compose up --build
```

### Exercise 4: Database Persistence Test
```bash
# Start container and create data
docker-compose up -d

# Stop container
docker-compose down

# Start again - data should still exist!
docker-compose up -d
```

---

## Docker Best Practices (You're Already Using!)

✅ **Multi-stage builds**: Smaller final images  
✅ **Layer caching**: Copy package.json before code  
✅ **`.dockerignore`**: Exclude unnecessary files  
✅ **Health checks**: Monitor container health  
✅ **Volumes**: Persist important data  
✅ **Environment variables**: Configuration flexibility  
✅ **Restart policies**: Auto-recovery from crashes  

---

## Resources for Further Learning

- 📚 [Official Docker Documentation](https://docs.docker.com/)
- 🎓 [Docker Curriculum](https://docker-curriculum.com/)
- 🎥 [Docker Tutorial for Beginners](https://www.youtube.com/watch?v=fqMOX6JJhGo)
- 📖 [Docker Compose Documentation](https://docs.docker.com/compose/)

---

> [!TIP]
> **Learning by Doing**: The best way to learn Docker is to experiment! Try modifying the Dockerfile, add new environment variables, or create additional services. Docker is forgiving - you can always rebuild!

Happy Dockerizing! 🐳
