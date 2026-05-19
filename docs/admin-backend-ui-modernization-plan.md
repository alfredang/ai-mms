# Admin Backend UI Modernization Plan

## Goal

Modernize the Magento/OpenMage admin interface so it feels cleaner, more consistent, and usable across desktop and tablet widths without breaking core backend workflows.

The target outcome is:

- a more compact and readable admin shell
- better responsive behavior on smaller laptop and tablet screens
- less visual noise in tables, forms, and menus
- more consistent spacing, hierarchy, and interaction states
- a maintainable admin theme layer instead of one-off overrides

## Current Constraints

This codebase is running OpenMage/Magento 1 admin UI, which means:

- the admin markup is legacy and table-heavy
- menu behavior is driven by old CSS assumptions and hover interactions
- many layout widths are fixed or semi-fixed
- theme overrides currently live mostly in custom admin templates and CSS

Current implementation surfaces already in use:

- [skin/adminhtml/default/default/dark-theme.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/dark-theme.css:1)
- [skin/adminhtml/default/default/menu.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/menu.css:1)
- [skin/adminhtml/default/default/boxes.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/boxes.css:1)
- [app/design/adminhtml/default/default/template/page/header.phtml](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/template/page/header.phtml:1)
- [app/design/adminhtml/default/default/template/page/menu.phtml](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/template/page/menu.phtml:1)
- [app/design/adminhtml/default/default/layout/main.xml](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/layout/main.xml:1)

## Design Direction

The backend should move toward a modern admin style with:

- dark, low-glare shell with cleaner contrast hierarchy
- compact but readable navigation
- lighter use of borders and separators
- stronger spacing rhythm instead of stacked chrome
- flatter panel design with selective elevation
- more consistent control sizing
- responsive wrapping of filters, search, actions, and pagination

This should not aim to mimic generic SaaS dashboards. It should preserve Magento admin density, but remove friction.

## UX Priorities

1. Navigation should be predictable.
2. Grids should stay usable at smaller widths.
3. Filters and action bars should wrap instead of collide.
4. Forms should scan faster and feel less crowded.
5. Visual hierarchy should come from spacing and typography, not repeated lines.

## Implementation Strategy

### Phase 1: Stabilize the Admin Shell

Focus:

- top header
- logo/title alignment
- global search
- top navigation
- dropdown behavior
- page spacing

Deliverables:

- normalize header height and spacing
- make top nav compact and aligned
- clean dropdown sizing and separators
- ensure dropdowns open reliably over content
- reduce top-level border duplication
- standardize page gutters and content spacing

Primary files:

- [dark-theme.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/dark-theme.css:1)
- [header.phtml](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/template/page/header.phtml:1)
- [menu.phtml](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/template/page/menu.phtml:1)

Success criteria:

- nav dropdowns no longer feel oversized
- no stacked/double dividers in menus
- header alignment feels balanced
- shell remains visually stable at 1024px and 1280px widths

### Phase 2: Establish a Reusable Admin Design System

Focus:

- visual tokens
- spacing scale
- typography scale
- radius and borders
- shadows and focus states

Deliverables:

- split generic variables and rules from page-specific overrides
- define a compact token layer for:
  - color roles
  - spacing scale
  - radii
  - shadows
  - control heights
  - font sizes
- unify button, input, select, textarea, notice, and panel styles

Recommended structure:

- `skin/adminhtml/default/default/dark-theme.css`
  - keep as temporary integration layer
- add:
  - `skin/adminhtml/default/default/admin-tokens.css`
  - `skin/adminhtml/default/default/admin-layout.css`
  - `skin/adminhtml/default/default/admin-components.css`
  - `skin/adminhtml/default/default/admin-responsive.css`

Success criteria:

- control sizing becomes consistent
- spacing no longer varies heavily between modules
- styling changes become easier to reason about

### Phase 3: Redesign Data Grids and Utility Rows

Focus:

- filters
- massaction
- pager
- export controls
- table readability

Why this matters:

Most daily admin work happens inside grids. This is the highest leverage area after the shell.

Deliverables:

- convert rigid toolbars into responsive wrapping rows
- reduce unnecessary borders and nested containers
- improve spacing between filter inputs and actions
- make select/button groups align cleanly
- improve row density without making the UI cramped
- add graceful horizontal scrolling only where unavoidable

