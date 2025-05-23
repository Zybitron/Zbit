# Style Guidelines for Zbit - AutoPlay

To ensure consistency and readability, please follow these style guidelines when contributing to Zbit - AutoPlay scripts.

## General
- Use **AutoHotkey v2.0** syntax.
- Use UTF-8 encoding for all files.
- Add comments to explain complex logic.

## Naming Conventions
- Use `CamelCase` for function and variable names (e.g., `MyFunction`, `userInput`).
- Use descriptive names for variables and functions.
- Constants should be in all uppercase (e.g., `MAX_COUNT`).

## Formatting
- Indent with 4 spaces (no tabs).
- Keep lines under 120 characters.
- Place a space after commas and around operators (e.g., `a := b + 1`).
- Use blank lines to separate logical sections.

## Comments
- Use `;` for single-line comments.
- Use block comments for longer explanations.

## File Organization
- Group related functions together.
- Place configuration and constants at the top of the file.

## Example
```ahk2
; This is a single-line comment
myVar := 10

/*
This is a block comment
Describing the following function
*/
MyFunction(param1, param2) {
    result := param1 + param2
    return result
}
```

Thank you for helping keep the code clean and maintainable!
