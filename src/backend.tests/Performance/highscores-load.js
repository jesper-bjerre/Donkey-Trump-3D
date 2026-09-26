import http from 'k6/http';
import crypto from 'k6/crypto';
import { check } from 'k6';
import { Counter } from 'k6/metrics';
const origin = __ENV.HIGHSCORE_TEST_ORIGIN;
if (!/^http:\/\/(127\.0\.0\.1|localhost):[0-9]+$/.test(origin || '')) throw new Error('Use a test-owned loopback API');
const statuses = new Counter('highscore_status');
export const options = {
  scenarios: {
    reads: { executor: 'constant-arrival-rate', rate: 10, timeUnit: '1s', duration: '5m', preAllocatedVUs: 4, maxVUs: 8, exec: 'read' },
    writes: { executor: 'constant-arrival-rate', rate: 1, timeUnit: '1s', duration: '5m', preAllocatedVUs: 2, maxVUs: 4, exec: 'write' },
    burst: { executor: 'shared-iterations', vus: 10, iterations: 10, startTime: '5m5s', maxDuration: '15s', exec: 'write' }
  },
  thresholds: { http_req_duration: ['p(95)<2000'], checks: ['rate==1'], dropped_iterations: ['count==0'] }
};
function record(response) {
  statuses.add(1, { status: String(response.status) });
  check(response, { 'accepted snapshot or explicit throttling/contention': r => r.status === 200 || r.status === 429 || (r.status === 503 && r.json('code') === 'contention_exhausted') });
}
export function read() { record(http.get(origin + '/api/v1/highscores', { timeout: '8s' })); }
export function write() {
  const id = Array.from(new Uint8Array(crypto.randomBytes(16)), n => n.toString(16).padStart(2, '0')).join('');
  const submissionId = `${id.slice(0,8)}-${id.slice(8,12)}-${id.slice(12,16)}-${id.slice(16,20)}-${id.slice(20)}`;
  record(http.post(origin + '/api/v1/highscores', JSON.stringify({ submissionId, displayName: 'Local load', score: 10000, levelReached: 1 }),
    { headers: { 'Content-Type': 'application/json' }, timeout: '8s' }));
}
