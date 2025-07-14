const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const REDIRECTS_FILE = process.env.REDIRECTS_FILE || './redirects.json';

// Store redirects in memory for better performance
let redirects = {};

// Function to load redirects from file
function loadRedirects() {
  try {
    const redirectsPath = path.resolve(REDIRECTS_FILE);
    if (fs.existsSync(redirectsPath)) {
      const data = fs.readFileSync(redirectsPath, 'utf8');
      redirects = JSON.parse(data);
      console.log('Redirects loaded successfully:', Object.keys(redirects).length, 'domains');
    } else {
      console.warn(`Redirects file not found at ${redirectsPath}. Creating empty redirects.`);
      redirects = {};
    }
  } catch (error) {
    console.error('Error loading redirects file:', error.message);
    redirects = {};
  }
}

// Load redirects on startup
loadRedirects();

// Middleware to log requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url} - Host: ${req.get('host')}`);
  next();
});

// Health check endpoint for Google Cloud Run
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    redirectsLoaded: Object.keys(redirects).length
  });
});


// Main redirect handler
app.use('*', (req, res) => {
  const hostname = req.get('host');
  const fullUrl = req.protocol + '://' + hostname + req.originalUrl;
  
  // Remove port from hostname for matching if present
  const cleanHostname = hostname.split(':')[0];
  
  // Check if we have a redirect for this domain
  if (redirects[cleanHostname]) {
    const targetUrl = redirects[cleanHostname];
    console.log(`Redirecting ${fullUrl} -> ${targetUrl}`);
    
    // Use 301 (permanent redirect) for retired domains
    return res.redirect(301, targetUrl);
  }
  
  // If no redirect found, return 404
  console.log(`No redirect found for domain: ${cleanHostname}`);
  res.status(404).json({
    error: 'Domain not found',
    domain: cleanHostname,
    message: `No redirect configured for domain: ${cleanHostname}`,
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(500).json({
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Domain redirect service running on port ${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});
