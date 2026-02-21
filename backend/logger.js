// =============================================================================
// LOGGER - Centralized Winston Logging Framework (Docker-aware)
// =============================================================================
// Usage in any file:
//   const logger = require('../logger');   // adjust path as needed
//   logger.info('Something happened', { userId: 123 });
//   logger.warn('Low stock', { productId: 'P001', qty: 2 });
//   logger.error('DB failure', { error: err.message });
//   logger.debug('Query executed', { sql, params });
//
// Docker: Set LOG_FORMAT=json for JSON to stdout (docker logs / aggregators).
//         Set LOG_TO_FILES=true and mount ./logs to persist file logs.
// =============================================================================

const { createLogger, format, transports } = require('winston');
const path = require('path');
const fs = require('fs');

// ---------------------------------------------------------------------------
// Environment: Docker / log aggregation friendly
//   LOG_FORMAT=json   → JSON on console (for docker logs, ELK, etc.)
//   LOG_LEVEL         → debug | info | warn | error
//   LOG_TO_FILES      → true | false — enable file transports (default true if ./logs writable)
// ---------------------------------------------------------------------------
const useJsonConsole = process.env.LOG_FORMAT === 'json';
const logToFiles = process.env.LOG_TO_FILES !== 'false';

// Ensure the logs directory exists (inside the container at /app/logs)
const LOG_DIR = path.join(__dirname, 'logs');
if (logToFiles && !fs.existsSync(LOG_DIR)) {
    try {
        fs.mkdirSync(LOG_DIR, { recursive: true });
    } catch (e) {
        // e.g. read-only filesystem in minimal container
    }
}

// ---------------------------------------------------------------------------
// Console: human-friendly (dev) or JSON (Docker / production)
// ---------------------------------------------------------------------------
const consoleFormat = useJsonConsole
    ? format.combine(
        format.timestamp(),
        format.errors({ stack: true }),
        format.json()
    )
    : format.combine(
        format.colorize({ all: true }),
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.printf(({ timestamp, level, message, ...meta }) => {
            const metaStr = Object.keys(meta).length
                ? ' ' + JSON.stringify(meta)
                : '';
            return `${timestamp} [${level.toUpperCase().padEnd(5)}] ${message}${metaStr}`;
        })
    );

// ---------------------------------------------------------------------------
// JSON format for FILE transports — structured, machine-parseable
// ---------------------------------------------------------------------------
const fileFormat = format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.json()
);

// ---------------------------------------------------------------------------
// Log level: LOG_LEVEL env > NODE_ENV=development → 'debug' > default 'info'
// ---------------------------------------------------------------------------
const logLevel =
    process.env.LOG_LEVEL ||
    (process.env.NODE_ENV === 'development' ? 'debug' : 'info');

// ---------------------------------------------------------------------------
// Transports: always console (stdout/stderr for Docker); optional files
// ---------------------------------------------------------------------------
const transportList = [
    new transports.Console({ format: consoleFormat }),
];

if (logToFiles && fs.existsSync(LOG_DIR)) {
    transportList.push(
        new transports.File({
            filename: path.join(LOG_DIR, 'combined.log'),
            format: fileFormat,
            maxsize: 10 * 1024 * 1024,
            maxFiles: 7,
        }),
        new transports.File({
            filename: path.join(LOG_DIR, 'error.log'),
            level: 'error',
            format: fileFormat,
            maxsize: 10 * 1024 * 1024,
            maxFiles: 7,
        })
    );
}

const logger = createLogger({
    level: logLevel,
    defaultMeta: { service: 'supermarket-backend' },
    transports: transportList,

    exceptionHandlers: logToFiles && fs.existsSync(LOG_DIR)
        ? [new transports.File({ filename: path.join(LOG_DIR, 'exceptions.log') })]
        : [new transports.Console({ format: fileFormat })],
    rejectionHandlers: logToFiles && fs.existsSync(LOG_DIR)
        ? [new transports.File({ filename: path.join(LOG_DIR, 'rejections.log') })]
        : [new transports.Console({ format: fileFormat })],
});

// ---------------------------------------------------------------------------
// Morgan stream — lets Morgan pipe HTTP request logs INTO Winston
// Used in server.js: app.use(morgan('combined', { stream: logger.stream }));
// ---------------------------------------------------------------------------
logger.stream = {
    write: (message) => logger.http(message.trim()),
};

module.exports = logger;
