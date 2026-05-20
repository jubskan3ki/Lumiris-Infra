import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE = __ENV.BASE || 'http://localhost:3001';

export const options = {
    scenarios: {
        busy_day: {
            executor: 'constant-vus',
            vus: 15,
            duration: '3m',
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.02'],
        http_req_duration: ['p(95)<1200'],
        'http_req_duration{group:::dashboard}': ['p(95)<900'],
        checks: ['rate>0.98'],
    },
};

const SECTIONS = ['/', '/audits', '/certificates', '/journal'];

export default function () {
    group('dashboard', () => {
        const res = http.get(`${BASE}/`);
        check(res, {
            'dashboard up': (r) => r.status === 200,
        });
    });

    group('section_walkthrough', () => {
        for (const path of SECTIONS) {
            const res = http.get(`${BASE}${path}`);
            check(res, { 'section reachable': (r) => r.status < 500 });
            sleep(0.4 + Math.random() * 0.6);
        }
    });

    sleep(1);
}

export function handleSummary(data) {
    return {
        'bench/out/audit.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data),
    };
}

function textSummary(data) {
    const m = data.metrics;
    const p95 = m.http_req_duration?.values?.['p(95)']?.toFixed(1) ?? 'n/a';
    const fail = m.http_req_failed?.values?.rate?.toFixed(4) ?? 'n/a';
    return `\n[audit] p95=${p95}ms · failure_rate=${fail}\n`;
}
