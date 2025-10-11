# Error Handling and Logging Guide

**Date:** 2025-10-09
**Version:** 1.0.0
**Scope:** Local Intelligence MCP Audio Agent Tools System

---

## Overview

This guide documents the comprehensive error handling and logging improvements implemented across the Local Intelligence MCP Audio Agent Tools system. The new standardized approach ensures consistent behavior, enhanced security, and improved debugging capabilities across all tools.

---

## Architecture

### Core Components

#### 1. ErrorHandlingUtils
- **Location**: `Sources/LocalIntelligenceMCP/Utils/ErrorHandlingUtils.swift`
- **Purpose**: Centralized error handling utilities with security-focused sanitization
- **Key Features**:
  - Standardized error creation patterns
  - Automatic sensitive data sanitization
  - Error classification and recovery strategies
  - User-friendly error formatting

#### 2. LoggingUtils
- **Location**: `Sources/LocalIntelligenceMCP/Utils/LoggingUtils.swift`
- **Purpose**: Standardized logging patterns with automatic PII protection
- **Key Features**:
  - Consistent log formatting across all tools
  - Audio domain-specific logging methods
  - Performance metric logging
  - PII operation tracking

#### 3. StandardizedTool Protocol
- **Location**: `Sources/LocalIntelligenceMCP/Core/StandardizedTool.swift`
- **Purpose**: Protocol for tools with standardized error handling and logging
- **Key Features**:
  - Unified execution flow
  - Standardized parameter validation
  - Automatic error logging
  - Consistent response formatting

#### 4. EnhancedBaseMCPTool
- **Location**: `Sources/LocalIntelligenceMCP/Core/StandardizedTool.swift`
- **Purpose**: Base class implementing standardized behavior
- **Key Features**:
  - Default implementation of StandardizedTool protocol
  - Convenience methods for validation and logging
  - Built-in error handling patterns

---

## Error Handling Patterns

### Error Classification

```swift
enum ErrorClassification: String {
    case validation = "validation"      // Input validation errors
    case security = "security"          // Permission/security errors
    case processing = "processing"      // Processing failures
    case serialization = "serialization" // Data format errors
    case unknown = "unknown"           // Unclassified errors
}
```

### Error Creation Patterns

#### Validation Errors
```swift
// Creating a validation error with sanitization
throw ErrorHandlingUtils.createValidationError(
    message: "Invalid parameter value",
    field: "max_points",
    value: 20,
    toolName: "apple.summarize"
)
```

#### Security Errors
```swift
// Creating a security error with context
throw ErrorHandlingUtils.createSecurityError(
    message: "Access denied",
    operation: "read_sensitive_data",
    toolName: "apple.system.info"
)
```

#### Processing Errors
```swift
// Creating a processing error with cause
throw ErrorHandlingUtils.createProcessingError(
    message: "Failed to process audio content",
    operation: "summarization",
    toolName: "apple.summarize",
    cause: underlyingError
)
```

### Error Sanitization

The system automatically sanitizes error messages to prevent information disclosure:

```swift
// Sensitive patterns automatically redacted
"Error: API key sk_1234567890abcdef failed"
→ "Error: [REDACTED] failed"

"Error: Password 'secret123' is incorrect"
→ "Error: [REDACTED] is incorrect"
```

### Error Recovery Strategies

```swift
enum RetryStrategy {
    case none                           // No retry
    case linear(delay: TimeInterval, maxRetries: Int)
    case exponential(base: Double, maxDelay: TimeInterval)
}
```

---

## Logging Patterns

### Standardized Logging Methods

#### Tool Execution Logging
```swift
// Log tool start
await LoggingUtils.logToolStart(
    toolName: "apple.summarize",
    parameters: parameters,
    context: context,
    logger: logger
)

// Log tool success
await LoggingUtils.logToolSuccess(
    toolName: "apple.summarize",
    executionTime: 0.123,
    resultSize: 1024,
    context: context,
    logger: logger
)

// Log tool failure
await LoggingUtils.logToolFailure(
    toolName: "apple.summarize",
    error: error,
    executionTime: 0.045,
    context: context,
    logger: logger
)
```

#### Audio Domain Logging
```swift
// Log audio processing start
await LoggingUtils.logAudioProcessingStart(
    operation: "summarization",
    inputSize: text.count,
    parameters: processingParams,
    context: context,
    logger: logger
)

// Log audio processing result
await LoggingUtils.logAudioProcessingResult(
    operation: "summarization",
    duration: 0.234,
    outputSize: summary.count,
    quality: ["compressionRatio": 0.15],
    context: context,
    logger: logger
)
```

#### Security Event Logging
```swift
// Log security event
await LoggingUtils.logSecurityEvent(
    eventType: .permissionDenied,
    toolName: "apple.system.info",
    details: ["operation": "access_sensitive_info"],
    context: context,
    logger: logger
)
```

