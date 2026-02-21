# Agent Guidelines

## Skill 1: SwiftUI Expert

Write, review, or improve SwiftUI code following best practices for state management, view composition, performance, modern APIs, Swift concurrency, and iOS 26+ Liquid Glass adoption. Use when building new SwiftUI features, refactoring existing views, reviewing code quality, or adopting modern SwiftUI patterns.

### Overview

Use this skill to build, review, or improve SwiftUI features with correct state management, modern API usage, Swift concurrency best practices, optimal view composition, and iOS 26+ Liquid Glass styling. Prioritize native APIs, Apple design guidance, and performance-conscious patterns. This skill focuses on facts and best practices without enforcing specific architectural patterns.

### Workflow Decision Tree

#### 1) Review existing SwiftUI code
- Check property wrapper usage against the selection guide (see State Management section)
- Verify modern API usage (see Modern APIs section)
- Verify view composition follows extraction rules (see View Structure section)
- Check performance patterns are applied (see Performance section)
- Verify list patterns use stable identity (see List Patterns section)
- Check animation patterns for correctness (see Animation sections)
- Inspect Liquid Glass usage for correctness and consistency (see Liquid Glass section)
- Validate iOS 26+ availability handling with sensible fallbacks

#### 2) Improve existing SwiftUI code
- Audit state management for correct wrapper selection (prefer `@Observable` over `ObservableObject`)
- Replace deprecated APIs with modern equivalents (see Modern APIs section)
- Extract complex views into separate subviews (see View Structure section)
- Refactor hot paths to minimize redundant state updates (see Performance section)
- Ensure ForEach uses stable identity (see List Patterns section)
- Improve animation patterns (use value parameter, proper transitions)
- Suggest image downsampling when `UIImage(data:)` is used (as optional optimization)
- Adopt Liquid Glass only when explicitly requested by the user

#### 3) Implement new SwiftUI feature
- Design data flow first: identify owned vs injected state (see State Management section)
- Use modern APIs (no deprecated modifiers or patterns)
- Use `@Observable` for shared state (with `@MainActor` if not using default actor isolation)
- Structure views for optimal diffing (extract subviews early, keep views small)
- Separate business logic into testable models
- Use correct animation patterns (implicit vs explicit, transitions)
- Apply glass effects after layout/appearance modifiers (see Liquid Glass section)
- Gate iOS 26+ features with `#available` and provide fallbacks

### Core Guidelines

#### State Management
- **Always prefer `@Observable` over `ObservableObject`** for new code
- **Mark `@Observable` classes with `@MainActor`** unless using default actor isolation
- **Always mark `@State` and `@StateObject` as `private`** (makes dependencies clear)
- **Never declare passed values as `@State` or `@StateObject`** (they only accept initial values)
- Use `@State` with `@Observable` classes (not `@StateObject`)
- `@Binding` only when child needs to **modify** parent state
- `@Bindable` for injected `@Observable` objects needing bindings
- Use `let` for read-only values; `var` + `.onChange()` for reactive reads
- Legacy: `@StateObject` for owned `ObservableObject`; `@ObservedObject` for injected
- Nested `ObservableObject` doesn't work (pass nested objects directly); `@Observable` handles nesting fine

##### Property Wrapper Selection (Modern)
| Wrapper | Use When |
|---------|----------|
| `@State` | Internal view state (must be `private`), or owned `@Observable` class |
| `@Binding` | Child modifies parent's state |
| `@Bindable` | Injected `@Observable` needing bindings |
| `let` | Read-only value from parent |
| `var` | Read-only value watched via `.onChange()` |

**Legacy (Pre-iOS 17):**
| Wrapper | Use When |
|---------|----------|
| `@StateObject` | View owns an `ObservableObject` (use `@State` with `@Observable` instead) |
| `@ObservedObject` | View receives an `ObservableObject` |

