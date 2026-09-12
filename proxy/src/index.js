/**
 * besir API 프록시 (Cloudflare Worker)
 *
 * 목적: Kakao REST 키와 ODsay 키를 클라이언트(앱)에 노출하지 않기 위해
 * 앱은 이 Worker만 호출하고, Worker가 실제 키를 붙여 카카오/ODsay로 중계한다.
 *
 * 비밀값(wrangler secret 으로 설정, 코드/깃에 안 들어감):
 *   - KAKAO_REST_KEY : 카카오모빌리티 길찾기용 REST 키
 *   - ODSAY_KEY      : ODsay API 키
 *   - OPENAI_KEY     : OpenAI API 키 — 대화형 일정 등록(/ai/chat)의 기본 백엔드
 *   - ANTHROPIC_KEY  : Claude(Anthropic) API 키 — (구) LLM 대화형 일정 등록용, 현재 미사용
 *   - APP_TOKEN      : 앱이 보내야 하는 토큰(이게 없으면 거부). 남용 차단·식별용.
 *
 * (구) GEMINI_KEY 시크릿·Gemini 연동은 2026-09-09 제거됨: Cloudflare Worker가 전 세계
 * 여러 위치에서 실행되는데 그중 일부(데이터센터 IP 대역)를 Gemini 무료 티어가 지역과
 * 무관하게 차단해("User location is not supported") 성공률이 10~50%로 들쭉날쭉했다.
 * 지금은 **Workers AI 바인딩**(env.AI, wrangler.toml [ai])으로 대체 — Cloudflare 자체
 * 인프라에서 모델이 돌아 외부 호출 자체가 없으므로 이 문제가 구조적으로 없다. 별도 키 불필요.
 *
 * 라우트:
 *   GET  /kakao/directions?origin=lng,lat&destination=lng,lat[&priority=RECOMMEND]
 *   GET  /kakao/local/keyword?query=&size=&category_group_code=&x=&y=&radius=&sort=
 *   GET  /odsay/searchPubTransPathT?SX=&SY=&EX=&EY=
 *   GET  /odsay/loadLane?mapObject=
 *   POST /claude/messages   (본문을 Anthropic /v1/messages 로 중계, 키는 서버가 붙임)
 *   POST /ai/chat           (Gemini generateContent 형식의 본문을 받아 OpenAI로 실행하고
 *                            같은 Gemini 형식 응답으로 돌려준다 — 앱은 백엔드가 뭐든 몰라도 됨.
 *                            OPENAI_KEY가 없으면 (구) Workers AI로 자동 폴백)
 *
 * 인증: 헤더 `X-App-Token: <APP_TOKEN>` 필요.
 */

const KAKAO_DIRECTIONS = "https://apis-navi.kakaomobility.com/v1/directions";
const KAKAO_LOCAL_KEYWORD = "https://dapi.kakao.com/v2/local/search/keyword.json";
const ODSAY_BASE = "https://api.odsay.com/v1/api";
const ANTHROPIC_MESSAGES = "https://api.anthropic.com/v1/messages";
const OPENAI_RESPONSES = "https://api.openai.com/v1/responses";

// 대화형 일정 등록의 기본 모델(2026-09-12 전환).
//
// Workers AI(mistral-small-3.1-24b)에서 옮겨온 이유는 비용이 아니라 **함수 호출 신뢰도**다.
// 그 모델은 선택 인자를 빠뜨리거나(origin_query 누락 → 출발지=도착지인 0분 일정), 비워둬야 할
// 인자를 멋대로 채우거나(mode), 호출하지도 않은 도구를 호출했다고 말하는 실패가 반복됐다.
// besir의 도구는 11개에 중첩 인자를 쓰므로 이 부분이 그대로 사용자 경험이 된다.
//
// luna는 5.6 계열의 최저가 등급($0.20/$1.20, 캐시 입력 $0.02)이다. 측정된 고정 비용
// 5,804토큰/요청(시스템 1,812 + 도구 3,992) 기준 작업당 약 6원. 인자 누락이 계속 나오면
// gpt-5.6-terra($2/$12)로 올린다 — 아래 상수 한 줄만 바꾸면 된다.
const OPENAI_MODEL = "gpt-5.6-luna";

