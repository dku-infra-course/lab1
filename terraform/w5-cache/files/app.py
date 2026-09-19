"""week05 · Flask 백엔드 앱 (캐시 실습용)

실습 가이드 실습_W5_캐시.html 의 Part 1 / Part 3 / Part 6 코드를 하나로 모은 최종 형태다.
배치 경로: /home/ubuntu/backend-app/app.py  (백엔드 서버 VM)

엔드포인트
  GET /api/products         캐시 없음. 매 요청마다 느린 조회를 수행한다(약 2초).
  GET /api/products-cached  Redis Cache-Aside. TTL 10초.
  GET /api/products-dual    Nginx + Redis 이중 캐싱용. Redis TTL 30초.

Redis 에 requirepass 를 설정했다면 아래 REDIS_PASSWORD 를 채운다.
비밀번호를 소스에 직접 적는 대신 환경 변수로 넘기는 것을 권장한다.

  REDIS_PASSWORD='...' python3 app.py

systemd 로 기동할 때는 서비스 유닛에 다음을 추가한다.
  Environment=REDIS_PASSWORD=...
"""

import json
import os
import time
from datetime import datetime

import redis
from flask import Flask, jsonify

app = Flask(__name__)

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
# requirepass 를 설정하지 않았다면 None 이 되어 인증 없이 접속한다.
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD") or None

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True
)


def slow_database_query():
    """느린 DB 쿼리를 시뮬레이션한다. 이 2초가 이번 실습의 병목이다."""
    time.sleep(2)
    return [
        {"id": 1, "name": "Laptop", "price": 1200},
        {"id": 2, "name": "Mouse", "price": 25},
        {"id": 3, "name": "Keyboard", "price": 75}
    ]


@app.route('/api/products')
def get_products():
    """캐시 없음. 매 요청마다 약 2초가 걸린다."""
    return jsonify({
        "products": slow_database_query(),
        "cached": False,
        "timestamp": datetime.now().isoformat()
    })


@app.route('/api/products-cached')
def get_products_cached():
    """Cache-Aside(Lazy Loading) 패턴. TTL 10초."""
    cache_key = 'products:all'

    cached_data = redis_client.get(cache_key)

    if cached_data:
        print(f"[Redis] Cache HIT: {cache_key}")
        return jsonify({
            "products": json.loads(cached_data),
            "cached": True,
            "source": "redis",
            "timestamp": datetime.now().isoformat()
        })

    print(f"[Redis] Cache MISS: {cache_key}")
    products = slow_database_query()

    redis_client.setex(
        cache_key,
        10,
        json.dumps(products)
    )

    return jsonify({
        "products": products,
        "cached": False,
        "source": "database",
        "timestamp": datetime.now().isoformat()
    })


@app.route('/api/products-dual')
def get_products_dual():
    """Nginx(10초) + Redis(30초) 이중 캐싱용.

    Nginx TTL < Redis TTL 로 두어, Nginx 가 만료되어도 Redis 가 2차 방어선이 된다.
    """
    cache_key = 'products:all'
    cached_data = redis_client.get(cache_key)

    if cached_data:
        print("[Redis] Cache HIT")
        return jsonify({
            "products": json.loads(cached_data),
            "cache_info": {
                "redis_cached": True,
                "nginx_cached": "check X-Cache-Status header"
            },
            "timestamp": datetime.now().isoformat()
        })

    print("[Redis] Cache MISS - Querying database...")
    products = slow_database_query()

    redis_client.setex(cache_key, 30, json.dumps(products))

    return jsonify({
        "products": products,
        "cache_info": {
            "redis_cached": False,
            "nginx_cached": "check X-Cache-Status header"
        },
        "timestamp": datetime.now().isoformat()
    })


if __name__ == '__main__':
    # 실습 편의를 위해 0.0.0.0 으로 바인딩한다. 방화벽에서 5000 포트를
    # 내부 대역으로만 열어 두고, 외부에는 노출하지 않는다.
    app.run(host='0.0.0.0', port=5000)