#### PII Operation Logging
```swift
// Log PII detection and redaction
await LoggingUtils.logPIIOperation(
    operation: "redaction",
    detections: 3,
    redactions: 3,
    categories: ["email", "phone", "apiKey"],
    context: context,
    logger: logger
)
```

### ToolLogger Convenience Class

```swift
// Get tool-specific logger
let toolLogger = logger.toolLogger("apple.summarize")

// Use convenience methods
await toolLogger.logStart(parameters: parameters, context: context)
await toolLogger.logSuccess(executionTime: 0.123, context: context)
await toolLogger.logFailure(error: error, executionTime: 0.045, context: context)
```

### Log Sanitization

The logging system automatically sanitizes sensitive data:

```swift
// Parameter sanitization
let sanitizedParams = LoggingUtils.sanitizeLogParameters([
    "text": "User input",
    "apiKey": "sk_1234567890abcdef",  // → [REDACTED]
    "password": "secret123"            // → [REDACTED]
])
```

---

## Implementation Guide

### Creating a New Tool

#### 1. Extend EnhancedBaseMCPTool
```swift
public class MyTool: EnhancedBaseMCPTool, @unchecked Sendable {

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "my.tool",
            description: "My tool description",
            inputSchema: inputSchema,
            logger: logger,
            securityManager: securityManager
        )
    }
}
```

#### 2. Implement Required Methods
```swift
public override func validateParametersStandard(
    _ parameters: [String: AnyCodable],
    context: MCPExecutionContext
) async throws {
    // Call parent validation
    try await super.validateParametersStandard(parameters, context: context)

    // Add tool-specific validation
    _ = try validateParameter(
        parameters["required_param"]?.value,
        as: String.self,
        name: "required_param",
        required: true,
        context: context
    )
}

public override func performCoreExecution(
    parameters: [String: AnyCodable],
    context: MCPExecutionContext
) async throws -> Any {
    // Extract validated parameters
    let requiredParam = try validateParameter(
        parameters["required_param"]?.value,
        as: String.self,
        name: "required_param",
        required: true,
        context: context
    )

    // Perform core logic
    let result = await performMyOperation(requiredParam)

    // Return structured result
    return ["result": result, "metadata": ["processed": true]]
}
```

#### 3. Use Logging Patterns
```swift
// Performance logging
await logPerformance(
    operation: "my_operation",
    duration: processingTime,
    metadata: ["inputSize": requiredParam.count],
    context: context
)

// Security logging
await logSecurityEvent(
    eventType: .permissionGranted,
    details: ["operation": "my_operation"],
    context: context
)
```

### Updating Existing Tools

#### Option 1: Adopt StandardizedTool Protocol
```swift
extension ExistingTool: StandardizedTool {

    func performCoreExecution(
        parameters: [String: AnyCodable],
        context: MCPExecutionContext
    ) async throws -> Any {
        // Migrate existing performExecution logic here
        return try await existingLogic(parameters, context)
    }
}
```

#### Option 2: Use EnhancedBaseMCPTool as Base
```swift
class UpdatedExistingTool: EnhancedBaseMCPTool {

    // Migrate existing initialization
    override init(logger: Logger, securityManager: SecurityManager) {
        // Existing init logic
    }

    // Implement standardized methods
    override func validateParametersStandard(...) async throws {
        // Migrate existing validation
    }

    override func performCoreExecution(...) async throws -> Any {
        // Migrate existing processing logic
    }
}
```

---

## Best Practices

### Error Handling

1. **Always use ErrorHandlingUtils for error creation**
   ```swift
   // ✅ Good
   throw ErrorHandlingUtils.createValidationError(message: "Invalid input", toolName: name)

   // ❌ Avoid
   throw NSError(domain: "MyTool", code: 400, userInfo: nil)
   ```

2. **Include context in errors**
   ```swift
   // ✅ Good
   throw ErrorHandlingUtils.createValidationError(
       message: "Invalid style parameter",
       field: "style",
       value: invalidValue,
       toolName: toolName
   )
   ```

3. **Handle errors gracefully**
   ```swift
   do {
       let result = try await riskyOperation()
       return MCPResponse(success: true, data: AnyCodable(result))
   } catch {
       return await handleError(error, context: context)
   }
   ```

### Logging

1. **Log at appropriate levels**
   ```swift
   // ✅ Good
   await logger.debug("Detailed debugging info", metadata: details)
   await logger.info("Important events", metadata: metadata)
   await logger.warning("Potential issues", metadata: warningData)
   await logger.error("Errors with context", error: error, metadata: errorData)
   ```

