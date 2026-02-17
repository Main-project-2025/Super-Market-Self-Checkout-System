# 🐳 Docker Quick Reference

> **New to Docker?** Start with [DOCKER_LEARNING_GUIDE.md](./DOCKER_LEARNING_GUIDE.md) for comprehensive explanations!

## 🚀 Quick Start (3 Steps)

```bash
# 1. Navigate to backend directory
cd /home/jackedhawk117/mainproject/Super-Market-Self-Checkout-System/backend

# 2. Build and start the container
docker compose up

# 3. Test the API (in another terminal)
curl http://localhost:3000/api/health
```

That's it! Your backend is now running in Docker! 🎉

---

## 📋 Common Commands Cheat Sheet

### Starting & Stopping

| Command | What it does |
|---------|--------------|
| `docker-compose up` | Build (if needed) and start containers in foreground |
| `docker-compose up -d` | Start containers in background (detached) |
| `docker-compose up --build` | Force rebuild and start |
| `docker-compose down` | Stop and remove containers |
| `docker-compose down -v` | Stop and remove containers + volumes |
| `docker-compose restart` | Restart all services |
| `docker-compose restart backend` | Restart specific service |

### Viewing Information

| Command | What it does |
|---------|--------------|
| `docker-compose ps` | List running containers |
| `docker-compose logs` | View logs from all services |
| `docker-compose logs -f` | Follow logs (live updates) |
| `docker-compose logs backend` | View logs for specific service |
| `docker images` | List all images on your system |
| `docker ps -a` | List all containers (running + stopped) |

### Executing Commands

| Command | What it does |
|---------|--------------|
| `docker-compose exec backend sh` | Open shell inside running container |
| `docker-compose exec backend node --version` | Check Node.js version in container |
| `docker-compose exec backend npm run init-db` | Reinitialize database |
| `docker-compose exec backend ls -la /app` | List files in container |

### Cleaning Up

| Command | What it does |
|---------|--------------|
| `docker system prune` | Remove unused data (containers, networks, images) |
| `docker system prune -a` | Remove ALL unused images |
| `docker volume prune` | Remove unused volumes |
| `docker-compose rm` | Remove stopped containers |

---

## 🔍 Troubleshooting Quick Fixes

### Port 3000 Already in Use?

```bash
# Find what's using the port
sudo lsof -i :3000

# Kill it
kill -9 <PID>

# Or use a different port in docker-compose.yml
# Change: "3001:3000"  # Access via localhost:3001
```

### Container Won't Start?

```bash
# Check logs for errors
docker-compose logs backend

# Rebuild from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### Database Issues?

```bash
# Check if database directory exists and has correct permissions
ls -la ./database

# Fix permissions
chmod -R 755 ./database

# Reinitialize database in container
docker-compose exec backend npm run init-db
```

### Want to Start Fresh?

```bash
# Remove everything and rebuild
docker-compose down -v
rm -rf ./database/*
docker-compose build --no-cache
docker-compose up
```

---

## 🎯 Practical Examples

### Example 1: Development Workflow

```bash
# Start backend
docker-compose up -d

# Make code changes in your editor...

# Restart to apply changes
docker-compose restart backend

# View logs to see changes
docker-compose logs -f backend
```

### Example 2: Testing API Endpoints

```bash
# Start backend
docker-compose up -d

# Health check
curl http://localhost:3000/api/health

# Test product endpoint (example)
curl http://localhost:3000/api/products

# Test with POST request
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123","email":"test@test.com"}'
```

### Example 3: Debugging Inside Container

```bash
# Start backend
docker-compose up -d

# Shell into container
docker-compose exec backend sh

# Now you're inside! Try these commands:
pwd                           # Where am I?
ls -la                        # What files are here?
cat package.json              # View file contents
node --version                # Check Node version
python3 --version             # Check Python version
env                           # See environment variables
exit                          # Leave container
```

### Example 4: Database Inspection

```bash
# Check if database exists
docker-compose exec backend ls -la /app/database

# Access SQLite database (if sqlite3 CLI is installed)
docker-compose exec backend sqlite3 /app/database/checkout.db

# Inside SQLite:
.tables                       # List all tables
SELECT * FROM users;          # Query users
.exit                         # Exit SQLite
```

---

## 📁 File Structure Reference

```
backend/
├── Dockerfile                 # Instructions to build Docker image
├── docker-compose.yml         # Orchestrate multi-container setup
├── .dockerignore              # Files to exclude from build
├── DOCKER_LEARNING_GUIDE.md   # Comprehensive Docker tutorial
├── DOCKER_QUICK_REFERENCE.md  # This file!
├── config.env                 # Environment configuration
├── package.json               # Node.js dependencies
├── server.js                  # Main application entry
├── database/                  # SQLite database (persists via volume)
├── analytics/                 # Python ML scripts
│   └── requirements.txt       # Python dependencies
└── routes/                    # API routes
```

---

## 🔧 Configuration Tips

### Change Port

In `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Use port 3001 on your computer
```

### Add Environment Variables

In `docker-compose.yml`:
```yaml
environment:
  - NODE_ENV=development
  - DEBUG=true
  - MY_CUSTOM_VAR=value
```

### Mount Additional Directories

In `docker-compose.yml`:
```yaml
volumes:
  - ./database:/app/database
  - ./logs:/app/logs           # Add this
  - ./uploads:/app/uploads     # Add this
```

---

## 📊 Understanding Container Status

```bash
$ docker-compose ps

NAME                   STATUS              PORTS
supermarket-backend    Up 2 hours (healthy)  0.0.0.0:3000->3000/tcp
```

- **Up**: Container is running
- **(healthy)**: Health check passing
- **0.0.0.0:3000->3000/tcp**: Port mapping (host:container)

---

## 🎓 Next Steps

1. ✅ **You've completed**: Basic Docker setup
2. 📖 **Learn more**: Read [DOCKER_LEARNING_GUIDE.md](./DOCKER_LEARNING_GUIDE.md)
3. 🧪 **Practice**: Try the exercises in the learning guide
4. 🚀 **Deploy**: Learn Docker production best practices

---

## ❓ Need Help?

- 📚 **Full Tutorial**: See [DOCKER_LEARNING_GUIDE.md](./DOCKER_LEARNING_GUIDE.md)
- 📖 **Official Docs**: https://docs.docker.com/
- 🔍 **Check logs**: `docker-compose logs -f backend`
- 💬 **Ask questions**: Your AI assistant is here to help!

---

**Happy Dockerizing! 🐳**
