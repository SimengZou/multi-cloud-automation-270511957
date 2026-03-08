const http = require('http');
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello from Service 1 - High Availability and Blue/Green is Working!\n');
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Service 1 running on port 3000');
});