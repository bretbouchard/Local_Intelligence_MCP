# BDS + GSD Integration Guide

## Overview

This document integrates **Behavior-Driven Specification (BDS)** with the existing **Get Shit Done (GSD)** task breakdown for Local Intelligence MCP.

## What is BDS?

BDS bridges the gap between:
- **What** the system should do (specifications)
- **How** to verify it works (acceptance tests)
- **Why** it matters (business value)

## Integration with GSD

```
┌─────────────────────────────────────────────────────────────┐
│                    BDS + GSD Workflow                       │
└─────────────────────────────────────────────────────────────┘

1. BDS Specification (What & Why)
   └── Defines behavior in plain language
   
2. GSD Task Breakdown (How & When)
   └── Breaks into executable tasks
   
3. BDS Scenarios (Acceptance)
   └── Automated acceptance tests
   
4. GSD Verification (Quality Gate)
   └── Task-level verification commands
```

## Directory Structure

```
/Users/bretbouchard/apps/local_intelligence_mcp/

specs/                          # BDS Specifications
├── features/                   # Behavior specifications (new)
│   ├── 00-truth/              # Phase 0 features
│   ├── 01-capability/         # Phase 1 features
│   ├── 02-automation/         # Phase 2 features
│   └── 03-foundation-models/  # Phase 3 features
├── scenarios/                  # Concrete scenarios (new)
└── constitution.md            # Project principles (existing)

docs/gsd/                       # GSD Task Breakdown
├── tasks/                     # AI-optimized tasks
├── MASTER_PLAN.md            # Overall plan
└── ACCEPTANCE_GATES.md       # Quality gates

Tests/                         # Executable acceptance tests
├── BDSTests/                  # BDS scenario tests (new)
└── IntegrationTests/          # GSD integration tests
```

## BDS Template for Features

Each feature file describes ONE capability:

```gherkin
Feature: [Capability Name]
  As a [role]
  I want [capability]
  So that [business value]

  Background:
    Given the system is running on [OS version]
    And [prerequisite conditions]

  Scenario: [Happy path]
    Given [initial state]
    When [action]
    Then [expected outcome]
    And [additional verification]

  Scenario: [Error case]
    Given [initial state]
    When [problematic action]
    Then [error handling]
    And [graceful degradation]

  Scenario: [Edge case]
    Given [boundary condition]
    When [action]
    Then [expected behavior]
```

## Mapping BDS → GSD

Each BDS Feature maps to multiple GSD Tasks:

```yaml
# Example: RuntimeCapabilities Feature → GSD Tasks 1.1.x

BDS Feature:
  File: specs/features/01-capability/runtime-capabilities.feature
  Scenarios: 5 acceptance scenarios
  
GSD Tasks:
  - 1.1.1: Define CapabilityID enum
  - 1.1.2: Define CapabilityStatus enum
  - 1.1.3: Create RuntimeCapabilities struct
  - 1.1.4: Add API feature level detection
  - 1.1.5: Add Apple Intelligence eligibility
  - ... (10 total tasks)
  
BDS Test:
  File: Tests/BDSTests/RuntimeCapabilitiesFeatureTests.swift
  Implements: All 5 scenarios
  Verifies: GSD tasks 1.1.1-1.1.10 complete correctly
```

## Workflow: BDS-First vs GSD-First

### Option A: BDS-First (Recommended for New Features)

```
1. Write BDS Feature
   └── Define what and why

2. Write BDS Scenarios
   └── Define acceptance criteria

3. Generate GSD Tasks
   └── Break down how

4. Implement GSD Tasks
   └── Write code + unit tests

5. Run BDS Tests
   └── Verify scenarios pass
```

### Option B: GSD-First (Retrofit Existing)

```
1. Complete GSD Tasks
   └── Implementation exists

2. Extract BDS Feature
   └── Document what was built

3. Write BDS Scenarios
   └── Capture current behavior

4. Implement BDS Tests
   └── Lock in behavior

5. Refactor with confidence
   └── BDS tests protect against regression
```

## BDS Test Structure

