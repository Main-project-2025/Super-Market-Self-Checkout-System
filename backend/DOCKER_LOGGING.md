# Docker Logging Framework

The backend uses a **Winston-based logging framework** that is Docker-aware and works with `docker logs` and common log aggregators.

## How It Works

- **Console (stdout/stderr)**  
  All app logs go to the console so Docker captures them. With `LOG_FORMAT=json` (set in `docker-compose.yml`), output is JSON for easy parsing.

- **Docker logging driver**  
  The `backend` service uses the `json-file` driver with size/rotation limits so container logs don’t fill disk:
  - `max-size: 10m` per file  
  - `max-file: 5` rotated files  

- **Optional file logs**  
  When `LOG_TO_FILES=true` and the `./logs` volume is mounted, Winston also writes:
  - `./logs/combined.log` — all levels  
  - `./logs/error.log` — errors only  
  - `./logs/exceptions.log` / `rejections.log` — uncaught errors  

## Environment Variables

| Variable        | Default   | Description                                      |
|----------------|-----------|--------------------------------------------------|
| `LOG_FORMAT`   | (human)   | `json` = JSON lines to stdout (Docker/ELK)       |
| `LOG_LEVEL`    | `info`    | `debug` \| `info` \| `warn` \| `error`          |
| `LOG_TO_FILES` | `true`    | `false` = only console (e.g. read-only fs)      |

## Commands

```bash
# Follow container logs (JSON when LOG_FORMAT=json)
docker-compose logs -f backend

# View host log files (after volume mount)
type logs\combined.log   # Windows
cat logs/combined.log    # Linux/macOS
```

## Using the Logger in Code

```javascript
const logger = require('./logger');

logger.info('Message', { key: 'value' });
logger.warn('Warning', { code: 'LOW_STOCK' });
logger.error('Error', { error: err.message, stack: err.stack });
logger.debug('Detail', { sql, params });
```

HTTP requests are logged via Morgan → Winston (see `server.js`).
