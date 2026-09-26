#!/usr/bin/env python3
"""Loopback-only redirect fixture for the iPhone transport boundary test."""
import argparse
import json
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--state-file', required=True)
parser.add_argument('--slow-stream', action='store_true')
args = parser.parse_args()
state_file = Path(args.state_file)
lock = threading.Lock()
state = {'reads': 0, 'posts': 0, 'redirectTargetRequests': 0, 'streamChunks': 0}

def record(key):
    with lock:
        state[key] += 1
        state_file.write_text(json.dumps(state, indent=2) + '\n')

class Target(BaseHTTPRequestHandler):
    def do_GET(self):
        record('redirectTargetRequests')
        self.send_response(500); self.send_header('Content-Length', '0'); self.end_headers()
    do_POST = do_GET
    def log_message(self, *unused): pass

target = ThreadingHTTPServer(('127.0.0.1', 0), Target)
class Source(BaseHTTPRequestHandler):
    def do_GET(self):
        record('reads')
        if args.slow_stream:
            self.protocol_version = 'HTTP/1.1'
            self.send_response(200); self.send_header('Content-Type', 'application/json')
            self.send_header('Transfer-Encoding', 'chunked'); self.end_headers()
            try:
                for _ in range(1200):
                    self.wfile.write(b'1\r\n \r\n'); self.wfile.flush(); record('streamChunks'); time.sleep(.05)
            except (BrokenPipeError, ConnectionResetError): pass
            return
        body = json.dumps({'entries': [], 'revision': 'empty', 'fetchedAtUtc': '2026-09-26T12:00:00.000Z'}).encode()
        self.send_response(200); self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_POST(self):
        record('posts')
        length = min(int(self.headers.get('Content-Length', '0')), 4096)
        self.rfile.read(length)
        self.send_response(307)
        self.send_header('Location', f'http://127.0.0.1:{target.server_port}/api/v1/highscores')
        self.send_header('Content-Length', '0'); self.end_headers()
    def log_message(self, *unused): pass

source = ThreadingHTTPServer(('127.0.0.1', 0), Source)
state.update(origin=f'http://127.0.0.1:{source.server_port}', redirectOrigin=f'http://127.0.0.1:{target.server_port}')
state_file.write_text(json.dumps(state, indent=2) + '\n')
threading.Thread(target=target.serve_forever, daemon=True).start()
try: source.serve_forever()
finally: source.server_close(); target.shutdown(); target.server_close()
