# besir API 프록시 (Cloudflare Worker)

Kakao REST 키와 ODsay 키를 앱에 노출하지 않기 위한 중계 서버.
앱은 이 Worker만 호출하고, Worker가 실제 키를 붙여 카카오/ODsay로 요청한다.

## 로컬 개발

```bash
cd proxy
npm install
npx wrangler dev          # http://127.0.0.1:8787 에서 실행
```

`.dev.vars`(gitignore됨)에서 KAKAO_REST_KEY / ODSAY_KEY / APP_TOKEN 을 읽는다.

테스트:

```bash
TOKEN=$(grep APP_TOKEN .dev.vars | cut -d= -f2)
curl -H "X-App-Token: $TOKEN" \
  "http://127.0.0.1:8787/kakao/directions?origin=127.0276,37.4979&destination=127.0286,37.5896"
```

## 배포 (네 Cloudflare 계정 필요)

```bash
cd proxy
npx wrangler login                    # 브라우저로 Cloudflare 로그인
npx wrangler secret put KAKAO_REST_KEY # 값 입력
npx wrangler secret put ODSAY_KEY
npx wrangler secret put APP_TOKEN
npx wrangler deploy                   # → https://besir-proxy.<계정>.workers.dev
```

배포되면 앱 설정의 "프록시 URL"에 그 주소를 넣는다.

## 남용 방지(앱스토어 배포 전 권장)

- 코드의 `X-App-Token` 검사가 1차 방어선.
- 추가로 Cloudflare 대시보드 ▸ Security ▸ WAF ▸ Rate limiting rules 에서
  IP당 분당 요청 수 제한을 코드 없이 걸 수 있다.

## 라우트

| 경로 | 중계 대상 |
|---|---|
| `GET /kakao/directions?origin=lng,lat&destination=lng,lat` | 카카오모빌리티 길찾기 |
| `GET /odsay/searchPubTransPathT?SX=&SY=&EX=&EY=` | ODsay 대중교통 경로 |
| `GET /odsay/loadLane?mapObject=` | ODsay 경로 좌표 |

모든 요청에 헤더 `X-App-Token: <APP_TOKEN>` 필요.
