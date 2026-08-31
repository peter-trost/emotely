import type { AnswerType } from "@emotely/contract";
import { MockLanguageModelV4 } from "ai/test";

type ScriptStep =
  | { ask: { questionId: string; question: string; answerType: AnswerType } }
  | { record: { questionId: string; answerType: AnswerType; value: unknown } }
  | { complete: string };

function stepContent(step: ScriptStep | undefined, nextId: () => string) {
  if (step === undefined) {
    return [{ type: "text" as const, text: "Done." }];
  }
  if ("ask" in step) {
    return [
      {
        type: "tool-call" as const,
        toolCallId: nextId(),
        toolName: "ask_question",
        input: JSON.stringify({
          question_id: step.ask.questionId,
          question: step.ask.question,
          answer_type: step.ask.answerType,
        }),
      },
    ];
  }
  if ("record" in step) {
    return [
      {
        type: "tool-call" as const,
        toolCallId: nextId(),
        toolName: "record_answer",
        input: JSON.stringify({
          question_id: step.record.questionId,
          answer: {
            answer_type: step.record.answerType,
            value: step.record.value,
          },
        }),
      },
    ];
  }
  return [
    {
      type: "tool-call" as const,
      toolCallId: nextId(),
      toolName: "complete_session",
      input: JSON.stringify({ summary: step.complete }),
    },
  ];
}

/** Mock model that emits one scripted tool call per round, then final text. */
export function scriptedSessionModel(steps: ScriptStep[]): MockLanguageModelV4 {
  const queue: ScriptStep[] = [...steps];
  let callId = 0;
  return new MockLanguageModelV4({
    doGenerate: async () => {
      const step = queue.shift();
      const content = stepContent(step, () => `c${++callId}`);
      const isToolCall = content.some((c) => c.type === "tool-call");
      return {
        content,
        finishReason: {
          unified: isToolCall ? ("tool-calls" as const) : ("stop" as const),
          raw: undefined,
        },
        usage: {
          inputTokens: {
            total: 7,
            noCache: 7,
            cacheRead: undefined,
            cacheWrite: undefined,
          },
          outputTokens: { total: 3, text: 3, reasoning: undefined },
        },
        warnings: [],
      };
    },
  });
}
