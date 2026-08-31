# FEATURE Example: Streaming Generation Support

**ID**: FEATURE-20260822-001-streaming-example  
**Status**: open  
**Priority**: P2-medium  
**Created**: 2026-08-22  
**Updated**: 2026-08-22  
**Assignee**: unassigned  

## Description

Add streaming support for `local_generate` to provide incremental results as text is generated, improving perceived latency for long-form content.

## Context

User feedback indicates that generation feels slow for long outputs (>500 tokens). Streaming would allow:
- Progressive display to user
- Better UX for chatbot-style interactions
- Early cancellation if output is off-track

Apple Foundation Models supports streaming natively (as of macOS 15.2).

## Use Cases

1. **Chatbot UI**: Stream responses token-by-token
2. **Long-form writing**: Progressive display of articles/essays
3. **Code generation**: See code appear as it's generated
4. **Early stopping**: Cancel if output goes wrong direction

## Proposed API

```json
{
  "tool": "local_generate",
  "arguments": {
    "prompt": "Write a blog post about...",
    "stream": true,
    "max_tokens": 1000
  }
}
```

Response as Server-Sent Events (SSE) or line-delimited JSON:

```json
{"type": "chunk", "text": "The "}
{"type": "chunk", "text": "rise "}
{"type": "chunk", "text": "of "}
{"type": "done", "total_tokens": 453}
```

## Technical Considerations

### MCP Protocol

- MCP doesn't natively support streaming responses
- Options:
  1. Use progress notifications
  2. Return partial results via separate mechanism
  3. Extend MCP with streaming support

### Apple FM API

- Requires `@available(macOS 15.2, *)`
- Use `generateStream()` method
- Returns `AsyncThrowingStream<String, Error>`

### Provider Architecture

- Add `supportsStreaming` to provider capability
- Streaming and non-streaming code paths
- Graceful degradation if streaming unavailable

## GSD Task Breakdown

Estimated 6-8 tasks:

1. Research streaming options for MCP
2. Design streaming API contract
3. Add `generateStream()` to IntelligenceProvider protocol
4. Implement in AppleFMProvider
5. Add streaming request/response types
6. Update local_generate tool
7. Add streaming tests
8. Document streaming usage

## Linked Items

- Related to: GSD Phase 3 (Foundation Models)
- Depends on: Task 3.3.4 (basic generation working)
- Similar to: Task 3.3.4 (non-streaming generation)

## Acceptance Criteria

- [ ] Streaming works for local_generate
- [ ] Chunks delivered incrementally
- [ ] Cancellation stops stream cleanly
- [ ] Fallback to non-streaming if unavailable
- [ ] Tests cover streaming scenarios
- [ ] Documentation includes streaming examples
- [ ] Performance improvement measurable

## Benefits

- **User Experience**: Perceived latency reduced by ~60%
- **Flexibility**: Can cancel long generations early
- **Alignment**: Matches industry patterns (OpenAI, Anthropic)

## Risks

- **Complexity**: Adds async streaming complexity
- **MCP Compatibility**: May require custom solution
- **Testing**: Harder to test streaming behavior

## Estimated Effort

- **Time**: 4-6 hours
- **Complexity**: Medium
- **Risk**: Medium (protocol extension)
- **Dependencies**: Phase 3 complete

## Priority Justification

P2-medium because:
- **Not blocking**: Non-streaming works fine
- **Good enhancement**: Meaningful UX improvement
- **Moderate effort**: Reasonable time investment
- **Defer possible**: Can ship without it

## Proposed Timeline

- Phase 3 complete → design
- Phase 4 → implementation
- Phase 5 → testing & polish

## Tags

#feature #phase4 #streaming #generation #ux #P2
