const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");

const ROOT = path.join(__dirname, "www");
const PORT_START = 8080;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".ico": "image/x-icon",
  ".json": "application/json; charset=utf-8",
  ".webmanifest": "application/manifest+json; charset=utf-8"
};

function lanIPv4() {
  var list = [];
  var ifaces = os.networkInterfaces();
  Object.keys(ifaces).forEach(function (name) {
    ifaces[name].forEach(function (iface) {
      if (iface.family === "IPv4" && !iface.internal && iface.address.indexOf("169.254.") !== 0) {
        list.push(iface.address);
      }
    });
  });
  return list;
}

function createServer() {
  return http.createServer(function (req, res) {
    var pathname;
    try {
      pathname = decodeURIComponent(req.url.split("?")[0]);
    } catch (e) {
      res.writeHead(400, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Bad Request");
      return;
    }
    if (pathname === "/") {
      pathname = "/index.html";
    }
    var filePath = path.join(ROOT, pathname);
    if (filePath !== ROOT && filePath.indexOf(ROOT + path.sep) !== 0) {
      res.writeHead(403, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Forbidden");
      return;
    }
    fs.readFile(filePath, function (err, data) {
      if (err) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("404 Not Found");
        return;
      }
      var ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, {
        "Content-Type": MIME[ext] || "application/octet-stream",
        "Cache-Control": "no-store"
      });
      res.end(data);
    });
  });
}

function printInfo(port) {
  console.log("==============================================");
  console.log("TurtleIMU server");
  console.log("Port: " + port);
  var addrs = lanIPv4();
  if (addrs.length === 0) {
    console.log("No LAN IPv4 found (check WiFi connection)");
  }
  addrs.forEach(function (a) {
    console.log("Phone URL : http://" + a + ":" + port);
    console.log("Demo URL  : http://" + a + ":" + port + "/?demo=1");
  });
  console.log("Phone must use the same WiFi. Press Ctrl+C to stop.");
  console.log("Note: iOS Safari blocks sensors over HTTP; use the GitHub Pages HTTPS URL on a real phone.");
  console.log("==============================================");
}

if (process.argv[2] === "--check") {
  console.log("LAN IPv4: " + lanIPv4().join(", "));
  process.exit(0);
}

if (process.argv[2] === "--smoke") {
  var server = createServer();
  server.listen(PORT_START, "127.0.0.1", function () {
    http.get("http://127.0.0.1:" + PORT_START + "/", function (res) {
      var len = 0;
      res.on("data", function (c) { len += c.length; });
      res.on("end", function () {
        console.log("SMOKE status=" + res.statusCode + " bytes=" + len);
        server.close();
        process.exit(res.statusCode === 200 ? 0 : 1);
      });
    }).on("error", function (e) {
      console.log("SMOKE ERR " + e.message);
      server.close();
      process.exit(1);
    });
  });
  return;
}

function start(port) {
  var server = createServer();
  server.on("error", function (err) {
    if (err.code === "EADDRINUSE" && port < PORT_START + 20) {
      start(port + 1);
    } else {
      console.error("ERR " + err.message);
      process.exit(1);
    }
  });
  server.listen(port, "0.0.0.0", function () {
    printInfo(port);
  });
}

start(PORT_START);