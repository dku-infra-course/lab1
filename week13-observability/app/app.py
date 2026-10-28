"""W13/W14 실습용 데모 앱 (표준 라이브러리만 사용).

/            정상 응답 (호스트명, 버전)
/healthz     준비 상태 확인(readinessProbe용)
/metrics     Prometheus 텍스트 형식 지표 (요청 수를 상태 코드별로 센다)
/alloc?mb=N  N MB 메모리를 잡아 둔다 (메모리 고갈 시나리오용)
/free        잡아 둔 메모리를 놓는다
/crash       프로세스를 즉시 종료한다 (재시작 관찰용)

환경변수
APP_VERSION  표시용 버전 (기본 2.0.0)
FAIL_RATE    0~1. 이 확률로 / 요청에 500을 돌려준다 (SLO 소진 관찰용)
"""
import os
import random
import socket
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

VERSION = os.environ.get("APP_VERSION", "2.0.0")
FAIL_RATE = float(os.environ.get("FAIL_RATE", "0"))
HOST = socket.gethostname()

lock = threading.Lock()
counts = {}          # 상태 코드별 요청 수
held = []            # /alloc 로 잡아 둔 메모리


def count(code):
    with lock:
        counts[code] = counts.get(code, 0) + 1


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # 요청마다 로그를 남기지 않는다 (kubectl logs 를 짧게 유지)

    def send(self, code, body, ctype="text/plain; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path == "/healthz":
            return self.send(200, "ok\n")
        if u.path == "/metrics":
            with lock:
                lines = ["# HELP http_requests_total 처리한 요청 수",
                         "# TYPE http_requests_total counter"]
                for code, n in sorted(counts.items()):
                    lines.append('http_requests_total{code="%s"} %d' % (code, n))
                lines.append("# TYPE app_held_megabytes gauge")
                lines.append("app_held_megabytes %d" % len(held))
            return self.send(200, "\n".join(lines) + "\n", "text/plain; version=0.0.4")
        if u.path == "/alloc":
            mb = int(q.get("mb", ["50"])[0])
            for _ in range(mb):
                held.append(bytearray(b"a" * (1024 * 1024)))
            return self.send(200, "holding %d MB\n" % len(held))
        if u.path == "/free":
            held.clear()
            return self.send(200, "freed\n")
        if u.path == "/crash":
            self.send(200, "bye\n")
            sys.stdout.flush()
            os._exit(1)
        # 기본 경로
        if random.random() < FAIL_RATE:
            count(500)
            return self.send(500, "injected failure from %s\n" % HOST)
        count(200)
        return self.send(200, "hello from %s (version %s)\n" % (HOST, VERSION))


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8000), H).serve_forever()
