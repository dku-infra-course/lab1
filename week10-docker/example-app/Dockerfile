# 1단계: 빌드 스테이지. 의존성을 가상환경에 설치한다. 이 스테이지는 최종 이미지에 남지 않는다.
FROM python:3.12-slim AS builder
WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2단계: 실행 스테이지. 설치가 끝난 가상환경과 앱 코드만 가져온다.
FROM python:3.12-slim
ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION} \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
# 비루트 사용자. 숫자 UID 로 지정해야 쿠버네티스의 runAsNonRoot 검사를 통과한다.
RUN useradd --system --uid 10001 --no-create-home appuser
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=10001:10001 app.py .
USER 10001
EXPOSE 8000
# slim 이미지에는 curl 이 없으므로 파이썬으로 확인한다.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)"
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "4", "app:app"]
