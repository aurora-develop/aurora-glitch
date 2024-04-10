const express = require("express");
const app = express();
const port = 3000;
const PROJECT_DOMAIN = process.env.PROJECT_DOMAIN;
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");

app.get("/", function (req, res) {
    let cmdStr = "echo 'Hello, World!'";
    exec(cmdStr, function (err, stdout, stderr) {
      if (err) {
        res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
      } else {
        res.type("html").send("<pre>Powered by Aurora\n" + "</pre>");
      }
    });
  });

app.use(
    "/" + "*", 
    createProxyMiddleware({
        target: "http://127.0.0.1:8080/", 
        changeOrigin: false, 
        ws: true,
        logLevel: "error",
        onProxyReq: function onProxyReq(proxyReq, req, res) { }
    })
);

function keepalive() {
  exec("pgrep -laf app.js", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout.includes("./app.js")) {
      console.log("Aurora 正在运行");
    } else {
      //Argo 未运行，命令行调起
      exec("bash aurora.sh 2>&1 &", function (err, stdout, stderr) {
        if (err) {
          console.log("保活-调起Aurora-命令行执行错误:" + err);
        } else {
          console.log("保活-调起Aurora-命令行执行成功!");
        }
      });
    }
  });
}
setInterval(keepalive, 9 * 1000);

function keep_argo_alive() {
    if (!process.env.ARGO_AUTH) {
      console.log("未设置 ARGO_AUTH，跳过启动 Cloudflred！");
      return; 
    }
    exec("pgrep -laf cloudflared", function (err, stdout, stderr) {
      // 1.查后台系统进程，保持唤醒
      if (stdout.includes("./cloudflared tunnel")) {
        console.log("Argo 正在运行");
      } else {
        //Argo 未运行，命令行调起
        exec("bash argo.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起Argo-命令行执行错误:" + err);
          } else {
            console.log("保活-调起Argo-命令行执行成功!");
          }
        });
      }
    });
  }
  setInterval(keep_argo_alive, 30 * 1000);

app.listen(port, () => console.log(`Example app listening on port ${port}!`));