##### Decision Flowchart
```
Is this value owned by this view?
├─ YES: Is it a simple value type?
│       ├─ YES → @State private var
│       └─ NO (class):
│           ├─ Use @Observable → @State private var (mark class @MainActor)
│           └─ Legacy ObservableObject → @StateObject private var
│
└─ NO (passed from parent):
    ├─ Does child need to MODIFY it?
    │   ├─ YES → @Binding var
    │   └─ NO: Does child need BINDINGS to its properties?
    │       ├─ YES (@Observable) → @Bindable var
    │       └─ NO: Does child react to changes?
    │           ├─ YES → var + .onChange()
    │           └─ NO → let
    │
    └─ Is it a legacy ObservableObject from parent?
        └─ YES → @ObservedObject var (consider migrating to @Observable)
```

##### @State with @Observable (Preferred)
```swift
@Observable
@MainActor
final class DataModel {
    var name = "Some Name"
    var count = 0
}

struct MyView: View {
    @State private var model = DataModel()

    var body: some View {
        VStack {
            TextField("Name", text: $model.name)
            Stepper("Count: \(model.count)", value: $model.count)
        }
    }
}
```

##### Don't Pass Values as @State
```swift
// Wrong - child ignores updates from parent
struct ChildView: View {
    @State var item: Item  // Accepts initial value only!
}

// Correct - child receives updates
struct ChildView: View {
    let item: Item  // Or @Binding if child needs to modify
}
```

##### @Bindable (iOS 17+)
```swift
struct EditUserView: View {
    @Bindable var user: UserModel  // Received from parent, needs bindings

    var body: some View {
        Form {
            TextField("Name", text: $user.name)
            TextField("Email", text: $user.email)
        }
    }
}
```

##### Avoid Nested ObservableObject
This limitation only applies to `ObservableObject`. `@Observable` fully supports nested observed objects. Pass nested `ObservableObject` instances directly to child views as a workaround.

#### Modern APIs
- Use `foregroundStyle()` instead of `foregroundColor()`
- Use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`
- Use `Tab` API instead of `tabItem()`
- Use `Button` instead of `onTapGesture()` (unless need location/count)
- Use `NavigationStack` instead of `NavigationView`
- Use `navigationDestination(for:)` for type-safe navigation
- Use two-parameter or no-parameter `onChange()` variant
- Use `ImageRenderer` for rendering SwiftUI views
- Use `.sheet(item:)` instead of `.sheet(isPresented:)` for model-based content
- Sheets should own their actions and call `dismiss()` internally
- Use `ScrollViewReader` for programmatic scrolling with stable IDs
- Avoid `UIScreen.main.bounds` for sizing
- Avoid `GeometryReader` when alternatives exist (e.g., `containerRelativeFrame()`)

##### Modern API Replacements
| Deprecated | Modern Alternative |
|------------|-------------------|
| `foregroundColor()` | `foregroundStyle()` |
| `cornerRadius()` | `clipShape(.rect(cornerRadius:))` |
| `tabItem()` | `Tab` API |
| `onTapGesture()` | `Button` (unless need location/count) |
| `NavigationView` | `NavigationStack` |
| `onChange(of:) { value in }` | `onChange(of:) { old, new in }` or `onChange(of:) { }` |
| `fontWeight(.bold)` | `bold()` |
| `GeometryReader` | `containerRelativeFrame()` or `visualEffect()` |
| `showsIndicators: false` | `.scrollIndicators(.hidden)` |
| `String(format: "%.2f", value)` | `Text(value, format: .number.precision(.fractionLength(2)))` |
| `string.contains(search)` | `string.localizedStandardContains(search)` (for user input) |

#### Swift Best Practices
- Use modern Text formatting (`.format` parameters, not `String(format:)`)
- Use `localizedStandardContains()` for user-input filtering (not `contains()`)
- Prefer static member lookup (`.blue` vs `Color.blue`)
- Use `.task` modifier for automatic cancellation of async work
- Use `.task(id:)` for value-dependent tasks

#### View Composition
- **Prefer modifiers over conditional views** for state changes (maintains view identity)
- Extract complex views into separate subviews for better readability and performance
- Keep views small for optimal performance
- Keep view `body` simple and pure (no side effects or complex logic)
- Use `@ViewBuilder` functions only for small, simple sections
- Prefer `@ViewBuilder let content: Content` over closure-based content properties
- Separate business logic into testable models (not about enforcing architectures)
- Action handlers should reference methods, not contain inline logic
- Use relative layout over hard-coded constants
- Views should work in any context (don't assume screen size or presentation style)

##### Prefer Modifiers Over Conditional Views
```swift
// Good - same view, different states
SomeView()
    .opacity(isVisible ? 1 : 0)

