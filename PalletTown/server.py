#!/usr/bin/env python3
"""
Simple HTTP server for Pallet Town web game.
Serves the game on localhost:8000
"""

import http.server
import socketserver
import os
from pathlib import Path

PORT = 8000
DIRECTORY = Path(__file__).parent

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)
    
    def end_headers(self):
        # Add headers for better caching and CORS
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

def start_server():
    """Start the HTTP server."""
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"🏘️  Pallet Town Server Started!")
        print(f"📍 Open in your browser: http://localhost:{PORT}")
        print(f"📍 Or from another machine: http://<your-ip>:{PORT}")
        print(f"\nPress Ctrl+C to stop the server.\n")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n👋 Server stopped.")
            httpd.shutdown()

if __name__ == "__main__":
    start_server()
