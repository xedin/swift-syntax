//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if swift(>=6.0)
import SwiftBasicFormat
public import SwiftDiagnostics
@_spi(FixItApplier) import SwiftIDEUtils
import SwiftParser
import SwiftParserDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacroExpansion
public import SwiftSyntaxMacros
import _SwiftSyntaxTestSupport
private import XCTest
#else
import SwiftBasicFormat
import SwiftDiagnostics
@_spi(FixItApplier) import SwiftIDEUtils
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import _SwiftSyntaxTestSupport
import XCTest
#endif

// MARK: - Note

/// Describes a diagnostic note that tests expect to be created by a macro expansion.
public struct NoteSpec {
  /// The expected message of the note
  public let message: String

  /// The line to which the note is expected to point
  public let line: Int

  /// The column to which the note is expected to point
  public let column: Int

  /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  internal let originatorFile: StaticString
  internal let originatorLine: UInt

  /// Creates a new ``NoteSpec`` that describes a note tests are expecting to be generated by a macro expansion.
  ///
  /// - Parameters:
  ///   - message: The expected message of the note
  ///   - line: The line to which the note is expected to point
  ///   - column: The column to which the note is expected to point
  ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  public init(
    message: String,
    line: Int,
    column: Int,
    originatorFile: StaticString = #filePath,
    originatorLine: UInt = #line
  ) {
    self.message = message
    self.line = line
    self.column = column
    self.originatorFile = originatorFile
    self.originatorLine = originatorLine
  }
}

