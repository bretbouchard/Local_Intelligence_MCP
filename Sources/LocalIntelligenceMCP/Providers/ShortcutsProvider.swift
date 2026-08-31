//
//  ShortcutsProvider.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 2.1 — Genuine Shortcuts enumeration/execution via the supported
//  `shortcuts` CLI (macOS 12+). Deterministic input/output, deadline and
//  cancellation, shortcut failure distinguished from transport failure.
//  Arguments are passed directly to Process — never shell-interpolated.
//

import Foundation

final class ShortcutsProvider: AutomationProvider, @unchecked Sendable {

    static let executablePath = "/usr/bin/shortcuts"

    let metadata = ProviderMetadata(
        id: "shortcuts_cli",
        displayName: "Apple Shortcuts (CLI)",
        providerClass: .appleAutomation
    )

    // MARK: - CapabilityProvider

    func availability(for capability: StableCapability) async -> CapabilityStatus {
        switch capability {
        case .localAutomationList, .localAutomationExecute:
            guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 12 else {
                return .unsupported
            }
            return FileManager.default.isExecutableFile(atPath: Self.executablePath)
                ? .available
                : .unavailable
        default:
            return .unsupported
        }
    }

    // MARK: - AutomationProvider

    func listAutomation() async throws -> [String] {
        let result = try await runProcess(arguments: ["list"], input: nil, timeout: 15)
        guard result.exitCode == 0 else {
            throw CapabilityError.providerFailure(
                "shortcuts list failed (exit \(result.exitCode)): \(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
            )
        }
        return result.stdout
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func executeAutomation(name: String, input: String?, timeout: TimeInterval, confirm: Bool) async throws -> AutomationExecution {
        try validateShortcutName(name)

        let started = Date()
        let result: ProcessResult
        do {
            result = try await runProcess(arguments: ["run", name], input: input, timeout: timeout)
        } catch let error as CapabilityError {
            throw error
        } catch {
            // Transport-level failure before the shortcut could run.
            throw CapabilityError.providerFailure("Failed to launch shortcut runner: \(error.localizedDescription)")
        }

        let duration = Date().timeIntervalSince(started)

        if result.exitCode == 0 {
            return AutomationExecution(
                name: name,
                didRun: true,
                output: result.stdout.isEmpty ? nil : result.stdout,
                errorMessage: nil,
                duration: duration,
                provider: metadata
            )
        }

        // The shortcut itself failed (or was not found) — this is a shortcut
        // failure, not a transport failure, and must not be reported as success.
        let stderrMessage = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.exitCode == 1 && stderrMessage.localizedCaseInsensitiveContains("could not be found") {
            throw CapabilityError.invalidRequest("Shortcut '\(name)' does not exist on this Mac")
        }
        throw CapabilityError.providerFailure(
            "Shortcut '\(name)' exited with code \(result.exitCode)\(stderrMessage.isEmpty ? "" : ": \(stderrMessage)")"
        )
    }

    // MARK: - Validation

    /// Names are passed as a single argv element, so option-prefixed names would be
    /// parsed as flags by the CLI. Reject them rather than escaping through a shell.
    private func validateShortcutName(_ name: String) throws {
        if name.isEmpty {
            throw CapabilityError.invalidRequest("Shortcut name cannot be empty")
        }
        if name.count > MCPConstants.Limits.maxShortcutNameLength {
            throw CapabilityError.invalidRequest("Shortcut name exceeds \(MCPConstants.Limits.maxShortcutNameLength) characters")
        }
        if name.hasPrefix("-") {
            throw CapabilityError.invalidRequest("Shortcut name may not begin with '-'")
        }
        if name.contains(where: { $0 == "\0" }) {
            throw CapabilityError.invalidRequest("Shortcut name contains invalid characters")
        }
    }

    // MARK: - Process plumbing

    private struct ProcessResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        let timedOut: Bool
    }

    private func runProcess(arguments: [String], input: String?, timeout: TimeInterval) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let input {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            let handle = stdinPipe.fileHandleForWriting
            let payload = Data(input.utf8)
            // Write off-thread and close, so a shortcut that ignores stdin still terminates.
            DispatchQueue.global().async {
                do {
                    try handle.write(contentsOf: payload)
                    try handle.close()
                } catch {
                    // Process may have exited before consuming input.
                }
            }
        } else {
            process.standardInput = FileHandle.nullDevice
        }

        // No custom environment: do not leak configuration into the child.
        try process.run()

        async let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        async let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let timedOut = await waitForExit(process, timeout: timeout)
        if timedOut {
            if process.isRunning {
                process.terminate()
            }
            // Brief grace period, then hard kill.
            try? await Task.sleep(nanoseconds: 500_000_000)
            if process.isRunning {
                kill(process.processIdentifier, SIGKILL)
            }
            throw CapabilityError.timeout(timeout)
        }

        let out = await stdoutData
        let err = await stderrData
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(data: out, encoding: .utf8) ?? "",
            stderr: String(data: err, encoding: .utf8) ?? "",
            timedOut: false
        )
    }

    /// Returns true when the process had to be treated as timed out.
    private func waitForExit(_ process: Process, timeout: TimeInterval) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    if !process.isRunning {
                        continuation.resume()
                        return
                    }
                    process.terminationHandler = { _ in
                        continuation.resume()
                    }
                }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return process.isRunning
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }
}
