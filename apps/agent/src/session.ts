import {
  type Answer,
  type AnswerType,
  type AskQuestionInput,
  askQuestionInput,
  completeSessionInput,
  recordAnswerInput,
} from "@emotely/contract";
import {
  generateText,
  isStepCount,
  type JSONValue,
  type LanguageModel,
  type LanguageModelUsage,
  type ModelMessage,
  tool,
} from "ai";
import type { TokenUsage } from "./cost.ts";
import { resolvePrompt } from "./session-prompt.ts";
import { PRIVACY_TELEMETRY } from "./telemetry.ts";

type ListAnswerType = Extract<AnswerType, "color" | "emoji" | "text_list">;
type ScalarAnswerType = Exclude<AnswerType, ListAnswerType>;

// Union on answer_type so min_answers only exists where the value is a list.
export type Question = { id: string; text: string } & (
  | { answer_type: ScalarAnswerType; min_answers?: never }
  | { answer_type: ListAnswerType; min_answers?: number }
);

export type QuestionSet = {
  id: string;
  name: string;
  questions: Question[];
};

export type SessionClient = {
  /** Answer an ask_question tool call with the raw widget value. */
  askQuestion: (input: AskQuestionInput) => Promise<JSONValue>;
};

export type SessionResult = {
  summary: string;
  answers: Record<string, Answer>;
  /** Token totals across every model round, for cost accounting. */
  usage: TokenUsage;
  /** The full conversation, for eval transcripts and debugging. */
  messages: ModelMessage[];
  /** Version id of the system prompt this session ran with. */
  promptId: string;
  /** Wall-clock ms per model round — what the user waits between widgets. */
  roundLatenciesMs: number[];
};

// ponytail: generous cap — a poweruser recording 20 gratitudes must never hit
// it; tighten with real usage data once PostHog is wired (issue #5).
const MAX_ROUNDS_PER_QUESTION = 6;
const ROUND_SLACK = 20;

function buildSessionTools(
  questionSet: QuestionSet,
  answers: SessionResult["answers"],
  asked: Set<string>,
  onComplete: (summary: string) => void,
) {
  return {
    ask_question: tool({
      description:
        "Ask the user one journaling question; the client renders the widget.",
      inputSchema: askQuestionInput,
      // no execute: client-side tool — the session loop supplies the result
    }),
    record_answer: tool({
      description: "Record the validated answer for one question.",
      inputSchema: recordAnswerInput,
      execute: async ({ question_id, answer }) => {
        const question = questionSet.questions.find(
          (q) => q.id === question_id,
        );
        const min = question?.min_answers ?? 1;
        if (Array.isArray(answer.value) && answer.value.length < min) {
          return {
            recorded: false,
            error: `This question needs at least ${min} answers.`,
          };
        }
        answers[question_id] = answer;
        return { recorded: true };
      },
    }),
    complete_session: tool({
      description: "Finish the session with a summary of the journal entry.",
      inputSchema: completeSessionInput,
      execute: async ({ summary }) => {
        // Models tend to skip record_answer for the final question; an asked
        // question without a recorded answer is a lost answer, so refuse.
        const unrecorded = [...asked].filter((id) => !(id in answers));
        if (unrecorded.length > 0) {
          return {
            completed: false,
            error: `Record the answer for ${unrecorded.join(", ")} with record_answer before completing.`,
          };
        }
        onComplete(summary);
        return { completed: true };
      },
    }),
  };
}

function emptyUsage(): TokenUsage {
  return { inputTokens: 0, cacheReadTokens: 0, outputTokens: 0 };
}

function addUsage(total: TokenUsage, step: LanguageModelUsage): void {
  total.inputTokens += step.inputTokens ?? 0;
  total.cacheReadTokens += step.inputTokenDetails.cacheReadTokens ?? 0;
  total.outputTokens += step.outputTokens ?? 0;
}

/** Client-executed tool: the client answers ask_question with the widget value. */
async function answerAskQuestion(
  call: { toolCallId: string; toolName: string; input: unknown },
  client: SessionClient,
  asked: Set<string>,
): Promise<ModelMessage> {
  const input = call.input as AskQuestionInput;
  asked.add(input.question_id);
  const value = await client.askQuestion(input);
  return {
    role: "tool",
    content: [
      {
        type: "tool-result",
        toolCallId: call.toolCallId,
        toolName: call.toolName,
        output: { type: "json", value: { answer: value } },
      },
    ],
  };
}

/** Generous round cap so a model that never completes cannot loop forever. */
function roundGuard(questionSet: QuestionSet): { next: () => void } {
  const maxRounds =
    questionSet.questions.length * MAX_ROUNDS_PER_QUESTION + ROUND_SLACK;
  let rounds = 0;
  return {
    next: () => {
      if (++rounds > maxRounds) {
        throw new Error(
          `Session round limit reached (${maxRounds}) without complete_session.`,
        );
      }
    },
  };
}

const SESSION_TELEMETRY = {
  ...PRIVACY_TELEMETRY,
  includeRuntimeContext: { distinctId: true, sessionId: true, promptId: true },
} as const;

export async function runSession(opts: {
  questionSet: QuestionSet;
  client: SessionClient;
  model: LanguageModel;
  /** Sampling temperature; evals pin 0 for stability, product uses default. */
  temperature?: number;
  /** Joins spans to a person + session in PostHog; absent = anonymous. */
  attribution?: { distinctId: string; sessionId: string };
  /** Prompt version to run (flag payload); unknown ids fall back to current. */
  promptId?: string;
}): Promise<SessionResult> {
  const { questionSet, client, model, temperature, attribution } = opts;
  const prompt = resolvePrompt(opts.promptId);
  const answers: SessionResult["answers"] = {};
  const asked = new Set<string>();
  const roundLatenciesMs: number[] = [];
  const usage = emptyUsage();
  let summary: string | undefined;

  const tools = buildSessionTools(questionSet, answers, asked, (s) => {
    summary = s;
  });

  const messages: ModelMessage[] = [
    { role: "user", content: "I am ready to start my journaling session." },
  ];

  const guard = roundGuard(questionSet);

  while (summary === undefined) {
    guard.next();
    const startedAt = performance.now();
    const result = await generateText({
      model,
      instructions: prompt.build(questionSet),
      tools,
      stopWhen: isStepCount(1),
      ...(temperature === undefined ? {} : { temperature }),
      ...(attribution === undefined
        ? {}
        : { runtimeContext: { ...attribution, promptId: prompt.id } }),
      telemetry: SESSION_TELEMETRY,
      messages,
    });
    roundLatenciesMs.push(performance.now() - startedAt);
    messages.push(...result.response.messages);
    addUsage(usage, result.usage);

    if (result.finishReason !== "tool-calls") {
      continue;
    }

    for (const call of result.toolCalls) {
      if (call.toolName === "ask_question") {
        messages.push(await answerAskQuestion(call, client, asked));
      }
    }
  }

  return {
    summary,
    answers,
    usage,
    messages,
    promptId: prompt.id,
    roundLatenciesMs,
  };
}