// Avoid - creates/destroys view identity
if isVisible {
    SomeView()
}
```

##### Extract Subviews, Not Computed Properties
```swift
// BAD - re-executes complexSection() on every tap
struct ParentView: View {
    @State private var count = 0
    var body: some View {
        VStack {
            Button("Tap: \(count)") { count += 1 }
            complexSection()  // Re-executes every tap!
        }
    }
    @ViewBuilder
    func complexSection() -> some View { /* ... */ }
}

// GOOD - ComplexSection body SKIPPED when its inputs don't change
struct ParentView: View {
    @State private var count = 0
    var body: some View {
        VStack {
            Button("Tap: \(count)") { count += 1 }
            ComplexSection()  // Body skipped during re-evaluation
        }
    }
}
```

##### Container View Pattern
```swift
// GOOD - view can be compared
struct MyContainer<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack {
            Text("Header")
            content
        }
    }
}

// BAD - closure prevents SwiftUI from skipping updates
struct MyContainer<Content: View>: View {
    let content: () -> Content
    // ...
}
```

##### ZStack vs overlay/background
Use `ZStack` to compose multiple peer views that should be layered together and jointly define layout. Prefer `overlay`/`background` when decorating a primary view. In `overlay`/`background`, the child view implicitly adopts the size proposed to the parent. In `ZStack`, each child participates independently in layout.

#### Performance
- Pass only needed values to views (avoid large "config" or "context" objects)
- Eliminate unnecessary dependencies to reduce update fan-out
- Check for value changes before assigning state in hot paths
- Avoid redundant state updates in `onReceive`, `onChange`, scroll handlers
- Minimize work in frequently executed code paths
- Use `LazyVStack`/`LazyHStack` for large lists
- Use stable identity for `ForEach` (never `.indices` for dynamic content)
- Ensure constant number of views per `ForEach` element
- Avoid inline filtering in `ForEach` (prefilter and cache)
- Avoid `AnyView` in list rows
- Consider POD views for fast diffing (or wrap expensive views in POD parents)
- Suggest image downsampling when `UIImage(data:)` is encountered (as optional optimization)
- Avoid layout thrash (deep hierarchies, excessive `GeometryReader`)
- Gate frequent geometry updates by thresholds
- Use `Self._printChanges()` to debug unexpected view updates

##### Avoid Redundant State Updates
```swift
// BAD - triggers update even if value unchanged
.onReceive(publisher) { value in
    self.currentValue = value
}

// GOOD - only update when different
.onReceive(publisher) { value in
    if self.currentValue != value {
        self.currentValue = value
    }
}
```

##### Anti-Patterns
```swift
// BAD - creates new formatter every body call
var body: some View {
    let formatter = DateFormatter()
    // ...
}

// GOOD - static or stored formatter
private static let dateFormatter: DateFormatter = { /* ... */ }()
```

#### List Patterns
- **Always provide stable identity for `ForEach`** - never use `.indices` for dynamic content
- Ensure constant number of views per element in `ForEach`
- Avoid inline filtering in `ForEach` (prefilter and cache)
- Avoid `AnyView` in list rows
- Always convert enumerated sequences to arrays for ForEach

```swift
// Good - stable identity via Identifiable
ForEach(users) { user in
    UserRow(user: user)
}

// Wrong - indices create static content
ForEach(users.indices, id: \.self) { index in
    UserRow(user: users[index])  // Can crash on removal!
}

