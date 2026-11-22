// 실측 전
// 3단계 부하: 10 -> 30 -> 60 VU. 단계마다 10초 진입 + 60초 유지, 마지막 10초 종료(총 약 3분 40초).
// STAGES=short 이면 30 -> 60 VU만 실행한다(총 약 2분 30초). 기본값은 전체 3단계.
// 요청 구성: GET / (70%), POST /echo (25%, frontend가 backend로 전달), backend /cache (5%, Redis)
import http from 'k6/http';
import { check, sleep } from 'k6';

const FRONT = __ENV.FRONT_URL || 'http://frontend-podinfo.sre-lab:9898';
const BACK = __ENV.BACK_URL || 'http://backend-podinfo.sre-lab:9898';
const SHORT = __ENV.STAGES === 'short';

const FULL_STAGES = [
  { duration: '10s', target: 10 }, // 단계 1 진입
  { duration: '60s', target: 10 }, // 단계 1 유지: 10 VU
  { duration: '10s', target: 30 },
  { duration: '60s', target: 30 }, // 단계 2 유지: 30 VU
  { duration: '10s', target: 60 },
  { duration: '60s', target: 60 }, // 단계 3 유지: 60 VU
  { duration: '10s', target: 0 },
];
const SHORT_STAGES = [
  { duration: '10s', target: 30 },
  { duration: '60s', target: 30 },
  { duration: '10s', target: 60 },
  { duration: '60s', target: 60 },
  { duration: '10s', target: 0 },
];

export const options = {
  stages: SHORT ? SHORT_STAGES : FULL_STAGES,
  thresholds: {
    http_req_failed: ['rate<0.01'],     // 에러율 1% 미만
    http_req_duration: ['p(95)<500'],   // p95 500ms 미만
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  const r = Math.random();
  let res;
  if (r < 0.70) {
    res = http.get(`${FRONT}/`);
  } else if (r < 0.95) {
    res = http.post(`${FRONT}/echo`, JSON.stringify({ t: Date.now() }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } else {
    const key = `k${__VU}`;
    http.post(`${BACK}/cache/${key}`, 'v');
    res = http.get(`${BACK}/cache/${key}`);
  }
  check(res, { 'status 200': (x) => x.status === 200 });
  sleep(0.1);
}
