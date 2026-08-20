import { z } from 'zod';

const nonemptyString = z.string().min(1);

export const answerValueSchemas = {
  color: z.array(z.string().regex(/^#[0-9A-Fa-f]{6}$/)).nonempty(),
  emoji: z.array(nonemptyString).nonempty(),
  longtext: nonemptyString,
  rating: z.int().min(1).max(10),
  text_list: z.array(nonemptyString).nonempty(),
};

export const answerTypes = ['color', 'emoji', 'longtext', 'rating', 'text_list'] as const;
export type AnswerType = (typeof answerTypes)[number];

const answerVariant = <T extends AnswerType>(t: T) =>
  z.object({
    question_id: nonemptyString,
    answer_type: z.literal(t),
    value: answerValueSchemas[t],
  });

export const recordAnswerInput = z.discriminatedUnion('answer_type', [
  answerVariant('color'),
  answerVariant('emoji'),
  answerVariant('longtext'),
  answerVariant('rating'),
  answerVariant('text_list'),
]);
export type RecordAnswerInput = z.infer<typeof recordAnswerInput>;

export const askQuestionInput = z.object({
  question_id: nonemptyString,
  question: nonemptyString,
  answer_type: z.enum(answerTypes),
});
export type AskQuestionInput = z.infer<typeof askQuestionInput>;

export const completeSessionInput = z.object({
  summary: nonemptyString,
});
export type CompleteSessionInput = z.infer<typeof completeSessionInput>;
