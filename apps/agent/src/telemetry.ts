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
import { PostHog } from "posthog-node";
import { createErrorReporter, type ReportError } from "./error-tracking.ts";

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
let activeProcessor: SpanProcessor | undefined;
/**
 * The exception client, separate from the span pipeline: `$ai_generation`
 * spans and `$exception` events are different PostHog products on the same
 * project, and only the latter needs a `posthog-node` client. One client per
 * process, reused by every report (ADR 0004: one vendor, one SDK).
 */
let exceptionClient: PostHog | undefined;

/**
 * Flush queued spans *and* queued exceptions without tearing the pipeline
 * down (serverless use). A Vercel function can freeze the moment the
 * response is returned, so the caller runs this inside `waitUntil`; skipping
 * it loses the very events that say the service is down.
 */
export async function flushTelemetry(): Promise<void> {
  await Promise.all([activeProcessor?.forceFlush(), exceptionClient?.flush()]);
}

/**
 * Report a handled failure to PostHog error tracking, content-free
 * (ADR 0005). A no-op until `initTelemetry` has been given PostHog
 * credentials — observability must never block journaling.
 */
export const reportError: ReportError = (error, context) => {
  if (exceptionClient === undefined) {
    return;
  }
  createErrorReporter(exceptionClient)(error, context);
};

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
    const processor = new PostHogSpanProcessor(opts.posthog);
    activeProcessor = processor;
    processors.push(processor);
    // Exceptions are captured explicitly, never autocaptured: the SDK's
    // uncaught handler would report errors this code has not passed through
    // the content-free rule, and stack-trace processing needs a file system
    // a serverless runtime may not give it.
    exceptionClient = new PostHog(opts.posthog.projectToken, {
      host: opts.posthog.host,
      enableExceptionAutocapture: false,
    });
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
    await exceptionClient?.shutdown();
    exceptionClient = undefined;
  };
}
