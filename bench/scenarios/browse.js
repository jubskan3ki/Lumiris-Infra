import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend } from 'k6/metrics';

const BASE = __ENV.BASE || 'http://localhost:3000';

const ttfb = new Trend('ttfb_ms', true);

export const options = {
    scenarios: {
        organic: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 25 },
                { duration: '2m', target: 50 },
                { duration: '30s', target: 0 },
            ],
            gracefulRampDown: '15s',
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<800'],
        'http_req_duration{group:::homepage}': ['p(95)<600'],
        ttfb_ms: ['p(95)<400'],
    },
};

const PAGES = ['/', '/journal', '/about', '/manifesto'];

export default function () {
    group('homepage', () => {
        const res = http.get(`${BASE}/`);
        ttfb.add(res.timings.waiting);
        check(res, {
            '200 OK': (r) => r.status === 200,
            'has html': (r) => (r.body || '').includes('<html'),
        });
    });

    group('navigation', () => {
        const path = PAGES[Math.floor(Math.random() * PAGES.length)];
        const res = http.get(`${BASE}${path}`);
        ttfb.add(res.timings.waiting);
        check(res, { reachable: (r) => r.status < 500 });
    });

    sleep(Math.random() * 2 + 0.5);
}

export function handleSummary(data) {
    return {
        'bench/out/browse.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data),
    };
}

function textSummary(data) {
    const m = data.metrics;
    const p95 = m.http_req_duration?.values?.['p(95)']?.toFixed(1) ?? 'n/a';
    const fail = m.http_req_failed?.values?.rate?.toFixed(4) ?? 'n/a';
    return `\n[browse] p95=${p95}ms · failure_rate=${fail}\n`;
}
