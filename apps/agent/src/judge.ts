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
}): Promise<Verdict[]> {
  const { model, transcript, rubrics } = opts;
  const { object } = await generateObject({
    model,
    schema: verdictSchema,
    prompt: `You are grading a journaling-assistant conversation against rubrics.
For EACH rubric, decide pass/fail for the assistant's behavior in the transcript
and give a one-sentence reason. Return one verdict per rubric, in order.

Rubrics:
${rubrics.map((r, i) => `${i + 1}. ${r}`).join("\n")}

Transcript:
${transcript}`,
  });
  return object.verdicts;
}
