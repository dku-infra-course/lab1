"""10주차 예시 앱: Flask + Redis 카운터.

필수 요건(최종 과제 공통): /healthz 응답, 환경변수로 버전 표시. /metrics 는 권장.
시크릿은 코드에 넣지 않는다. Redis 주소는 환경변수 REDIS_HOST 로만 받는다.
"""
import os
import socket
import time

import redis
from flask import Flask, jsonify

VERSION = os.environ.get("APP_VERSION", "1.0.0")
REDIS_HOST = os.environ.get("REDIS_HOST", "")
STARTED = time.time()

app = Flask(__name__)
_requests = 0


@app.before_request
def count_request():
    global _requests
    _requests += 1


@app.get("/")
def index():
    return f"hello from {socket.gethostname()} (version {VERSION})\n"


@app.get("/healthz")
def healthz():
    # 외부 서비스(Redis)에 의존하지 않는다. 앱 프로세스가 살아 있는지만 답한다.
    return jsonify(status="ok", version=VERSION)


@app.get("/count")
def count():
    if not REDIS_HOST:
        return jsonify(error="REDIS_HOST is not set"), 503
    try:
        client = redis.Redis(host=REDIS_HOST, port=6379,
                             socket_connect_timeout=1, socket_timeout=1)
        hits = client.incr("hits")
    except redis.RedisError as exc:
        return jsonify(error=type(exc).__name__), 503
    return jsonify(hits=hits, host=socket.gethostname())


@app.get("/metrics")
def metrics():
    body = (
        "# TYPE app_requests_total counter\n"
        f"app_requests_total {_requests}\n"
        "# TYPE app_uptime_seconds gauge\n"
        f"app_uptime_seconds {time.time() - STARTED:.0f}\n"
    )
    return body, 200, {"Content-Type": "text/plain; version=0.0.4"}