// Good - prefilter and cache
@State private var enabledItems: [Item] = []
ForEach(enabledItems) { item in
    ItemRow(item: item)
}
.onChange(of: items) { _, newItems in
    enabledItems = newItems.filter { $0.isEnabled }
}
```

#### Animations

##### Animation Basics
- Use `.animation(_:value:)` with value parameter (deprecated version without value is too broad)
- Use `withAnimation` for event-driven animations (button taps, gestures)
- Prefer transforms (`offset`, `scale`, `rotation`) over layout changes (`frame`) for performance
- Transitions require animations outside the conditional structure
- Custom `Animatable` implementations must have explicit `animatableData`
- Implicit animations override explicit animations (later in view tree wins)

```swift
// GOOD - uses value parameter
Rectangle()
    .frame(width: isExpanded ? 200 : 100, height: 50)
    .animation(.spring, value: isExpanded)

// BAD - deprecated, animates all changes unexpectedly
Rectangle()
    .animation(.spring)  // Deprecated!
```

##### Timing Curves
| Curve | Use Case |
|-------|----------|
| `.spring` | Interactive elements, most UI |
| `.easeInOut` | Appearance changes |
| `.bouncy` | Playful feedback (iOS 17+) |
| `.linear` | Progress indicators only |

##### Animation Performance
```swift
// GOOD - GPU accelerated transforms
Rectangle()
    .scaleEffect(isActive ? 1.5 : 1.0)
    .offset(x: isActive ? 50 : 0)

// BAD - layout changes are expensive
Rectangle()
    .frame(width: isActive ? 150 : 100, height: isActive ? 150 : 100)
```

##### Transitions
```swift
// GOOD - animation outside conditional
VStack {
    if showDetail {
        DetailView()
            .transition(.slide)
    }
}
.animation(.spring, value: showDetail)

// BAD - animation inside conditional (removed with view!)
if showDetail {
    DetailView()
        .transition(.slide)
        .animation(.spring, value: showDetail)  // Won't work on removal!
}
```

##### Phase Animations (iOS 17+)
Use `.phaseAnimator` for multi-step sequences. Prefer enum phases for clarity.
```swift
enum BouncePhase: CaseIterable {
    case initial, up, down, settle
    var scale: CGFloat {
        switch self {
        case .initial: 1.0
        case .up: 1.2
        case .down: 0.9
        case .settle: 1.0
        }
    }
}

Circle()
    .phaseAnimator(BouncePhase.allCases, trigger: trigger) { content, phase in
        content.scaleEffect(phase.scale)
    }
```

##### Keyframe Animations (iOS 17+)
Use `.keyframeAnimator` for precise timing control. Tracks run in parallel.
```swift
Button("Bounce") { trigger += 1 }
    .keyframeAnimator(initialValue: AnimationValues(), trigger: trigger) { content, value in
        content.scaleEffect(value.scale).offset(y: value.verticalOffset)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.15)
            SpringKeyframe(0.9, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.15)
        }
        KeyframeTrack(\.verticalOffset) {
            LinearKeyframe(-20, duration: 0.15)
            LinearKeyframe(0, duration: 0.25)
        }
    }
```

##### Transactions
- `withTransaction` is the explicit form of `withAnimation`
- Implicit animations override explicit (later in view tree wins)
- Use `disablesAnimations` to prevent override
- Use `.transaction { $0.animation = nil }` to remove animation

##### Animation Completion Handlers (iOS 17+)
```swift
// GOOD - completion with withAnimation
withAnimation(.spring) {
    isExpanded.toggle()
} completion: {
    showNextStep = true
}