Primary files:

- [dark-theme.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/dark-theme.css:1)
- [boxes.css](/Users/alfredang/projects/tertiary/ai-mms/skin/adminhtml/default/default/boxes.css:1)
- custom grid templates under [app/design/adminhtml/default/default/template](/Users/alfredang/projects/tertiary/ai-mms/app/design/adminhtml/default/default/template:1)

Success criteria:

- customer/catalog/order grids remain usable at 1024px
- filters do not overflow or overlap controls
- actions and pager remain readable and clickable

### Phase 4: Modernize Forms and Edit Screens

Focus:

- fieldsets
- labels
- grouped inputs
- admin edit pages
- sidebars

Deliverables:

- reduce overuse of boxed sections
- use spacing to separate logical groups
- modernize labels, helper text, and validation messages
- standardize field heights and input states
- improve sidebar and tab styling
- collapse multi-column layouts more cleanly at smaller widths

Success criteria:

- edit screens feel less noisy
- long forms scan faster
- validation is clearer
- controls look consistent across modules

### Phase 5: Responsive Behavior Across Breakpoints

Focus:

- overall shell responsiveness
- nav fallback behavior
- grid toolbars
- form stacking

Target breakpoints:

- `1440px+`: full desktop
- `1280px`: standard laptop
- `1024px`: small laptop/tablet landscape
- `768px`: tablet baseline

Expected behavior:

- top nav becomes more compact at smaller widths
- search box and account info stop fighting for horizontal space
- page actions wrap before clipping
- grids scroll horizontally only when needed
- filters become stacked or multi-row cleanly
- edit forms collapse into simpler vertical layouts

Success criteria:

- common admin pages remain usable at all target widths
- no clipped menus, toolbars, or actions
- no horizontal overflow caused by header or nav alone

### Phase 6: QA and Hardening

Focus:

- visual regression checks
- page-by-page validation
- module-specific edge cases

Priority test pages:

- dashboard
- customers grid
- catalog product grid
- catalog category screens
- orders grid and order detail
- CMS pages
- reports
- store config

Validation checklist:

- header alignment
- nav open states
- dropdown compactness
- button consistency
- filter usability
- grid readability
- form spacing
- tablet-width behavior

## Recommended First Execution Pass

If implementing this now, the best order is:

1. finish shell cleanup
2. extract token/component/layout layers
3. stabilize grids and action bars
4. modernize forms
5. add breakpoint-specific responsive rules
6. run screen-by-screen QA

## Specific Improvements To Target

### Header

- reduce visual weight in the top shell
- align logo, title, user info, and search cleanly
- constrain search width responsively
- use fewer border lines

### Navigation

- compact top-level items slightly
- improve spacing and hover feedback
- make dropdown width content-aware but capped
- remove double borders and legacy submenu textures
- define tablet fallback behavior

### Tables and Grids

- simplify header backgrounds
- reduce excessive grid chrome
- keep strong contrast for headers, weaker contrast for separators
- align filter inputs with action controls
- improve selection and hover states

### Buttons and Controls

- standardize heights and corner radius
- reduce exaggerated shadows
- unify primary, secondary, destructive, and neutral actions
- strengthen focus visibility

### Forms

- use cleaner group spacing
- reduce panel nesting
- improve labels and helper spacing
- modernize input and select appearance

## Risks

- Magento admin HTML is inconsistent across screens, so some targeted overrides will still be necessary.
- Table-heavy pages may resist fully fluid layouts without selective exceptions.
- Some module templates may need local fixes rather than global CSS alone.
- Aggressive global overrides can regress older admin pages if not validated incrementally.

## Guardrails

- avoid changing PHP layout structure unless needed for responsiveness
- prefer layered CSS refactors over massive template rewrites
- keep overrides scoped to admin theme surfaces
- validate each phase against at least 3 high-traffic admin pages before expanding

## Suggested Deliverables

1. Admin shell cleanup
2. Tokenized component layer
3. Responsive grid toolkit
4. Responsive form toolkit
5. Final QA checklist and screenshot pass

## Immediate Next Step

The next practical step is to execute Phase 1 and Phase 2 together:

- finish menu/header cleanup
- extract admin tokens/components/layout CSS
- set initial responsive rules for header, nav, and page actions

That gives the rest of the backend a stable base before touching every grid and form.
