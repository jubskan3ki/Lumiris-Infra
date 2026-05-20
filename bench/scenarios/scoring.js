import http from 'k6/http';
import { check } from 'k6';
import { SharedArray } from 'k6/data';

const BASE = __ENV.BASE || 'http://localhost:4000';

const payloads = new SharedArray('dpp_payloads', () => {
    const data = JSON.parse(open('../payloads/dpp.json'));
    return [data];
});

export const options = {
    scenarios: {
        scoring_ramp: {
            executor: 'ramping-arrival-rate',
            startRate: 20,
            timeUnit: '1s',
            preAllocatedVUs: 30,
            maxVUs: 200,
            stages: [
                { duration: '30s', target: 50 },
                { duration: '1m', target: 200 },
                { duration: '1m', target: 400 },
                { duration: '30s', target: 0 },
            ],
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.005'],
        http_req_duration: ['p(95)<250', 'p(99)<500'],
        checks: ['rate>0.999'],
    },
};

const headers = { 'Content-Type': 'application/json' };

export default function () {
    const body = payloads[0];
    const res = http.post(`${BASE}/score`, JSON.stringify(body), { headers });

    check(res, {
        '200 OK': (r) => r.status === 200,
        'has grade': (r) => {
            try {
                return typeof r.json('grade') === 'string';
            } catch {
                return false;
            }
        },
        'has total': (r) => {
            try {
                return typeof r.json('total') === 'number';
            } catch {
                return false;
            }
        },
    });
}

export function handleSummary(data) {
    return {
        'bench/out/scoring.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data),
    };
}

function textSummary(data) {
    const m = data.metrics;
    const p95 = m.http_req_duration?.values?.['p(95)']?.toFixed(1) ?? 'n/a';
    const p99 = m.http_req_duration?.values?.['p(99)']?.toFixed(1) ?? 'n/a';
    const fail = m.http_req_failed?.values?.rate?.toFixed(4) ?? 'n/a';
    return `\n[scoring] p95=${p95}ms · p99=${p99}ms · failure_rate=${fail} (SLO: p95<250ms)\n`;
}
