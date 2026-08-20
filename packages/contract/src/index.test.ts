import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  answerValueSchemas,
  askQuestionInput,
  completeSessionInput,
  recordAnswerInput,
} from "./index.ts";

describe("ask_question input", () => {
  it("accepts question_id, question text, and a known answer_type", () => {
    const input = {
      question_id: "NUy0Q6sAiHQjteaSyjz4",
      question: "How would you rate your day?",
      answer_type: "rating",
    };
    assert.deepEqual(askQuestionInput.parse(input), input);
  });

  it("rejects unknown answer types and empty question text", () => {
    assert.equal(
      askQuestionInput.safeParse({
        question_id: "x",
        question: "Hi?",
        answer_type: "multi_select",
      }).success,
      false,
    );
    assert.equal(
      askQuestionInput.safeParse({
        question_id: "x",
        question: "",
        answer_type: "rating",
      }).success,
      false,
    );
  });
});

describe("complete_session input", () => {
  it("accepts a non-empty summary and rejects an empty one", () => {
    assert.deepEqual(completeSessionInput.parse({ summary: "A good day." }), {
      summary: "A good day.",
    });
    assert.equal(
      completeSessionInput.safeParse({ summary: "" }).success,
      false,
    );
  });
});

describe("record_answer input", () => {
  it("accepts a value matching the answer_type discriminator", () => {
    const input = {
      question_id: "NUy0Q6sAiHQjteaSyjz4",
      answer: { answer_type: "rating", value: 7 },
    };
    assert.deepEqual(recordAnswerInput.parse(input), input);
  });

  it("rejects a value whose shape belongs to a different answer_type", () => {
    const mismatched = {
      question_id: "ZP1r3kAnMd9XZ1rU1sem",
      answer: { answer_type: "text_list", value: 7 },
    };
    assert.equal(recordAnswerInput.safeParse(mismatched).success, false);
  });

  it("rejects unknown answer types", () => {
    const unknown = {
      question_id: "x",
      answer: { answer_type: "mood_slider", value: 3 },
    };
    assert.equal(recordAnswerInput.safeParse(unknown).success, false);
  });
});

describe("text_list, emoji, longtext values", () => {
  it("text_list and emoji accept non-empty string lists (legacy Firestore shape)", () => {
    assert.deepEqual(
      answerValueSchemas.text_list.parse(["my wife", "myself", "Flutter"]),
      ["my wife", "myself", "Flutter"],
    );
    assert.deepEqual(answerValueSchemas.emoji.parse(["🔥", "🤔"]), [
      "🔥",
      "🤔",
    ]);
  });

  it("longtext accepts one non-empty string, rejects a list", () => {
    assert.equal(
      answerValueSchemas.longtext.parse("I feel happy because…"),
      "I feel happy because…",
    );
    assert.equal(answerValueSchemas.longtext.safeParse(["a"]).success, false);
  });

  it("rejects empty lists, empty strings, and lists of empties", () => {
    assert.equal(answerValueSchemas.text_list.safeParse([]).success, false);
    assert.equal(answerValueSchemas.text_list.safeParse([""]).success, false);
    assert.equal(answerValueSchemas.emoji.safeParse([]).success, false);
    assert.equal(answerValueSchemas.longtext.safeParse("").success, false);
  });
});

describe("color value", () => {
  it("accepts a list of uppercase #RRGGBB strings (legacy Firestore shape)", () => {
    assert.deepEqual(answerValueSchemas.color.parse(["#00FF00", "#FF0004"]), [
      "#00FF00",
      "#FF0004",
    ]);
  });

  it("rejects bare hex, 8-digit hex, short hex, and the empty list", () => {
    for (const bad of [["FF0000"], ["#FF00000A"], ["#ff00"], []]) {
      assert.equal(answerValueSchemas.color.safeParse(bad).success, false);
    }
  });
});

describe("rating value", () => {
  it("accepts integers 1 and 10 (legacy scale bounds)", () => {
    assert.equal(answerValueSchemas.rating.parse(1), 1);
    assert.equal(answerValueSchemas.rating.parse(10), 10);
  });

  it("rejects 0 (legacy null sentinel), 11, and non-integers", () => {
    for (const bad of [0, 11, 5.5, "7", null]) {
      assert.equal(answerValueSchemas.rating.safeParse(bad).success, false);
    }
  });
});
