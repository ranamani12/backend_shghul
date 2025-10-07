const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 9001;

app.use(cors({ origin: '*', methods: ['GET','POST','OPTIONS'], allowedHeaders: ['*'] }));

const proxyOptions = {
  target: 'https://file.engineeric.qa/engineeric/fileSystem',
  changeOrigin: true,
  secure: true,
  pathRewrite: { '^/upload': '' },
  onProxyReq: (proxyReq, req, res) => {
    // Let browser set content-type for multipart/form-data
    if (proxyReq.getHeader('content-type') && proxyReq.getHeader('content-type').includes('multipart/form-data')) {
      // leave as is
    }
  },
  onProxyRes: (proxyRes) => {
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Headers'] = '*';
  }
};

app.use('/upload', createProxyMiddleware(proxyOptions));
app.use('/upload/', createProxyMiddleware(proxyOptions));

// simple health endpoint
app.get('/health', (req, res) => res.status(200).send('ok'));

app.listen(PORT, () => console.log(`Upload proxy running on http://localhost:${PORT}`));
