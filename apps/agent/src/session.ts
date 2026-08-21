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
  type ModelMessage,
  tool,
} from "ai";
import { PROMPT_ID, sessionPrompt } from "./session-prompt.ts";

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
  askQuestion(input: AskQuestionInput): Promise<JSONValue>;
};

export type SessionResult = {
  summary: string;
  answers: Record<string, Answer>;
  /** Token totals across every model round, for cost accounting. */
  usage: { inputTokens: number; outputTokens: number };
  /** The full conversation, for eval transcripts and debugging. */
  messages: ModelMessage[];
  /** Version id of the system prompt this session ran with. */
  promptId: string;
};

export async function runSession(opts: {
  questionSet: QuestionSet;
  client: SessionClient;
  model: LanguageModel;
  /** Sampling temperature; evals pin 0 for stability, product uses default. */
  temperature?: number;
}): Promise<SessionResult> {
  const { questionSet, client, model, temperature } = opts;
  const answers: SessionResult["answers"] = {};
  const usage = { inputTokens: 0, outputTokens: 0 };
  let summary: string | undefined;

  const tools = {
    ask_question: tool({
      description:
        "Ask the user one journaling question; the client renders the widget.",
      inputSchema: askQuestionInput,
      // no execute: client-side tool — the loop below supplies the result
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
      execute: async (input) => {
        summary = input.summary;
        return { completed: true };
      },
    }),
  };

  const messages: ModelMessage[] = [
    { role: "user", content: "I am ready to start my journaling session." },
  ];

  // ponytail: generous cap — a poweruser recording 20 gratitudes must never hit it;
  // tighten with real usage data once PostHog is wired (issue #5).
  const maxRounds = questionSet.questions.length * 6 + 20;
  let rounds = 0;

  while (summary === undefined) {
    if (++rounds > maxRounds) {
      throw new Error(
        `Session round limit reached (${maxRounds}) without complete_session.`,
      );
    }
    const result = await generateText({
      model,
      instructions: sessionPrompt(questionSet),
      tools,
      stopWhen: isStepCount(1),
      temperature,
      messages,
    });
    messages.push(...result.response.messages);
    usage.inputTokens += result.totalUsage.inputTokens ?? 0;
    usage.outputTokens += result.totalUsage.outputTokens ?? 0;

    if (result.finishReason !== "tool-calls") continue;

    for (const call of result.toolCalls) {
      if (call.toolName !== "ask_question") continue;
      const value = await client.askQuestion(call.input as AskQuestionInput);
      messages.push({
        role: "tool",
        content: [
          {
            type: "tool-result",
            toolCallId: call.toolCallId,
            toolName: call.toolName,
            output: { type: "json", value: { answer: value } },
          },
        ],
      });
    }
  }

  return { summary, answers, usage, messages, promptId: PROMPT_ID };
}
