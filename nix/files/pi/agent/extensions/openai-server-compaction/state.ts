/** Ephemeral per-session state; opaque artifacts persist in Pi compaction entries. */
import type {
  RemoteCompactionSessionState,
  ResponsesReasoningConfig,
  ResponsesTextConfig,
} from "./remote-compaction.ts";

export type ResponsesRequestShapeState = {
  reasoning?: ResponsesReasoningConfig;
  text?: ResponsesTextConfig;
};

export type SessionStore<T> = {
  get(sessionId: string): T | undefined;
  set(sessionId: string, state: T): void;
  clear(sessionId: string | undefined): void;
};

const clearAllCallbacks: Array<() => void> = [];

function createSessionStore<T>(): SessionStore<T> {
  const bySessionId = new Map<string, T>();
  clearAllCallbacks.push(() => bySessionId.clear());
  return {
    get: (sessionId) => bySessionId.get(sessionId),
    set: (sessionId, state) => {
      bySessionId.set(sessionId, state);
    },
    clear: (sessionId) => {
      if (sessionId) bySessionId.delete(sessionId);
    },
  };
}

/** Post-compaction opaque history replayed on later compatible requests. */
export const remoteCompactionState = createSessionStore<RemoteCompactionSessionState>();

/** Request shape (reasoning/text) observed from Pi's own Responses payloads. */
export const responsesRequestShapeState = createSessionStore<ResponsesRequestShapeState>();

export function clearAllRuntimeState(): void {
  for (const clear of clearAllCallbacks) clear();
}
