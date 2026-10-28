"""Loopback-only sound audition server; previews read original ZIPs on demand.

No extraction/import, source replacement, internet requests or filesystem writes.
Browser previews use full-length PCM16 WAV at original rate, channel count and level.
"""
import argparse
from collections import OrderedDict
import io
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
from threading import Lock
from urllib.parse import urlsplit
import wave
import zipfile
import numpy as np
from build_nox_audition_catalog import ROOT, WORK, ARCHIVE, read_audio

CACHE_LIMIT = 96 * 1024 * 1024


class AuditionServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address):
        super().__init__(address, Handler)
        self.catalog_bytes = (WORK / 'catalog.json').read_bytes()
        self.catalog = json.loads(self.catalog_bytes)
        self.items = {item['id']: item for item in self.catalog['items']}
        self.cache, self.cache_size, self.cache_lock = OrderedDict(), 0, Lock()

    def audio(self, item_id):
        with self.cache_lock:
            if item_id in self.cache:
                self.cache.move_to_end(item_id)
                return self.cache[item_id]
        item = self.items[item_id]
        if item['source'] == 'NOX CC0':
            with zipfile.ZipFile(ARCHIVE) as archive:
                data = archive.read(item['member'])
        else:
            data = (ROOT / item['member']).read_bytes()
        mime = 'audio/mpeg' if item['filename'].lower().endswith('.mp3') else 'audio/wav'
        if mime == 'audio/wav':
            rate, samples = read_audio(data)
            pcm = np.clip(np.rint(np.clip(samples, -1, 1) * 32768), -32768, 32767).astype('<i2')
            output = io.BytesIO()
            with wave.open(output, 'wb') as wav:
                wav.setnchannels(item['channels'])
                wav.setsampwidth(2)
                wav.setframerate(rate)
                wav.writeframes(pcm.tobytes())
            data = output.getvalue()
        result = data, mime
        with self.cache_lock:
            if item_id not in self.cache and len(data) <= CACHE_LIMIT:
                while self.cache and self.cache_size + len(data) > CACHE_LIMIT:
                    _, (old, _) = self.cache.popitem(last=False)
                    self.cache_size -= len(old)
                self.cache[item_id] = result
                self.cache_size += len(data)
        return result


class Handler(BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.do_GET(head_only=True)

    def do_GET(self, head_only=False):
        path = urlsplit(self.path).path
        if path == '/health':
            data = json.dumps(dict(service='threadbound-nox-audition-v1', items=len(self.server.items))).encode()
            return self.send_bytes(data, 'application/json', head_only)
        if path == '/api/catalog':
            return self.send_bytes(self.server.catalog_bytes, 'application/json', head_only)
        static = {'/': ('audition.html', 'text/html; charset=utf-8'),
                  '/audition.js': ('audition.js', 'text/javascript; charset=utf-8'),
                  '/audition.css': ('audition.css', 'text/css; charset=utf-8')}
        if path in static:
            filename, mime = static[path]
            return self.send_bytes((Path(__file__).parent / filename).read_bytes(), mime, head_only)
        match = re.fullmatch(r'/audio/((?:nox|game)-[a-f0-9]{12})', path)
        if not match or match[1] not in self.server.items:
            return self.send_error(404)
        try:
            data, mime = self.server.audio(match[1])
            return self.send_bytes(data, mime, head_only, ranges=True)
        except (OSError, ValueError, zipfile.BadZipFile) as error:
            print(f'Audio error: {type(error).__name__}: {error}', flush=True)
            return self.send_error(500, 'Unable to read preview source; check the local library.')

    def send_bytes(self, data, mime, head_only, ranges=False):
        start, end, status = 0, len(data)-1, 200
        requested = self.headers.get('Range') if ranges else None
        if requested:
            match = re.fullmatch(r'bytes=(\d*)-(\d*)', requested.strip())
            if not match or not any(match.groups()):
                return self.invalid_range(len(data))
            if match[1]:
                start = int(match[1])
                end = min(end, int(match[2])) if match[2] else end
            else:
                start = max(0, len(data)-int(match[2]))
            if start > end or start >= len(data):
                return self.invalid_range(len(data))
            status = 206
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(end-start+1))
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('X-Content-Type-Options', 'nosniff')
        if ranges:
            self.send_header('Accept-Ranges', 'bytes')
        if status == 206:
            self.send_header('Content-Range', f'bytes {start}-{end}/{len(data)}')
        self.end_headers()
        if not head_only:
            try:
                self.wfile.write(data[start:end+1])
            except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
                pass  # Normal when the listener stops or switches clips mid-request.

    def invalid_range(self, size):
        self.send_response(416)
        self.send_header('Content-Range', f'bytes */{size}')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def log_message(self, format, *args):
        if args and str(args[0]).startswith('GET /audio/'):
            return
        super().log_message(format, *args)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8876)
    args = parser.parse_args()
    server = AuditionServer(('127.0.0.1', args.port))
    print(f'NOX audition: http://127.0.0.1:{args.port}/ ({len(server.items)} clips)', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
