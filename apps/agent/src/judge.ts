import { generateObject, type LanguageModel } from "ai";
import { z } from "zod";

const verdictSchema = z.object({
  verdicts: z.array(
    z.object({
      rubric: z.string(),
      pass: z.boolean(),
      reason: z.string(),
    }),
  ),
});

export type Verdict = z.infer<typeof verdictSchema>["verdicts"][number];

/** One structured judge call covering every rubric for a session transcript. */
export async function judgeSession(opts: {
  model: LanguageModel;
  transcript: string;
  rubrics: string[];
  /** What the assistant was supposed to do — e.g. the question set. */
  context?: string;
}): Promise<Verdict[]> {
  const { model, transcript, rubrics, context } = opts;
  const { object } = await generateObject({
    model,
    schema: verdictSchema,
    // Deterministic grading: the judge must not be a second source of variance.
    temperature: 0,
    prompt: `You are grading a journaling-assistant conversation against rubrics.
For EACH rubric, decide pass/fail for the assistant's behavior in the transcript
and give a one-sentence reason. Return one verdict per rubric, in order.
${context ? `\nSession setup:\n${context}\n` : ""}
Rubrics:
${rubrics.map((r, i) => `${i + 1}. ${r}`).join("\n")}

Transcript:
${transcript}`,
  });
  return object.verdicts;
}
