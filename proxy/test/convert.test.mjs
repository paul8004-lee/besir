// Gemini 형식 ↔ 백엔드 형식 변환 테스트.
//
// 이 층이 조용히 깨지면 앱에서는 "처리 중 문제가 생겼어요"로만 보여 원인을 찾기 어렵다.
// 특히 도구 호출 id 짝맞춤은 대화가 몇 턴 쌓여야 드러나서 손으로는 잘 안 잡힌다.
//
// 실행: npm test   (프록시 배포 전에 돌릴 것)

import { toResponsesRequest, responsesToGeminiShape } from "../src/index.js";
import assert from "node:assert";

// 2턴짜리 히스토리: user → model(도구호출) → function(결과) → model(텍스트+도구호출) → function(결과) → user(+이미지)
function sampleBody() {
  return {
    system_instruction: { parts: [{ text: "너는 besir 비서다." }] },
    contents: [
      { role: "user", parts: [{ text: "내일 3시 강남역" }] },
      { role: "model", parts: [{ functionCall: { name: "check_travel_time", args: { destination_query: "강남역" } } }] },
      { role: "function", parts: [{ functionResponse: { name: "check_travel_time", response: { car: 50 } } }] },
      { role: "model", parts: [{ text: "등록할게요" }, { functionCall: { name: "create_schedule", args: { title: "약속" } } }] },
      { role: "function", parts: [{ functionResponse: { name: "create_schedule", response: { ok: true } } }] },
      { role: "user", parts: [{ text: "고마워" }, { inlineData: { mimeType: "image/jpeg", data: "AAAA" } }] },
    ],
    tools: [{ functionDeclarations: [{
      name: "create_schedule",
      description: "d",
      parameters: { type: "OBJECT", properties: { title: { type: "STRING" } }, required: ["title"] },
    }] }],
  };
}

const tests = [];
function test(name, fn) { tests.push([name, fn]); }

// ── OpenAI Responses (유일한 백엔드) ─────────────────────────────────────────

test("system은 instructions로 빠지고 input에는 안 들어간다", () => {
  const { instructions, input } = toResponsesRequest(sampleBody());
  assert.equal(instructions, "너는 besir 비서다.");
  assert.ok(!input.some((i) => i.role === "system"));
});

test("call_id가 대화 전체에서 유일하고 호출↔결과가 순서대로 짝지어진다", () => {
  const { input } = toResponsesRequest(sampleBody());
  const calls = input.filter((i) => i.type === "function_call").map((i) => i.call_id);
  const outs = input.filter((i) => i.type === "function_call_output").map((i) => i.call_id);
  assert.equal(new Set(calls).size, calls.length, "중복 call_id");
  assert.deepEqual(outs, calls, "호출 id와 결과 id 불일치");
  assert.deepEqual(calls, ["tc0000000", "tc0000001"]);
});

test("텍스트+도구호출이 섞인 model 턴은 아이템 두 개로 쪼개지되 순서는 유지된다", () => {
  const { input } = toResponsesRequest(sampleBody());
  const idxText = input.findIndex((i) => i.role === "assistant" && i.content?.[0]?.text === "등록할게요");
  const idxCall = input.findIndex((i) => i.type === "function_call" && i.name === "create_schedule");
  assert.ok(idxText >= 0 && idxCall === idxText + 1, "텍스트 뒤에 도구호출이 와야 함");
});

test("첨부 이미지는 input_image, 본문은 input_text", () => {
  const { input } = toResponsesRequest(sampleBody());
  const last = input[input.length - 1];
  assert.equal(last.role, "user");
  assert.deepEqual(last.content.map((c) => c.type), ["input_text", "input_image"]);
  assert.equal(last.content[1].image_url, "data:image/jpeg;base64,AAAA");
});

test("도구 스키마는 평평하게 펴지고 type이 소문자가 된다", () => {
  const { tools } = toResponsesRequest(sampleBody());
  assert.equal(tools[0].name, "create_schedule");
  assert.equal(tools[0].parameters.type, "object");
  assert.equal(tools[0].parameters.properties.title.type, "string");
  assert.ok(!("function" in tools[0]), "chat completions식 중첩이 남아있음");
});

test("응답 역변환: reasoning 아이템은 버리고 나머지 순서는 유지", () => {
  const g = responsesToGeminiShape({
    output: [
      { type: "reasoning", summary: [] },
      { type: "message", content: [{ type: "output_text", text: "네" }] },
      { type: "function_call", call_id: "x", name: "f", arguments: '{"a":1}' },
    ],
  });
  assert.deepEqual(g.candidates[0].content.parts, [{ text: "네" }, { functionCall: { name: "f", args: { a: 1 } } }]);
});

test("인자 JSON이 깨져도 던지지 않고 빈 인자로 넘긴다", () => {
  const g = responsesToGeminiShape({ output: [{ type: "function_call", name: "f", arguments: "{oops" }] });
  assert.deepEqual(g.candidates[0].content.parts, [{ functionCall: { name: "f", args: {} } }]);
});

// (구) Workers AI 폴백 섹션은 2026-09-13 제거 — 폴백 백엔드 자체가 없어졌다.

// ── 실행 ────────────────────────────────────────────────────────────────────

let failed = 0;
for (const [name, fn] of tests) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
  } catch (e) {
    failed++;
    console.log(`  ✗ ${name}\n    ${e.message}`);
  }
}
console.log(`\n${tests.length - failed}/${tests.length} 통과`);
process.exit(failed ? 1 : 0);