// none / low / medium(기본) / high / xhigh / max.
// 추론 토큰은 출력 단가로 과금되지만 이 워크로드에선 금액보다 응답 지연이 체감된다.
// medium에서 시작해, 인자 누락이 재발하면 high로, 대화가 답답하면 low로 조정.
//
// ⚠️ chat completions(/v1/chat/completions)가 아니라 **/v1/responses**를 쓰는 이유가 이것이다.
// 전자는 "Function tools with reasoning_effort are not supported"로 거부한다(실측 2026-09-12) —
// 도구를 쓰려면 추론을 none으로 꺼야 하는데, 인자 누락을 줄이려고 옮겨온 마당에 그건 앞뒤가 안 맞는다.
const OPENAI_REASONING_EFFORT = "medium";

// (구) Workers AI 폴백 — OPENAI_KEY 미설정 시에만 쓴다.
// 함수 호출 + 한국어 정확도 실측 확인(2026-09-09). 주의: 같은 자리에서 테스트한
// @cf/meta/llama-3.3-70b-instruct-fp8-fast는 함수 호출 인자 안의 한국어가 깨져 나왔음(제외).
const WORKERS_AI_MODEL = "@cf/mistralai/mistral-small-3.1-24b-instruct";

// ODsay 키는 도메인(Referer) 검사를 한다. ODsay 콘솔에 등록한 도메인과 맞춰 보낸다.
const ODSAY_REFERER = "https://localhost";

// 허용할 ODsay 엔드포인트(임의 경로 프록시 방지).
const ODSAY_ALLOWED = new Set(["searchPubTransPathT", "loadLane"]);

function json(status, obj) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // 헬스체크는 인증 없이 GET 허용
    if (request.method === "GET" && (path === "/" || path === "/health")) {
      return json(200, { ok: true, service: "besir-proxy" });
    }

    // 앱 토큰 검사
    const token = request.headers.get("X-App-Token");
    if (!env.APP_TOKEN || token !== env.APP_TOKEN) {
      return json(401, { error: "unauthorized" });
    }

    try {
      // Claude 대화형 일정 등록 (POST) — 구버전, 현재 앱은 Gemini 사용.
      if (path === "/claude/messages") {
        if (request.method !== "POST") {
          return json(405, { error: "method_not_allowed" });
        }
        return await proxyClaude(request, env);
      }

      // AI 대화형 일정 등록 (POST) — OpenAI 실행, Gemini 형식으로 요청/응답.
      if (path === "/ai/chat") {
        if (request.method !== "POST") {
          return json(405, { error: "method_not_allowed" });
        }
        const geminiBody = await request.json();
        return env.OPENAI_KEY
          ? await proxyOpenAI(geminiBody, env)
          : await proxyWorkersAI(geminiBody, env);
      }

      // 이하 라우트는 GET 전용
      if (request.method !== "GET") {
        return json(405, { error: "method_not_allowed" });
      }
      if (path === "/kakao/directions") {
        return await proxyKakaoDirections(url, env);
      }
      if (path === "/kakao/local/keyword") {
        return await proxyKakaoKeyword(url, env);
      }
      if (path.startsWith("/odsay/")) {
        const endpoint = path.slice("/odsay/".length);
        return await proxyOdsay(endpoint, url, env);
      }
      return json(404, { error: "not_found" });
    } catch (e) {
      return json(502, { error: "upstream_error", detail: redactSecrets(String(e), env) });
    }
  },
};

// 일부 런타임/네트워크 에러 메시지에는 요청 URL이 그대로 담겨(ODsay는 apiKey를 쿼리로 보냄)
// 클라이언트로 돌려주는 에러 상세에 시크릿이 섞여 나갈 수 있다 — 응답 전에 알려진 시크릿 값을
// 전부 지운다.
function redactSecrets(text, env) {
  let out = text;
  for (const key of ["KAKAO_REST_KEY", "ODSAY_KEY", "OPENAI_KEY", "ANTHROPIC_KEY", "APP_TOKEN"]) {
    const value = env[key];
    if (value) out = out.split(value).join("[REDACTED]");
  }
  return out;
}

// Anthropic /v1/messages 로 본문을 그대로 중계한다. API 키는 서버(시크릿)가 붙인다.
async function proxyClaude(request, env) {
  if (!env.ANTHROPIC_KEY) {
    return json(500, { error: "missing_anthropic_key" });
  }
  const body = await request.text();
  const resp = await fetch(ANTHROPIC_MESSAGES, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": env.ANTHROPIC_KEY,
      "anthropic-version": "2023-06-01",
    },
    body,
  });
  return passthrough(resp);
}