func assertNote(
  _ note: Note,
  in expansionContext: BasicMacroExpansionContext,
  expected spec: NoteSpec
) {
  assertStringsEqualWithDiff(
    note.message,
    spec.message,
    "message of note does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )
  let location = expansionContext.location(for: note.position, anchoredAt: note.node, fileName: "")
  XCTAssertEqual(
    location.line,
    spec.line,
    "line of note does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )
  XCTAssertEqual(
    location.column,
    spec.column,
    "column of note does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )
}

// MARK: - Fix-It

/// Describes a Fix-It that tests expect to be created by a macro expansion.
///
/// Currently, it only compares the message of the Fix-It. In the future, it might
/// also compare the expected changes that should be performed by the Fix-It.
public struct FixItSpec {
  /// The expected message of the Fix-It
  public let message: String

  /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  internal let originatorFile: StaticString
  internal let originatorLine: UInt

  /// Creates a new ``FixItSpec`` that describes a Fix-It tests are expecting to be generated by a macro expansion.
  ///
  /// - Parameters:
  ///   - message: The expected message of the note
  ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  public init(
    message: String,
    originatorFile: StaticString = #filePath,
    originatorLine: UInt = #line
  ) {
    self.message = message
    self.originatorFile = originatorFile
    self.originatorLine = originatorLine
  }
}

func assertFixIt(
  _ fixIt: FixIt,
  expected spec: FixItSpec
) {
  assertStringsEqualWithDiff(
    fixIt.message.message,
    spec.message,
    "message of Fix-It does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )
}

// MARK: - Diagnostic

/// Describes a diagnostic that tests expect to be created by a macro expansion.
public struct DiagnosticSpec {
  /// If not `nil`, the ID, which the diagnostic is expected to have.
  public let id: MessageID?

  /// The expected message of the diagnostic
  public let message: String

  /// The line to which the diagnostic is expected to point
  public let line: Int

  /// The column to which the diagnostic is expected to point
  public let column: Int

  /// The expected severity of the diagnostic
  public let severity: DiagnosticSeverity

  /// If not `nil`, the text fragments the diagnostic is expected to highlight
  public let highlights: [String]?

  /// The notes that are expected to be attached to the diagnostic
  public let notes: [NoteSpec]

  /// The messages of the Fix-Its the diagnostic is expected to produce
  public let fixIts: [FixItSpec]

  /// The file and line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  internal let originatorFile: StaticString
  internal let originatorLine: UInt

  /// Creates a new ``DiagnosticSpec`` that describes a diagnostic tests are expecting to be generated by a macro expansion.
  ///
  /// - Parameters:
  ///   - id: If not `nil`, the ID, which the diagnostic is expected to have.
  ///   - message: The expected message of the diagnostic
  ///   - line: The line to which the diagnostic is expected to point
  ///   - column: The column to which the diagnostic is expected to point
  ///   - severity: The expected severity of the diagnostic
  ///   - highlights: If not empty, the text fragments the diagnostic is expected to highlight
  ///   - notes: The notes that are expected to be attached to the diagnostic
  ///   - fixIts: The messages of the Fix-Its the diagnostic is expected to produce
  ///   - originatorFile: The file at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  ///   - originatorLine: The line at which this ``NoteSpec`` was created, so that assertion failures can be reported at its location.
  public init(
    id: MessageID? = nil,
    message: String,
    line: Int,
    column: Int,
    severity: DiagnosticSeverity = .error,
    highlights: [String]? = nil,
    notes: [NoteSpec] = [],
    fixIts: [FixItSpec] = [],
    originatorFile: StaticString = #filePath,
    originatorLine: UInt = #line
  ) {
    self.id = id
    self.message = message
    self.line = line
    self.column = column
    self.severity = severity
    self.highlights = highlights
    self.notes = notes
    self.fixIts = fixIts
    self.originatorFile = originatorFile
    self.originatorLine = originatorLine
  }
}

extension DiagnosticSpec {
  @available(*, deprecated, message: "Use highlights instead")
  public var highlight: String? {
    guard let highlights else {
      return nil
    }
    return highlights.joined(separator: " ")
  }

  // swift-format-ignore
  @available(*, deprecated, message: "Use init(id:message:line:column:severity:highlights:notes:fixIts:originatorFile:originatorLine:) instead")
  @_disfavoredOverload
  public init(
    id: MessageID? = nil,
    message: String,
    line: Int,
    column: Int,
    severity: DiagnosticSeverity = .error,
    highlight: String? = nil,
    notes: [NoteSpec] = [],
    fixIts: [FixItSpec] = [],
    originatorFile: StaticString = #filePath,
    originatorLine: UInt = #line
  ) {
    self.init(
      id: id,
      message: message,
      line: line,
      column: column,
      severity: severity,
      highlights: highlight.map { [$0] },
      notes: notes,
      fixIts: fixIts
    )
  }
}

func assertDiagnostic(
  _ diag: Diagnostic,
  in expansionContext: BasicMacroExpansionContext,
  expected spec: DiagnosticSpec
) {
  if let id = spec.id {
    XCTAssertEqual(
      diag.diagnosticID,
      id,
      "diagnostic ID does not match",
      file: spec.originatorFile,
      line: spec.originatorLine
    )
  }
  assertStringsEqualWithDiff(
    diag.message,
    spec.message,
    "message does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )
  let location = expansionContext.location(for: diag.position, anchoredAt: diag.node, fileName: "")
  XCTAssertEqual(location.line, spec.line, "line does not match", file: spec.originatorFile, line: spec.originatorLine)
  XCTAssertEqual(
    location.column,
    spec.column,
    "column does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )

  XCTAssertEqual(
    spec.severity,
    diag.diagMessage.severity,
    "severity does not match",
    file: spec.originatorFile,
    line: spec.originatorLine
  )

  if let highlights = spec.highlights {
    if diag.highlights.count != highlights.count {
      XCTFail(
        """
        Expected \(highlights.count) highlights but received \(diag.highlights.count):
        \(diag.highlights.map(\.trimmedDescription).joined(separator: "\n"))
        """,
        file: spec.originatorFile,
        line: spec.originatorLine
      )
    } else {
      for (actual, expected) in zip(diag.highlights, highlights) {
        assertStringsEqualWithDiff(
          actual.trimmedDescription,
          expected,
          "highlight does not match",
          file: spec.originatorFile,
          line: spec.originatorLine
        )
      }
    }
  }
  if diag.notes.count != spec.notes.count {
    XCTFail(
      """
      Expected \(spec.notes.count) notes but received \(diag.notes.count):
      \(diag.notes.map(\.debugDescription).joined(separator: "\n"))
      """,
      file: spec.originatorFile,
      line: spec.originatorLine
    )
  } else {
    for (note, expectedNote) in zip(diag.notes, spec.notes) {
      assertNote(note, in: expansionContext, expected: expectedNote)
    }
  }
  if diag.fixIts.count != spec.fixIts.count {
    XCTFail(
      """
      Expected \(spec.fixIts.count) Fix-Its but received \(diag.fixIts.count):
      \(diag.fixIts.map(\.message.message).joined(separator: "\n"))
      """,
      file: spec.originatorFile,
      line: spec.originatorLine
    )
  } else {
    for (fixIt, expectedFixIt) in zip(diag.fixIts, spec.fixIts) {
      assertFixIt(fixIt, expected: expectedFixIt)
    }
  }
}

/// Assert that expanding the given macros in the original source produces
/// the given expanded source code.
///
/// - Parameters:
///   - originalSource: The original source code, which is expected to contain
///     macros in various places (e.g., `#stringify(x + y)`).
///   - expectedExpandedSource: The source code that we expect to see after
///     performing macro expansion on the original source.
///   - diagnostics: The diagnostics when expanding any macro
///   - macros: The macros that should be expanded, provided as a dictionary
///     mapping macro names (e.g., `"stringify"`) to implementation types
///     (e.g., `StringifyMacro.self`).
///   - testModuleName: The name of the test module to use.
///   - testFileName: The name of the test file name to use.
///   - indentationWidth: The indentation width used in the expansion.
///
/// - SeeAlso: ``assertMacroExpansion(_:expandedSource:diagnostics:macroSpecs:applyFixIts:fixedSource:testModuleName:testFileName:indentationWidth:file:line:)``
///   to also specify the list of conformances passed to the macro expansion.
public func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: Macro.Type],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  testModuleName: String = "TestModule",
  testFileName: String = "test.swift",
  indentationWidth: Trivia = .spaces(4),
  file: StaticString = #filePath,
  line: UInt = #line
) {
  let specs = macros.mapValues { MacroSpec(type: $0) }
  assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: specs,
    applyFixIts: applyFixIts,
    fixedSource: expectedFixedSource,
    testModuleName: testModuleName,
    testFileName: testFileName,
    indentationWidth: indentationWidth
  )
}

/// Assert that expanding the given macros in the original source produces
/// the given expanded source code.
///
/// - Parameters:
///   - originalSource: The original source code, which is expected to contain
///     macros in various places (e.g., `#stringify(x + y)`).
///   - expectedExpandedSource: The source code that we expect to see after
///     performing macro expansion on the original source.
///   - diagnostics: The diagnostics when expanding any macro
///   - macroSpecs: The macros that should be expanded, provided as a dictionary
///     mapping macro names (e.g., `"CodableMacro"`) to specification with macro type
///     (e.g., `CodableMacro.self`) and a list of conformances macro provides
///     (e.g., `["Decodable", "Encodable"]`).
///   - applyFixIts: If specified, filters the Fix-Its that are applied to generate `fixedSource` to only those whose message occurs in this array. If `nil`, all Fix-Its from the diagnostics are applied.
///   - fixedSource: If specified, asserts that the source code after applying Fix-Its matches this string.
///   - testModuleName: The name of the test module to use.
///   - testFileName: The name of the test file name to use.
///   - indentationWidth: The indentation width used in the expansion.
public func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macroSpecs: [String: MacroSpec],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  testModuleName: String = "TestModule",
  testFileName: String = "test.swift",
  indentationWidth: Trivia = .spaces(4),
  file: StaticString = #filePath,
  line: UInt = #line
) {
  // Parse the original source file.
  let origSourceFile = Parser.parse(source: originalSource)

  // Expand all macros in the source.
  let context = BasicMacroExpansionContext(
    sourceFiles: [origSourceFile: .init(moduleName: testModuleName, fullFilePath: testFileName)]
  )

  func contextGenerator(_ syntax: Syntax) -> BasicMacroExpansionContext {
    return BasicMacroExpansionContext(sharingWith: context, lexicalContext: syntax.allMacroLexicalContexts())
  }

  let expandedSourceFile = origSourceFile.expand(
    macroSpecs: macroSpecs,
    contextGenerator: contextGenerator,
    indentationWidth: indentationWidth
  )
  let diags = ParseDiagnosticsGenerator.diagnostics(for: expandedSourceFile)
  if !diags.isEmpty {
    XCTFail(
      """
      Expanded source should not contain any syntax errors, but contains:
      \(DiagnosticsFormatter.annotatedSource(tree: expandedSourceFile, diags: diags))

      Expanded syntax tree was:
      \(expandedSourceFile.debugDescription)
      """,
      file: file,
      line: line
    )
  }

  assertStringsEqualWithDiff(
    expandedSourceFile.description.trimmingCharacters(in: .newlines),
    expectedExpandedSource.trimmingCharacters(in: .newlines),
    "Macro expansion did not produce the expected expanded source",
    additionalInfo: """
      Actual expanded source:
      \(expandedSourceFile)
      """,
    file: file,
    line: line
  )

  if context.diagnostics.count != diagnostics.count {
    XCTFail(
      """
      Expected \(diagnostics.count) diagnostics but received \(context.diagnostics.count):
      \(context.diagnostics.map(\.debugDescription).joined(separator: "\n"))
      """,
      file: file,
      line: line
    )
  } else {
    for (actualDiag, expectedDiag) in zip(context.diagnostics, diagnostics) {
      assertDiagnostic(actualDiag, in: context, expected: expectedDiag)
    }
  }

  // Applying Fix-Its
  if let expectedFixedSource = expectedFixedSource {
    let messages = applyFixIts ?? context.diagnostics.compactMap { $0.fixIts.first?.message.message }

    let edits =
      context.diagnostics
      .flatMap(\.fixIts)
      .filter { messages.contains($0.message.message) }
      .flatMap { $0.changes }
      .map { $0.edit(in: context) }

    let fixedTree = FixItApplier.apply(edits: edits, to: origSourceFile)
    let fixedTreeDescription = fixedTree.description
    assertStringsEqualWithDiff(
      fixedTreeDescription.trimmingTrailingWhitespace(),
      expectedFixedSource.trimmingTrailingWhitespace(),
      file: file,
      line: line
    )
  }
}

fileprivate extension FixIt.Change {
  /// Returns the edit for this change, translating positions from detached nodes
  /// to the corresponding locations in the original source file based on
  /// `expansionContext`.
  ///
  /// - SeeAlso: `FixIt.Change.edit`
  func edit(in expansionContext: BasicMacroExpansionContext) -> SourceEdit {
    switch self {
    case .replace(let oldNode, let newNode):
      let start = expansionContext.position(of: oldNode.position, anchoredAt: oldNode)
      let end = expansionContext.position(of: oldNode.endPosition, anchoredAt: oldNode)
      return SourceEdit(
        range: start..<end,
        replacement: newNode.description
      )

    case .replaceLeadingTrivia(let token, let newTrivia):
      let start = expansionContext.position(of: token.position, anchoredAt: token)
      let end = expansionContext.position(of: token.positionAfterSkippingLeadingTrivia, anchoredAt: token)
      return SourceEdit(
        range: start..<end,
        replacement: newTrivia.description
      )

    case .replaceTrailingTrivia(let token, let newTrivia):
      let start = expansionContext.position(of: token.endPositionBeforeTrailingTrivia, anchoredAt: token)
      let end = expansionContext.position(of: token.endPosition, anchoredAt: token)
      return SourceEdit(
        range: start..<end,
        replacement: newTrivia.description
      )
    }
  }
}

fileprivate extension BasicMacroExpansionContext {
  /// Translates a position from a detached node to the corresponding position
  /// in the original source file.
  func position(
    of position: AbsolutePosition,
    anchoredAt node: some SyntaxProtocol
  ) -> AbsolutePosition {
    let location = self.location(for: position, anchoredAt: Syntax(node), fileName: "")
    return AbsolutePosition(utf8Offset: location.offset)
  }
}
