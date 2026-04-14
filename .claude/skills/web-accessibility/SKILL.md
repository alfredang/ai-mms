---
name: web-accessibility
description: Use when building or reviewing UI components for accessibility (a11y). Covers WCAG 2.1 compliance, semantic HTML, keyboard navigation, ARIA attributes, color contrast, focus management, and screen reader testing. Use when creating forms, modals, dropdowns, navigation, or any user-facing HTML.
metadata:
  version: "1.0.0"
  domain: frontend
  triggers: accessibility, a11y, WCAG, ARIA, keyboard navigation, screen reader, form, modal
---

# Web Accessibility (A11y)

Ensure all UI components are accessible to users with disabilities, following WCAG 2.1 guidelines.

## When to Use

- New UI component development
- Accessibility audit of existing pages
- Form implementation
- Modal/dropdown creation
- WCAG compliance review

## Workflow

1. **Use Semantic HTML** — meaningful elements before ARIA
2. **Implement Keyboard Navigation** — all features work without mouse
3. **Add ARIA Attributes** — context for screen readers
4. **Ensure Color Contrast** — meet WCAG ratios
5. **Test** — automated (axe-core) + manual (keyboard + screen reader)

## Semantic HTML

- Use `<button>`, `<nav>`, `<main>`, `<header>`, `<footer>` — not `<div>` for everything
- Correct heading hierarchy (`h1` through `h6`)
- Connect `<label>` with `<input>` via `for` attribute
- Semantic HTML first; ARIA is a last resort

## Keyboard Navigation

- **Tab/Shift+Tab** to move focus between elements
- **Enter/Space** to activate buttons and links
- **Arrow keys** to navigate within lists, menus, tabs
- **ESC** to close modals, dropdowns, popovers
- Use `tabindex="0"` for custom focusable elements, `tabindex="-1"` for programmatic focus
- Implement focus trap for modals (Tab cycles within modal)

## ARIA Attributes

| Attribute | Purpose |
|-----------|---------|
| `aria-label` | Define element name when no visible text |
| `aria-labelledby` | Reference another element as label |
| `aria-describedby` | Additional description (errors, help text) |
| `aria-live` | Announce dynamic content changes |
| `aria-hidden="true"` | Hide decorative elements from screen readers |
| `aria-expanded` | Toggle state for dropdowns/accordions |
| `aria-required` | Mark required form fields |
| `aria-invalid` | Mark fields with validation errors |
| `role="dialog"` | Identify modal dialogs |

## Color Contrast

- **WCAG AA**: Normal text 4.5:1, large text 3:1
- **WCAG AAA**: Normal text 7:1, large text 4.5:1
- Never convey information by color alone — use icons or text alongside
- Always provide visible focus indicators (`outline`)

## Constraints

### MUST DO
- All interactive elements keyboard accessible (Tab, Enter, Space, ESC)
- All images have `alt` attribute (descriptive for meaningful, `alt=""` for decorative)
- All form inputs have associated `<label>` or `aria-label`
- Focus trap in modals
- Visible focus indicators on all interactive elements

### MUST NOT DO
- Remove outline (`outline: none` is forbidden without visible replacement)
- Use `tabindex > 0` (breaks DOM focus order)
- Convey information by color alone
- Use `placeholder` as sole label for inputs
- Use `<div>` or `<span>` for interactive elements without `role` and keyboard handlers

## Testing Checklist

1. Tab through entire page — can you reach and operate every control?
2. Run axe-core / Lighthouse accessibility audit
3. Test with screen reader (VoiceOver on Mac, NVDA on Windows)
4. Verify contrast ratios with browser DevTools
5. Check that dynamic content updates are announced (`aria-live`)
