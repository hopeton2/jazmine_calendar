# Dart/Flutter Style Guide

This document outlines the coding style and best practices for Dart and Flutter development in this project.

## Code Quality, Style, and Formatting

### General Guidelines

- **Follow Effective Dart**: Adhere to the [official style guide](https://dart.dev/effective-dart) for Style, Documentation, Usage, and Design.
- **Strict Linting**: Use strict analysis options and fix all diagnostics before committing code.
- **Consistent Formatting**: All code must be formatted with `dart format`.
- **Null Safety**: Design APIs with null safety from the ground up. Use `?`, `!`, `required`, and `late` appropriately.
- **Immutability**: Prefer immutable state and classes where possible. Use `final` for fields that don't change after construction.
- **Meaningful Naming**: Use clear, descriptive names following Dart conventions:
  - `UpperCamelCase` for types/classes
  - `lowerCamelCase` for members/variables
  - `lowercase_with_underscores` for files/directories/packages

### Separation of Concerns

- Keep clear separation between UI and business logic
- Widgets should focus solely on presentation concerns
- Move non-UI specific code out of widgets into appropriate service/helper classes
- Keep widget classes under 400 lines
- Avoid widget bloat by extracting reusable components

### SOLID Principles

- **Single Responsibility Principle (SRP)**: A class should have only one reason to change.
- **Open/Closed Principle (OCP)**: Software entities should be open for extension, but closed for modification.
- **Liskov Substitution Principle (LSP)**: Subtypes must be substitutable for their base types.
- **Interface Segregation Principle (ISP)**: Clients should not be forced to depend on interfaces they do not use.
- **Dependency Inversion Principle (DIP)**: Depend upon abstractions, not concretions.

## API Design

### Public API Guidelines

- **Minimal Surface**: Only expose what users *need*. Place implementation details in `lib/src/`.
- **Library Privacy**: Use leading underscores (`_`) for library-private members.
- **Intuitiveness**: Make APIs easy to understand without requiring users to read source code.
- **Consistency**: Maintain consistent naming conventions, parameter order, and behavior across the entire API.
- **Avoid Breaking Changes**: Think carefully before changing public APIs.
- **Platform Independence**: For pure Dart packages, avoid Flutter dependencies unless essential.
- **Sensible Defaults**: Provide reasonable default values for optional parameters.
- **Extensibility**: Consider how users might need to extend or customize the package's behavior.

## Documentation

### Documentation Standards

- Use `///` doc comments for *all* public APIs (classes, methods, functions, constants, typedefs).
- Explain what the API does, its parameters (`[paramName]`), return values (`Returns...`), and exceptions (`Throws...`).
- Use Markdown for formatting (code blocks, links, lists).
- Include small code examples within doc comments where helpful.

## State Management

### Internal State Management

- For state within package widgets, prefer simple approaches like ValueNotifier/ChangeNotifier
- Avoid forcing specific app-level state management solutions (Provider, Riverpod, Bloc) onto package consumers
- Ensure the package works independently with any state management approach

## Testing

### Testing Requirements

- Aim for comprehensive unit tests for all logic
- Include widget/integration tests for UI components
- Test edge cases, error conditions, and core functionality

## Dependencies

### Dependency Management

- Minimize external dependencies
- Only add dependencies that are absolutely necessary
- Use appropriate SDK constraints in `pubspec.yaml`

## Code Maintenance and Refactoring

### Stability and Compatibility

- Do not rewrite or take a completely new approach to a problem that will break existing code that was working well before
- Always consider the entire effect of changes and account for all potential impacts
- Prefer incremental improvements over complete rewrites
- Maintain backward compatibility whenever possible
- When refactoring, ensure all existing functionality continues to work as expected

## Platform Compatibility

### Cross-Platform Development

- All UI components must work properly on mobile, web, and desktop platforms
- Test UI layouts on different screen sizes and orientations
- Use responsive design principles to adapt to different form factors
- Avoid platform-specific code unless absolutely necessary
- When platform-specific code is required, use conditional imports or platform checks
- Ensure touch, mouse, and keyboard interactions work appropriately for each platform

## Internationalization, Localization, and Theming

### Global Compatibility

- UI should be fully themable and respect the app's theme settings
- All dates should be timezone-aware and properly handle different time zones
- Never hardcode text strings; use proper localization mechanisms
- Support internationalization (i18n) and localization (l10n)
- Package should support multiple languages through appropriate localization frameworks
- Use locale-aware formatting for dates, numbers, and currencies
- Ensure text displays correctly with different languages and writing systems
- Support right-to-left (RTL) layouts for appropriate languages
- Test with various locales and languages to ensure proper functionality
