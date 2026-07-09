/**
 * Format Load Error - Map HTTP errors to user messages
 * Purpose: Determine user-friendly error message based on error type
 * Input: Error object from Load Page
 * Output: chat_id, error_message, error_code
 */
const config = $('Configuration').item.json;
const requestId = $('Generate Request ID').item.json.request_id;
const error = $json.error;

// Extract error info - handle different error types
let statusCode = null;
let errorMessage = '';

if (error) {
  if (typeof error === 'object') {
    // Error object from HTTP Request node
    statusCode = error.statusCode || error.status || null;
    errorMessage = error.message || '';

    // Check for special error types
    if (errorMessage.includes('SSL') || errorMessage.includes('certificate')) {
      // SSL certificate error
      statusCode = 'SSL_ERROR';
    }
  } else if (typeof error === 'string') {
    // String error
    errorMessage = error;
  }
}

// Map error codes to user messages
let userMessage = config.MSG_LOAD_DEFAULT;

if (statusCode === 404) {
  userMessage = config.MSG_404;
} else if (statusCode === 500) {
  userMessage = config.MSG_500;
} else if (statusCode === 403) {
  userMessage = config.MSG_403;
} else if (statusCode === 'SSL_ERROR') {
  userMessage = config.MSG_SSL_ERROR;
} else if (errorMessage.includes('ENOTFOUND') || errorMessage.includes('DNS')) {
  userMessage = config.MSG_DNS_ERROR;
} else if (errorMessage.includes('ETIMEDOUT') || errorMessage.includes('timeout')) {
  userMessage = config.MSG_TIMEOUT;
} else if (errorMessage.includes('ECONNREFUSED')) {
  userMessage = config.MSG_CONNECTION_ERROR;
}

console.log(`[${requestId}][Load Page Error] Status:`, statusCode, 'Message:', errorMessage);

return [{
  json: {
    chat_id: $('Telegram Trigger').item.json.message.chat.id,
    error_message: userMessage,
    error_code: String(statusCode || 'NETWORK_ERROR'),
    request_id: requestId
  }
}];