// GOOD - completion fires on every trigger change
.transaction(value: bounceCount) { transaction in
    transaction.animation = .spring
    transaction.addAnimationCompletion {
        message = "Bounce \(bounceCount) complete"
    }
}
```

#### Sheet & Navigation Patterns
- Use `.sheet(item:)` for model-based sheets
- Sheets own their actions and dismiss internally
- Use `NavigationStack` with `navigationDestination(for:)` for type-safe navigation
- Use `NavigationPath` for programmatic navigation

```swift
// Good - item-driven
@State private var selectedItem: Item?
List(items) { item in
    Button(item.name) { selectedItem = item }
}
.sheet(item: $selectedItem) { item in
    ItemDetailSheet(item: item)
}
```

#### ScrollView Patterns
- Use `.scrollIndicators(.hidden)` instead of `showsIndicators: false`
- Use `ScrollViewReader` with stable IDs for programmatic scrolling
- Gate frequent scroll position updates by thresholds
- Use `.visualEffect` for scroll-based visual changes (iOS 17+)
- Use `.scrollTargetBehavior(.paging)` for paging (iOS 17+)
- Use `.scrollTargetBehavior(.viewAligned)` for snap-to-item (iOS 17+)

#### Text Formatting
- Never use C-style `String(format:)` with Text - use `.format` parameters
- Use `localizedStandardContains()` for user-input filtering
- Use `localizedStandardCompare()` for locale-aware sorting

```swift
// Modern
Text(value, format: .number.precision(.fractionLength(2)))
Text(price, format: .currency(code: "USD"))
Text(percentage, format: .percent.precision(.fractionLength(1)))
Text(date, format: .dateTime.day().month().year())
```

#### Image Optimization
- Use `AsyncImage` with proper phase handling (empty, success, failure)
- When encountering `UIImage(data:)`, suggest downsampling as optional optimization
- Decode and downsample images off the main thread using `CGImageSource`
- Use `ImageRenderer` for rendering SwiftUI views to images

#### Layout Best Practices
- Use dynamic layout calculations instead of hard-coded values
- Views should work in any context (don't assume screen size)
- Custom views should own static containers but not lazy/repeatable ones
- Avoid deep view hierarchies (layout thrash)
- Gate frequent geometry updates by thresholds
- Prefer `containerRelativeFrame()` over `GeometryReader` (iOS 17+)

#### Liquid Glass (iOS 26+)
**Only adopt when explicitly requested by the user.**
- Use native `glassEffect`, `GlassEffectContainer`, and glass button styles
- Wrap multiple glass elements in `GlassEffectContainer`
- Apply `.glassEffect()` after layout and visual modifiers
- Use `.interactive()` only for tappable/focusable elements
- Use `glassEffectID` with `@Namespace` for morphing transitions

```swift
// Basic glass effect with fallback
if #available(iOS 26, *) {
    content
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
} else {
    content
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
}

// Grouped glass elements
GlassEffectContainer(spacing: 24) {
    HStack(spacing: 24) {
        GlassButton1()
        GlassButton2()
    }
}

// Glass buttons
Button("Confirm") { }
    .buttonStyle(.glassProminent)
```

### Review Checklist

#### State Management
- [ ] Using `@Observable` instead of `ObservableObject` for new code
- [ ] `@Observable` classes marked with `@MainActor` (if needed)
- [ ] Using `@State` with `@Observable` classes (not `@StateObject`)
- [ ] `@State` and `@StateObject` properties are `private`
- [ ] Passed values NOT declared as `@State` or `@StateObject`
- [ ] `@Binding` only where child modifies parent state
- [ ] `@Bindable` for injected `@Observable` needing bindings

#### Modern APIs
- [ ] Using `foregroundStyle()` instead of `foregroundColor()`
- [ ] Using `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`
- [ ] Using `Tab` API instead of `tabItem()`
- [ ] Using `Button` instead of `onTapGesture()`
- [ ] Using `NavigationStack` instead of `NavigationView`
- [ ] Avoiding `UIScreen.main.bounds`
- [ ] Button images include text labels for accessibility

#### View Structure
- [ ] Using modifiers instead of conditionals for state changes
- [ ] Complex views extracted to separate subviews
- [ ] Views kept small for performance
- [ ] Container views use `@ViewBuilder let content: Content`

#### Performance
- [ ] View `body` kept simple and pure (no side effects)
- [ ] Passing only needed values (not large config objects)
- [ ] State updates check for value changes before assigning
- [ ] No object creation in `body`
- [ ] Heavy computation moved out of `body`

#### List Patterns
- [ ] ForEach uses stable identity (not `.indices`)
- [ ] Constant number of views per ForEach element
- [ ] No inline filtering in ForEach
- [ ] No `AnyView` in list rows

#### Animations
- [ ] Using `.animation(_:value:)` with value parameter
- [ ] Using `withAnimation` for event-driven animations
- [ ] Transitions paired with animations outside conditional structure
- [ ] Preferring transforms over layout changes for animation performance

#### Liquid Glass (iOS 26+)
- [ ] `#available(iOS 26, *)` with fallback
- [ ] Multiple glass views wrapped in `GlassEffectContainer`
- [ ] `.glassEffect()` applied after layout/appearance modifiers
- [ ] `.interactive()` only on user-interactable elements