```swift
// Tests/BDSTests/RuntimeCapabilitiesFeatureTests.swift

import XCTest
@testable import LocalIntelligenceMCP

final class RuntimeCapabilitiesFeatureTests: XCTestCase {
    
    // MARK: - Feature: Runtime Capabilities Detection
    
    func testScenario_DetectOSVersion_OnMacOS13() {
        // Given the system is running on macOS 13
        let capabilities = RuntimeCapabilities()
        
        // When I query the OS version
        let version = capabilities.osVersion
        
        // Then it returns a valid OperatingSystemVersion
        XCTAssertGreaterThanOrEqual(version.majorVersion, 13)
        XCTAssertNotNil(capabilities.architecture)
    }
    
    func testScenario_DetectAPIFeatureLevel_OnMacOS13() {
        // Given the system is running on macOS 13
        // And Apple Intelligence is not available
        let capabilities = RuntimeCapabilities()
        
        // When I query the API feature level
        let level = capabilities.apiFeatureLevel
        
        // Then it returns tier1 (automation available)
        XCTAssertEqual(level, .tier1)
    }
    
    func testScenario_CheckAppleIntelligence_OnIntelMac() {
        // Given the system is running on Intel hardware
        // When I check Apple Intelligence eligibility
        // Then it returns false (Apple Silicon required)
        // (Implementation follows from BDS scenario)
    }
}
```

## Creating BDS Features from GSD Tasks

For each GSD Phase, create corresponding BDS features:

### Phase 0: Establish Truth

**GSD Tasks**: 0.1.x - 0.4.x  
**BDS Features**:
- `tool-inventory.feature` - Tool enumeration and classification
- `false-success-removal.feature` - No simulated side effects
- `build-compatibility.feature` - Multi-SDK building
- `baseline-metrics.feature` - Performance baseline

### Phase 1: Capability Kernel

**GSD Tasks**: 1.1.x - 1.5.x  
**BDS Features**:
- `runtime-capabilities.feature` - System capability detection
- `capability-routing.feature` - Provider selection and routing
- `error-taxonomy.feature` - Standard error handling
- `mcp-tools.feature` - local_* tool registration
- `observability.feature` - Logging and metrics

### Phase 2: Real Automation

**GSD Tasks**: 2.1.x - 2.6.x  
**BDS Features**:
- `shortcuts-execution.feature` - Real Shortcuts automation
- `permission-handling.feature` - Permission checks
- `timeout-safety.feature` - Timeout and cancellation
- `automation-policy.feature` - Execution policies

### Phase 3: Foundation Models

**GSD Tasks**: 3.1.x - 3.7.x  
**BDS Features**:
- `fm-provider.feature` - Foundation Models provider
- `text-generation.feature` - Basic text generation
- `structured-output.feature` - Structured generation
- `tool-calling.feature` - Tool execution with policy

## BDS Scenario Examples

### Example 1: Tool Inventory (Phase 0)

```gherkin
Feature: MCP Tool Inventory
  As a developer
  I want to enumerate all registered MCP tools
  So that I can verify what capabilities are claimed vs implemented

  Scenario: Enumerate all tools
    Given the MCP server is initialized
    When I request the tool inventory
    Then I receive a JSON list of all tools
    And each tool has a name, description, and schema
    And each tool is classified as deterministic, side-effect, or stub

  Scenario: Detect simulated tools
    Given the MCP server is initialized
    When I classify the Shortcuts tool
    Then it is marked as "simulated" or "unavailable"
    And the reason explains "not yet implemented"
```

### Example 2: Runtime Capabilities (Phase 1)

```gherkin
Feature: Runtime Capabilities Detection
  As the system
  I want to detect what this machine can do
  So that I can route requests to available providers

  Scenario: Detect capabilities on macOS 13 Intel
    Given the system is running on macOS 13.0
    And the architecture is x86_64
    When I query RuntimeCapabilities
    Then apiFeatureLevel is tier1
    And appleIntelligenceEligible is false
    And supportedCapabilities includes automation
    And supportedCapabilities excludes local_generate

  Scenario: Detect capabilities on macOS 15 Apple Silicon
    Given the system is running on macOS 15.0
    And the architecture is arm64
    And Apple Intelligence is enabled
    When I query RuntimeCapabilities
    Then apiFeatureLevel is tier2
    And appleIntelligenceEligible is true
    And supportedCapabilities includes local_generate
    And modelAvailability is either available or downloading
```

