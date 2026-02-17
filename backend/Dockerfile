# =============================================================================
# DOCKERFILE FOR SUPER-MARKET SELF-CHECKOUT BACKEND
# =============================================================================
# This Dockerfile builds an image containing both Node.js and Python
# to run the Express API server and ML analytics scripts.
#
# LEARNING NOTES:
# - Each instruction creates a new "layer" in the image
# - Layers are cached - if nothing changed, Docker reuses the layer
# - Order matters! Put things that change less often at the top
# =============================================================================

# -----------------------------------------------------------------------------
# BASE IMAGE: Start with Node.js 20 (slim version for smaller size)
# -----------------------------------------------------------------------------
# The 'slim' variant includes only essential packages, making the image smaller
FROM node:20-slim

# -----------------------------------------------------------------------------
# INSTALL PYTHON: Our analytics scripts need Python
# -----------------------------------------------------------------------------
# RUN executes commands during the build process
# We chain commands with && to reduce layers (each RUN creates a layer)
# The backslash \ allows us to split long commands across multiple lines
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    && rm -rf /var/lib/apt/lists/*
# The last line cleans up apt cache to keep image size small

# -----------------------------------------------------------------------------
# SET WORKING DIRECTORY: All subsequent commands run from /app
# -----------------------------------------------------------------------------
# WORKDIR creates the directory if it doesn't exist
# Think of it like 'cd /app' but permanent
WORKDIR /app

# -----------------------------------------------------------------------------
# COPY PACKAGE FILES: Install Node.js dependencies
# -----------------------------------------------------------------------------
# Why copy package.json first instead of all files?
# Answer: CACHING! If package.json doesn't change, Docker reuses this layer
# and we don't reinstall dependencies (much faster builds!)
COPY package*.json ./

# Install Node.js dependencies
# --production: Skip devDependencies (we don't need nodemon in production)
# --silent: Less verbose output
RUN npm install --production --silent

# -----------------------------------------------------------------------------
# SETUP PYTHON ENVIRONMENT: Install Python analytics dependencies
# -----------------------------------------------------------------------------
# Create analytics directory and copy Python requirements
COPY analytics/requirements.txt ./analytics/

# Install Python packages globally (no venv needed in container)
# --no-cache-dir: Don't save pip's download cache (saves space)
# --break-system-packages: Allow installing in Python 3.11+ (safe in Docker)
RUN pip3 install --no-cache-dir --break-system-packages -r analytics/requirements.txt

# -----------------------------------------------------------------------------
# COPY APPLICATION CODE: Copy everything else
# -----------------------------------------------------------------------------
# Done AFTER installing dependencies so code changes don't trigger
# dependency reinstallation (faster rebuilds during development)
COPY . .

# -----------------------------------------------------------------------------
# EXPOSE PORT: Document that this app uses port 3000
# -----------------------------------------------------------------------------
# NOTE: EXPOSE doesn't actually publish the port!
# It's documentation for developers. Actual publishing happens with -p flag
# or ports: in docker-compose.yml
EXPOSE 3000

# -----------------------------------------------------------------------------
# HEALTH CHECK: Let Docker monitor if the app is healthy
# -----------------------------------------------------------------------------
# Docker will run this command periodically
# If it fails, the container is marked unhealthy
# --interval: How often to check (default 30s)
# --timeout: How long to wait for response (default 30s)
# --retries: How many failures before marking unhealthy (default 3)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# -----------------------------------------------------------------------------
# STARTUP COMMAND: What to run when container starts
# -----------------------------------------------------------------------------
# CMD provides the default command (can be overridden when running container)
# We use shell form (sh -c) to run multiple commands:
# 1. Initialize database (npm run init-db)
# 2. Start the server (npm start)
CMD ["sh", "-c", "npm run init-db && npm start"]

# =============================================================================
# BUILD INSTRUCTIONS:
# 1. Build the image:
#    docker build -t supermarket-backend .
#
# 2. Run manually (if not using docker-compose):
#    docker run -p 3000:3000 -v $(pwd)/database:/app/database supermarket-backend
#
# 3. Or use docker-compose (recommended):
#    docker-compose up
# =============================================================================