// Gemini generateContent 형식 요청 바디를 OpenAI chat completion 형식(messages/tools)으로
// 옮긴다. 앱(AIAssistant.swift)의 요청/응답 파싱 코드는 그대로 두고 백엔드만 여기서
// 갈아끼우기 위한 층이다 — 백엔드를 바꿔도 앱은 안 건드린다.
function toOpenAIRequest(geminiBody) {
  const messages = [];

  const systemText = (geminiBody.system_instruction?.parts || []).map((p) => p.text || "").join("\n");
  if (systemText) messages.push({ role: "system", content: systemText });

  // tool_call id는 대화 **전체**에서 유일해야 한다. 턴마다 0부터 다시 세면 여러 턴이 쌓인
  // 히스토리에서 같은 id가 반복돼 assistant 턴 ↔ tool 턴 짝이 모호해진다.
  // 도구 결과는 호출과 같은 순서로 바로 뒤따라오므로, 발급한 id를 큐에 넣고 순서대로 꺼내 쓴다.
  let seq = 0;
  const pendingIds = [];

  for (const c of geminiBody.contents || []) {
    const parts = c.parts || [];
    if (c.role === "model") {
      const text = parts.filter((p) => p.text).map((p) => p.text).join("\n");
      const toolCalls = parts
        .filter((p) => p.functionCall)
        .map((p) => {
          const id = toolCallId(seq++);
          pendingIds.push(id);
          return {
            id,
            type: "function",
            function: { name: p.functionCall.name, arguments: JSON.stringify(p.functionCall.args || {}) },
          };
        });
      messages.push({ role: "assistant", content: text || null, tool_calls: toolCalls.length ? toolCalls : undefined });
    } else if (c.role === "function") {
      parts
        .filter((p) => p.functionResponse)
        .forEach((p) => {
          const id = pendingIds.shift() || toolCallId(seq++);
          messages.push({ role: "tool", tool_call_id: id, content: JSON.stringify(p.functionResponse.response || {}) });
        });
    } else {
      const content = [];
      for (const p of parts) {
        if (p.text) content.push({ type: "text", text: p.text });
        if (p.inlineData) {
          content.push({ type: "image_url", image_url: { url: `data:${p.inlineData.mimeType};base64,${p.inlineData.data}` } });
        }
      }
      messages.push({ role: "user", content: content.length === 1 && content[0].type === "text" ? content[0].text : content });
    }
  }

  const geminiTools = geminiBody.tools?.[0]?.functionDeclarations || [];
  const tools = geminiTools.length
    ? geminiTools.map((fd) => ({
        type: "function",
        function: { name: fd.name, description: fd.description, parameters: lowercaseSchemaTypes(fd.parameters) },
      }))
    : undefined;

  return { messages, tools };
}

// Gemini generateContent 형식 → OpenAI Responses 형식(instructions/input/tools).
//
// chat completions와 모양이 꽤 다르다: 대화가 messages가 아니라 **평평한 input 아이템 배열**이고,
// 도구 호출·결과가 role이 아니라 각각 function_call / function_call_output 아이템으로 들어간다.
function toResponsesRequest(geminiBody) {
  const instructions = (geminiBody.system_instruction?.parts || []).map((p) => p.text || "").join("\n");
  const input = [];

  // call_id는 대화 전체에서 유일해야 하고, 결과 아이템이 호출 아이템과 같은 값을 참조해야 한다.
  // 도구 결과는 호출과 같은 순서로 뒤따라오므로 발급한 id를 큐에 넣고 순서대로 꺼내 쓴다.
  let seq = 0;
  const pendingIds = [];

  for (const c of geminiBody.contents || []) {
    const parts = c.parts || [];
    if (c.role === "model") {
      const text = parts.filter((p) => p.text).map((p) => p.text).join("\n");
      if (text) input.push({ role: "assistant", content: [{ type: "output_text", text }] });
      for (const p of parts.filter((x) => x.functionCall)) {
        const callId = toolCallId(seq++);
        pendingIds.push(callId);
        input.push({
          type: "function_call",
          call_id: callId,
          name: p.functionCall.name,
          arguments: JSON.stringify(p.functionCall.args || {}),
        });
      }
    } else if (c.role === "function") {
      for (const p of parts.filter((x) => x.functionResponse)) {
        input.push({
          type: "function_call_output",
          call_id: pendingIds.shift() || toolCallId(seq++),
          output: JSON.stringify(p.functionResponse.response || {}),
        });
      }
    } else {
      const content = [];
      for (const p of parts) {
        if (p.text) content.push({ type: "input_text", text: p.text });
        if (p.inlineData) {
          content.push({ type: "input_image", image_url: `data:${p.inlineData.mimeType};base64,${p.inlineData.data}` });
        }
      }
      if (content.length) input.push({ role: "user", content });
    }
  }

  const geminiTools = geminiBody.tools?.[0]?.functionDeclarations || [];
  // Responses의 function 도구는 name/description/parameters가 중첩 없이 평평하게 온다.
  const tools = geminiTools.map((fd) => ({
    type: "function",
    name: fd.name,
    description: fd.description,
    parameters: lowercaseSchemaTypes(fd.parameters),
  }));

  return { instructions, input, tools };
}