2. **Include structured metadata**
   ```swift
   // ✅ Good
   await logger.info("Processing completed", metadata: [
       "operation": "summarization",
       "duration": 0.123,
       "inputSize": 1024,
       "outputSize": 256
   ])
   ```

3. **Use domain-specific logging methods**
   ```swift
   // ✅ Good
   await LoggingUtils.logAudioProcessingResult(
       operation: "summarization",
       duration: processingTime,
       outputSize: result.count,
       quality: qualityMetrics,
       context: context,
       logger: logger
   )
   ```

### Security

1. **Never log sensitive data**
   ```swift
   // ❌ Avoid
   await logger.info("API key used: \(apiKey)")

   // ✅ Good
   await logger.info("API key authentication attempted")
   ```

2. **Use automatic sanitization**
   ```swift
   // ✅ Good - automatic sanitization
   let sanitizedParams = LoggingUtils.sanitizeLogParameters(parameters)
   ```

3. **Log security events**
   ```swift
   // ✅ Good
   await LoggingUtils.logSecurityEvent(
       eventType: .permissionDenied,
       toolName: toolName,
       details: ["operation": "sensitive_access"],
       context: context,
       logger: logger
   )
   ```

---

## Migration Checklist

### For Existing Tools

- [ ] Extend or inherit from EnhancedBaseMCPTool
- [ ] Implement `validateParametersStandard()` method
- [ ] Implement `performCoreExecution()` method
- [ ] Replace manual error creation with ErrorHandlingUtils methods
- [ ] Replace manual logging with LoggingUtils methods
- [ ] Add performance logging for key operations
- [ ] Add security event logging for sensitive operations
- [ ] Test error handling and logging behavior

### For New Tools

- [ ] Use EnhancedBaseMCPTool as base class
- [ ] Implement standardized validation patterns
- [ ] Use domain-specific logging methods
- [ ] Include structured metadata in logs
- [ ] Add comprehensive error handling
- [ ] Test all error scenarios

---

## Troubleshooting

### Common Issues

1. **Compilation Errors with StandardizedTool**
   - Ensure all required methods are implemented
   - Check that toolName property is accessible
   - Verify logger and securityManager are properly initialized

2. **Missing Context in Logs**
   - Ensure MCPExecutionContext is passed to all logging methods
   - Check that context contains valid request and client IDs

3. **Error Information Disclosure**
   - Verify ErrorHandlingUtils.sanitizeErrorMessage() is working
   - Check for any direct logging of raw error messages
   - Test with various error scenarios

### Debugging Tips

1. **Enable Debug Logging**
   ```swift
   await logger.debug("Debug info", category: .general, metadata: debugData)
   ```

2. **Use ToolLogger for Context**
   ```swift
   let toolLogger = logger.toolLogger(toolName)
   await toolLogger.debug("Tool-specific debug info", context: context)
   ```

3. **Check Error Classification**
   ```swift
   let classification = ErrorHandlingUtils.classifyError(error)
   let retryStrategy = ErrorHandlingUtils.getRetryStrategy(error)
   ```

---

## Performance Considerations

### Logging Performance

- Logging is asynchronous and non-blocking
- Large metadata objects are automatically truncated
- File logging is buffered and written in batches

### Error Handling Performance

- Error sanitization is optimized for common patterns
- Error classification uses efficient type checking
- Retry strategies are computed lazily

### Memory Management

- Log buffers are automatically limited in size
- Error metadata is sanitized to prevent memory leaks
- Temporary objects are properly scoped and released

---

## Future Enhancements

### Planned Improvements

1. **Advanced Error Analytics**
   - Error pattern detection
   - Automatic error categorization
   - Performance impact analysis

2. **Enhanced Logging Features**
   - Log aggregation and correlation
   - Real-time log monitoring
   - Automated alerting based on error patterns

3. **Security Enhancements**
   - Advanced PII detection patterns
   - Configurable sanitization rules
   - Security event correlation

### Extensibility

The error handling and logging system is designed to be easily extensible:

- New error types can be added to ErrorClassification
- Custom logging patterns can extend LoggingUtils
- New sanitization patterns can be added to ErrorHandlingUtils
- Tool-specific logging categories can be defined

---

## Conclusion

The standardized error handling and logging system provides a robust foundation for all Local Intelligence MCP Audio Agent Tools. By following the patterns and best practices outlined in this guide, developers can create tools that are:

- **Consistent**: Uniform error handling and logging across all tools
- **Secure**: Automatic sanitization of sensitive data
- **Debuggable**: Comprehensive logging with rich context
- **Maintainable**: Clear separation of concerns and reusable patterns
- **Performant**: Optimized for production workloads

The system is production-ready and designed to scale with the growing needs of the Local Intelligence MCP Audio Agent Tools ecosystem.