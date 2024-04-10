const express = require("express");
const app = express();
const port = 3000;

const { createProxyMiddleware } = require("http-proxy-middleware");
const axios = require('axios');

app.use(
    "/",
    createProxyMiddleware({
        target: "http://127.0.0.1:8080/", 
        changeOrigin: false, 
        ws: true,
        logLevel: "error"
    })
);

function keepalive() {
    let glitch_app_url = `http://localhost:${port}`;

    axios.get(glitch_app_url)
        .then(response => {
            if (response.data.indexOf("./app.js") == -1) {
                console.log('Server is not running. Restarting...');
                // Restart server here
            }
        })
        .catch(error => {
            console.log("Error: " + error);
        });
}

setInterval(keepalive, 9 * 1000);

app.listen(port, () => console.log(`App listening on port ${port}!`));