// 기본 백엔드. 키는 서버(시크릿)가 붙이고 앱에는 나가지 않는다.
async function proxyOpenAI(geminiBody, env) {
  const { instructions, input, tools } = toResponsesRequest(geminiBody);
  // ⚠️ 임시 캡처(2026-09-12) — 실제 앱이 보내는 프롬프트·툴 선언을 한 번 떠서
  //    테스트 하네스를 만들기 위한 것. 캡처 끝나면 이 블록을 지운다.
  console.log("BESIR_CAPTURE " + JSON.stringify({ instructions, tools, input }));
  const resp = await fetch(OPENAI_RESPONSES, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${env.OPENAI_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      reasoning: { effort: OPENAI_REASONING_EFFORT },
      ...(instructions ? { instructions } : {}),
      input,
      ...(tools.length ? { tools } : {}),
      // 개인 앱의 일정·위치가 오가므로 OpenAI 쪽에 대화를 남기지 않는다.
      // (대신 추론 내용이 턴을 넘어 이어지지 않는다 — 이 워크로드에선 한 턴 안에서 끝나는 판단이라 무관.)
      store: false,
    }),
  });

  const text = await resp.text();
  if (!resp.ok) {
    // 앱은 200 + Gemini 모양만 파싱하므로 실패는 그대로 실패로 돌린다.
    // 다만 상세를 실어 보내야 쿼터 초과·모델명 오타 같은 원인이 구분된다(시크릿은 지우고).
    return json(resp.status, { error: "openai_error", detail: redactSecrets(text, env) });
  }
  return json(200, responsesToGeminiShape(JSON.parse(text)));
}

// OpenAI Responses 응답 → Gemini generateContent 응답 모양.
// output 배열에는 reasoning 아이템도 섞여 오는데 앱이 쓸 게 없으므로 버린다.
function responsesToGeminiShape(result) {
  const parts = [];
  for (const item of result.output || []) {
    if (item.type === "message") {
      for (const c of item.content || []) {
        if (c.type === "output_text" && c.text) parts.push({ text: c.text });
      }
    } else if (item.type === "function_call") {
      let args = {};
      try {
        args = JSON.parse(item.arguments);
      } catch (e) {
        /* 인자 파싱 실패 시 빈 객체로(앱 쪽에서 필수 필드 누락으로 처리됨) */
      }
      parts.push({ functionCall: { name: item.name, args } });
    }
  }
  return { candidates: [{ content: { parts, role: "model" }, finishReason: "STOP" }] };
}

// (구) 폴백 백엔드 — OPENAI_KEY가 없을 때만 탄다.
// ⚠️ luna 검증이 끝나면 이 함수와 toOpenAIRequest, WORKERS_AI_MODEL, wrangler.toml의 [ai]
//    바인딩을 함께 지운다. 지금은 luna와 비교할 기준선으로만 남겨둔 것이다.
async function proxyWorkersAI(geminiBody, env) {
  const { messages, tools } = toOpenAIRequest(geminiBody);
  const result = await env.AI.run(WORKERS_AI_MODEL, { messages, tools });
  return json(200, toGeminiShape(result));
}

// 일부 Workers AI 모델(예: mistral-small-3.1)은 tool_call id를 "영숫자 9자"로 강제한다.
// OpenAI는 제약이 없지만 두 백엔드가 같은 변환을 쓰도록 좁은 쪽에 맞춰 둔다.
function toolCallId(i) {
  return "tc" + String(i).padStart(7, "0");
}