### Example 3: Shortcuts Execution (Phase 2)

```gherkin
Feature: Shortcuts Execution
  As a user
  I want to execute macOS Shortcuts
  So that I can automate tasks locally

  Scenario: Execute existing shortcut
    Given a shortcut named "Test Shortcut" exists
    And the shortcut accepts text input
    When I execute the shortcut with input "test"
    Then the execution completes successfully
    And I receive the shortcut's output
    And execution evidence is logged

  Scenario: Handle missing shortcut
    Given no shortcut named "NonExistent" exists
    When I attempt to execute "NonExistent"
    Then I receive a CapabilityError.unavailable
    And the error message is "Shortcut not found: NonExistent"
    And no false success is returned

  Scenario: Enforce execution timeout
    Given a shortcut that runs for 60 seconds
    And the timeout is set to 5 seconds
    When I execute the shortcut
    Then the execution times out after 5 seconds
    And I receive a CapabilityError.timeout
    And the shortcut process is terminated
```

## Integration Checklist

### For Each GSD Phase:

- [ ] Create `specs/features/[phase]/` directory
- [ ] Write BDS feature files (.feature)
- [ ] Map features to GSD tasks
- [ ] Create BDS test files in `Tests/BDSTests/`
- [ ] Implement scenarios as XCTest methods
- [ ] Run BDS tests as phase acceptance gate
- [ ] Update phase gate with BDS criteria

### Quality Gates Enhancement:

**Original GSD Gate** (Phase 1):
```
- [ ] RuntimeCapabilities reports real state
- [ ] CapabilityRouter routes to providers
- [ ] All local_* tools registered
```

**Enhanced with BDS**:
```
- [ ] RuntimeCapabilities reports real state
  └── BDS: RuntimeCapabilitiesFeatureTests pass
- [ ] CapabilityRouter routes to providers
  └── BDS: CapabilityRoutingFeatureTests pass
- [ ] All local_* tools registered
  └── BDS: MCPToolsFeatureTests pass
```

## Benefits

### BDS Provides:

✅ **Living Documentation** - Features describe behavior in plain language  
✅ **Acceptance Criteria** - Scenarios define "done"  
✅ **Regression Protection** - Tests lock in behavior  
✅ **Communication** - Bridge between stakeholders and code  

### GSD Provides:

✅ **Execution Plan** - Atomic, verifiable tasks  
✅ **Progress Tracking** - Task-level status  
✅ **AI Optimization** - Concrete work steps  
✅ **Dependency Management** - Clear task ordering  

### Together:

✅ **Traceability**: Feature → Scenarios → Tasks → Code → Tests  
✅ **Quality**: Multiple verification layers  
✅ **Flexibility**: Write specs before or after implementation  
✅ **Confidence**: Behavioral + unit test coverage  

## Next Steps

1. **Review existing specs/**: Audit what's already documented
2. **Create BDS structure**: Set up `specs/features/` directories
3. **Start with Phase 0**: Write features for truth baseline
4. **Parallel with GSD**: AI implements tasks, human writes BDS
5. **Automate**: Run BDS tests in CI alongside GSD verification

## Tools and Resources

### Writing BDS Features:
- Use Gherkin syntax (.feature files)
- Tools: Cucumber, SpecFlow, or plain text
- This repo: Plain Gherkin for documentation, XCTest for execution

### Running BDS Tests:
- `swift test --filter BDSTests` - Run all BDS scenarios
- `swift test --filter RuntimeCapabilitiesFeatureTests` - Specific feature
- Integrate with GSD phase gates

### Generating Features from Tasks:
- Script: `scripts/gsd_to_bds.py` (to be created)
- Input: GSD task YAML
- Output: BDS feature template

---

**Document Version**: 1.0  
**Last Updated**: 2026-08-22  
**Status**: Integration framework ready  
**Next**: Create Phase 0 BDS features  
