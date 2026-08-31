import {
  type Answer,
  type AskQuestionInput,
  askQuestionInput,
  recordAnswerInput,
} from "@emotely/contract";
import type { ModelMessage } from "ai";

export type PendingQuestion = { toolCallId: string; input: AskQuestionInput };

type AssistantToolCall = {
  type: "tool-call";
  toolCallId: string;
  toolName: string;
  input: unknown;
};

function noteToolCall(
  part: AssistantToolCall,
  state: {
    answers: Record<string, Answer>;
    asked: Set<string>;
    setPending: (p: PendingQuestion) => void;
  },
): void {
  if (part.toolName === "ask_question") {
    const input = askQuestionInput.safeParse(part.input);
    if (input.success) {
      state.asked.add(input.data.question_id);
      state.setPending({ toolCallId: part.toolCallId, input: input.data });
    }
  } else if (part.toolName === "record_answer") {
    const input = recordAnswerInput.safeParse(part.input);
    if (input.success) {
      state.answers[input.data.question_id] = input.data.answer;
    }
  }
}

/** Rebuild recorded answers + asked questions from the transcript alone. */
export function replayTranscript(messages: ModelMessage[]): {
  answers: Record<string, Answer>;
  asked: Set<string>;
  pending: PendingQuestion | undefined;
} {
  const answers: Record<string, Answer> = {};
  const asked = new Set<string>();
  let pending: PendingQuestion | undefined;

  for (const message of messages) {
    if (typeof message.content === "string") {
      continue;
    }
    for (const part of message.content) {
      if (message.role === "assistant" && part.type === "tool-call") {
        noteToolCall(part, {
          answers,
          asked,
          setPending: (p) => {
            pending = p;
          },
        });
      } else if (
        message.role === "tool" &&
        part.type === "tool-result" &&
        part.toolCallId === pending?.toolCallId
      ) {
        // Positional: a result only settles the ask that precedes it, so a
        // model reusing tool-call ids cannot confuse the pending state.
        pending = undefined;
      }
    }
  }
  return { answers, asked, pending };
}
