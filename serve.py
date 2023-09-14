import whisper
import time
import json
import sys
import os
import signal
import http.server
import socket
import urllib.parse
import threading
import argparse
import random
import string

# read socket path and model name from args
parser = argparse.ArgumentParser()
parser.add_argument("socket_path", help="path to socket file")
parser.add_argument("-m", "--model", help="model name: tiny, small, medium, large")

args = parser.parse_args()

# Define the Unix socket path
SOCKET_PATH = args.socket_path

start = time.time()
model = whisper.load_model(args.model)
print(f"loading model took {time.time() - start}", file=sys.stderr)


class UnixSocketHTTPServer(http.server.HTTPServer):
    def server_bind(self):
        # Override server_bind to bind to a Unix socket instead of a TCP port
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        if os.path.exists(SOCKET_PATH):
            os.remove(SOCKET_PATH)
        self.socket.bind(SOCKET_PATH)
        self.server_address = SOCKET_PATH


class UnixSocketHTTPRequestHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # Handle GET requests
        parsed_url = urllib.parse.urlparse(self.path)
        if parsed_url.path == "/":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
            return

    def do_POST(self):
        # Handle POST requests
        parsed_url = urllib.parse.urlparse(self.path)
        if parsed_url.path != "/transcribe":
            self.send_response(404)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "not found"}).encode())
            return

        query = urllib.parse.parse_qs(parsed_url.query)

        if "language" not in query or len(query["language"]) == 0:
            self.send_response(400)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "language not specified"}).encode())
            return

        language = query["language"][0]
        input_file = None

        if "input" not in query or len(query["input"]) == 0:
            # read body from request bytes into file
            content_length = int(self.headers["Content-Length"])
            body = self.rfile.read(content_length)

            # generate random string
            random_sequence = ''.join(random.choice(string.ascii_letters) for _ in range(10))
            # generate random file name
            input_file = f"/tmp/{time.time()}-{random_sequence}.wav"

            with open(input_file, "wb") as f:
                f.write(body)
        else:
            input_file = query["input"][0]

        options = dict({"language": language.strip()})

        result = model.transcribe(
            input_file,
            **options,
        )

        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(result).encode())

    def log_message(self, format, *args):
        # Disable logging to stdout
        pass


server = None


def serve_forever():
    # Create the HTTP server and start serving forever
    global server
    server = UnixSocketHTTPServer(("localhost", 8000), UnixSocketHTTPRequestHandler)
    server.serve_forever()


def shutdown_server(signum, frame):
    # Function to gracefully shut down the server
    print("Shutting down server...")
    server.shutdown()
    os.remove(SOCKET_PATH)
    sys.exit(0)


def main():
    signal.signal(signal.SIGINT, shutdown_server)
    signal.signal(signal.SIGTERM, shutdown_server)

    print("Starting server...", file=sys.stderr)

    # Create a separate thread to run the server
    server_thread = threading.Thread(target=serve_forever)
    server_thread.start()
    server_thread.join()


if __name__ == "__main__":
    main()