// Workers AI(OpenAI 호환) 응답 → Gemini generateContent 응답 모양으로 변환.
function toGeminiShape(result) {
  const msg = result.choices?.[0]?.message || {};
  const parts = [];
  if (msg.content) parts.push({ text: msg.content });
  for (const tc of msg.tool_calls || []) {
    let args = {};
    try {
      args = JSON.parse(tc.function.arguments);
    } catch (e) {
      /* 인자 파싱 실패 시 빈 객체로(앱 쪽에서 필수 필드 누락으로 처리됨) */
    }
    parts.push({ functionCall: { name: tc.function.name, args } });
  }
  return { candidates: [{ content: { parts, role: "model" }, finishReason: "STOP" }] };
}

// Gemini 툴 스키마는 type을 대문자(STRING/OBJECT 등)로 쓰는데 OpenAI 호환 스키마는 소문자를 쓴다.
function lowercaseSchemaTypes(schema) {
  if (!schema || typeof schema !== "object") return schema;
  if (Array.isArray(schema)) return schema.map(lowercaseSchemaTypes);
  const out = {};
  for (const [k, v] of Object.entries(schema)) {
    out[k] = k === "type" && typeof v === "string" ? v.toLowerCase() : lowercaseSchemaTypes(v);
  }
  return out;
}

async function proxyKakaoDirections(url, env) {
  const origin = url.searchParams.get("origin");
  const destination = url.searchParams.get("destination");
  if (!origin || !destination) {
    return json(400, { error: "missing_params", need: ["origin", "destination"] });
  }
  const priority = url.searchParams.get("priority") || "RECOMMEND";
  const target = new URL(KAKAO_DIRECTIONS);
  target.searchParams.set("origin", origin);
  target.searchParams.set("destination", destination);
  target.searchParams.set("priority", priority);

  const resp = await fetch(target.toString(), {
    headers: { Authorization: `KakaoAK ${env.KAKAO_REST_KEY}` },
  });
  return passthrough(resp);
}

// 카카오 로컬 키워드 검색에서 그대로 넘겨줄 파라미터.
// 좌표(x,y)+radius+category_group_code 조합이 "목적지 주변 음식점(FD6)" 검색에 쓰인다.
const KAKAO_LOCAL_PASSTHROUGH = ["category_group_code", "x", "y", "radius", "sort", "page"];

async function proxyKakaoKeyword(url, env) {
  const query = url.searchParams.get("query");
  if (!query) {
    return json(400, { error: "missing_params", need: ["query"] });
  }
  const target = new URL(KAKAO_LOCAL_KEYWORD);
  target.searchParams.set("query", query);
  target.searchParams.set("size", url.searchParams.get("size") || "10");
  for (const key of KAKAO_LOCAL_PASSTHROUGH) {
    const value = url.searchParams.get(key);
    if (value) target.searchParams.set(key, value);
  }

  const resp = await fetch(target.toString(), {
    headers: { Authorization: `KakaoAK ${env.KAKAO_REST_KEY}` },
  });
  return passthrough(resp);
}

async function proxyOdsay(endpoint, url, env) {
  if (!ODSAY_ALLOWED.has(endpoint)) {
    return json(404, { error: "endpoint_not_allowed", endpoint });
  }
  const target = new URL(`${ODSAY_BASE}/${endpoint}`);
  // 클라이언트가 보낸 쿼리를 그대로 넘기되 apiKey 는 서버가 붙인다.
  for (const [k, v] of url.searchParams) {
    if (k.toLowerCase() === "apikey") continue;
    target.searchParams.set(k, v);
  }
  target.searchParams.set("apiKey", env.ODSAY_KEY);

  const resp = await fetch(target.toString(), {
    headers: { Referer: ODSAY_REFERER },
  });
  return passthrough(resp);
}

// 업스트림 응답 본문/상태를 그대로 전달(JSON 가정).
async function passthrough(resp) {
  const body = await resp.text();
  return new Response(body, {
    status: resp.status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

// 아래는 test/convert.test.mjs 전용 내보내기다.
// Cloudflare Workers는 default export만 핸들러로 쓰므로 런타임 동작에는 영향이 없다.
export { toResponsesRequest, responsesToGeminiShape, toOpenAIRequest, toGeminiShape, lowercaseSchemaTypes };
