import { appendFileSync } from "fs";
import { join } from "path";

// Use /tmp for log file since the container filesystem is read-only
const LOG_FILE = join(
  "/tmp",
  "mcp-server.log",
);

function formatMessage(
  level: string,
  message: string,
  data?: unknown,
): string {
  const timestamp = new Date().toISOString();
  const dataStr = data
    ? `\n${JSON.stringify(data, null, 2)}`
    : "";
  return `[${timestamp}] [${level}] ${message}${dataStr}\n`;
}

export const logger = {
  info(message: string, data?: unknown) {
    try {
      const logMessage = formatMessage(
        "INFO",
        message,
        data,
      );
      appendFileSync(LOG_FILE, logMessage);
    } catch (error) {
      // Silently fail if logging doesn't work
      console.error("Logging failed:", error);
    }
  },

  error(message: string, error?: unknown) {
    try {
      const logMessage = formatMessage(
        "ERROR",
        message,
        error,
      );
      appendFileSync(LOG_FILE, logMessage);
    } catch (error) {
      // Silently fail if logging doesn't work
      console.error("Logging failed:", error);
    }
  },

  // debug(message: string, data?: unknown) {
  //   const logMessage = formatMessage(
  //     "DEBUG",
  //     message,
  //     data,
  //   );
  //   appendFileSync(LOG_FILE, logMessage);
  // },
};