### Philosophy
This skill focuses on **facts and best practices**, not architectural opinions:
- We don't enforce specific architectures (e.g., MVVM, VIPER)
- We do encourage separating business logic for testability
- We prioritize modern APIs over deprecated ones
- We emphasize thread safety with `@MainActor` and `@Observable`
- We optimize for performance and maintainability
- We follow Apple's Human Interface Guidelines and API design patterns

---

## Skill 2: Practical Animation Tips

7 practical animation principles to make UI animations feel polished and professional. Apply these when implementing any animations in the app.

### 1. Scale Your Buttons
Provide immediate user feedback by adding a subtle scale-down effect when buttons are pressed. A scale of `0.97` on press should do the job.

```swift
// SwiftUI equivalent
Button("Action") { }
    .scaleEffect(isPressed ? 0.97 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
```

### 2. Don't Animate from scale(0)
Avoid starting animations from completely invisible (scale 0). Instead, begin from higher initial scales (0.9+). It makes the movement feel more gentle, natural, and elegant. Even deflated balloons retain visible shape rather than vanishing entirely.

```swift
// GOOD - animate from near-full size
.scaleEffect(isVisible ? 1.0 : 0.9)
.opacity(isVisible ? 1 : 0)

// BAD - animating from nothing
.scaleEffect(isVisible ? 1.0 : 0)
```

### 3. Don't Delay Subsequent Tooltips
Use initial delays on first tooltip appearance, but remove delays when hovering between already-open tooltips. This feels faster without sacrificing the purpose of preventing accidental activation.

### 4. Choose the Right Easing
Easing is the most critical animation component. For UI elements entering/exiting, use `ease-out` (accelerates at the beginning, creating a sense of responsiveness and speed). Built-in easing curves are often insufficient - custom easing curves provide better results. Identical durations feel different with different easing functions.

```swift
// Good - responsive spring for interactive elements
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { }

// Good - ease out for entries
withAnimation(.easeOut(duration: 0.2)) { }

// Bad - linear feels robotic
withAnimation(.linear(duration: 0.3)) { }
```

### 5. Make Animations Origin-Aware
Scale popovers and menus from their trigger point by using appropriate transform origins rather than the default center. This creates a natural connection between the trigger and the animated content. "Unseen details combine to produce something that's just stunning, like a thousand barely audible voices all singing in tune."

### 6. Keep Animations Fast
Maintain animation durations under 300ms for optimal perceived performance. Faster spinners create illusions of quicker loading. Remove animations seen repeatedly throughout the day - they become annoying rather than delightful. A 180ms animation feels noticeably more responsive than 400ms for the same interaction.

```swift
// Good - fast, responsive
withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { }

// Bad - too slow for frequent interactions
withAnimation(.easeInOut(duration: 0.5)) { }
```

### 7. Use Blur When Nothing Else Works
Add blur when other timing and easing adjustments fail to achieve smoothness. Blur works because it bridges the visual gap between old and new states, blending them together and tricking perception. Particularly effective for simple crossfade animations between states.

```swift
// Blur transition for smooth state changes
content
    .blur(radius: isTransitioning ? 4 : 0)
    .opacity(isTransitioning ? 0.8 : 1)
    .animation(.easeOut(duration: 0.15), value: isTransitioning)
```
