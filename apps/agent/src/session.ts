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

export type Question = {
  id: string;
  text: string;
  answer_type: AnswerType;
  min_answers?: number;
};

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
};

const systemPrompt = (set: QuestionSet) =>
  `You are a journaling assistant. Walk the user through these questions in order using the ask_question tool, record each answer with record_answer, then call complete_session with a summary of the user's day.

Questions:
${set.questions.map((q) => `${q.id}: ${q.text} (answer_type: ${q.answer_type}${q.min_answers ? `, at least ${q.min_answers} answers` : ""})`).join("\n")}`;

export async function runSession(opts: {
  questionSet: QuestionSet;
  client: SessionClient;
  model: LanguageModel;
}): Promise<SessionResult> {
  const { questionSet, client, model } = opts;
  const answers: SessionResult["answers"] = {};
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
      system: systemPrompt(questionSet),
      tools,
      stopWhen: isStepCount(1),
      messages,
    });
    messages.push(...result.response.messages);

    if (result.finishReason === "tool-calls") {
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
  }

  return { summary, answers };
}
