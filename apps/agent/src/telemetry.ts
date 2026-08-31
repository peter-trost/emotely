import { OpenTelemetry } from "@ai-sdk/otel";
import { resourceFromAttributes } from "@opentelemetry/resources";
import {
  SimpleSpanProcessor,
  type SpanExporter,
  type SpanProcessor,
} from "@opentelemetry/sdk-trace-base";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";
import { PostHogSpanProcessor } from "@posthog/ai/otel";
import { registerTelemetry } from "ai";

/**
 * ADR 0005: journal content never leaves the process via telemetry. These
 * flags suppress every content-bearing span attribute (messages, tool args,
 * tool results) at the source; runSession applies them on every model call.
 */
export const PRIVACY_TELEMETRY = {
  isEnabled: true,
  functionId: "journal-session",
  recordInputs: false,
  recordOutputs: false,
} as const;

/**
 * Wire the OTel pipeline once per process. Without POSTHOG_KEY (and no test
 * exporter) telemetry stays off — observability must never block journaling.
 * Returns a shutdown hook that flushes queued spans; a CLI that exits without
 * awaiting it silently loses events.
 */
export function initTelemetry(
  opts: {
    posthog?: { projectToken: string; host: string };
    testExporter?: SpanExporter;
  } = {},
): () => Promise<void> {
  const processors: SpanProcessor[] = [];
  if (opts.testExporter) {
    processors.push(new SimpleSpanProcessor(opts.testExporter));
  } else if (opts.posthog) {
    processors.push(new PostHogSpanProcessor(opts.posthog));
  } else {
    return async () => {
      // telemetry disabled — nothing to flush
    };
  }

  const provider = new NodeTracerProvider({
    resource: resourceFromAttributes({ "service.name": "emotely-agent" }),
    spanProcessors: processors,
  });
  provider.register();
  registerTelemetry(
    new OpenTelemetry({
      enrichSpan: ({ runtimeContext }) => {
        const str = (v: unknown) => (typeof v === "string" ? v : undefined);
        const distinctId = str(runtimeContext?.["distinctId"]);
        const sessionId = str(runtimeContext?.["sessionId"]);
        const promptId = str(runtimeContext?.["promptId"]);
        return {
          ...(distinctId === undefined
            ? {}
            : { "posthog.distinct_id": distinctId }),
          ...(sessionId === undefined ? {} : { $ai_session_id: sessionId }),
          ...(promptId === undefined ? {} : { promptId }),
        };
      },
    }),
  );

  return async () => {
    await provider.shutdown();
  };
}
