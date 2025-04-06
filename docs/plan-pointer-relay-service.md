# Plan: Implement PointerRelayService for Gesture Handling

**Goal:** Resolve the gesture conflict between the scrollable `CalendarGrid` and the overlaid `EventLayoutSurface` by creating a custom pub/sub service (`PointerRelayService`) to explicitly route pointer events.

**Steps:**

1.  **Dependency Cleanup (Manual Step):**
    *   Manually remove the `pointer_interceptor` dependency from `pubspec.yaml` in the main project root (`/Applications/Dev/projects/jazmine/jazmine_calendar`).
    *   Manually remove the `pointer_interceptor` dependency from `example/pubspec.yaml`.
    *   Run `flutter pub get` in both directories to update dependencies.

2.  **Revert Previous Code Changes (Code Mode):**
    *   In `lib/src/views/widgets/calendar_grid.dart`:
        *   Remove the `import 'package:pointer_interceptor/pointer_interceptor.dart';` (if present).
        *   Remove any `PointerInterceptor` widget wrapping the `RepaintBoundary`.
        *   Ensure the `clipBehavior` on the main `Stack` is default (or `Clip.hardEdge`).
    *   In `lib/src/event_rendering/event_layout_surface.dart`:
        *   Ensure `behavior: HitTestBehavior.translucent` is set on the `GestureDetector` (this detector will be removed in step 5, but ensure the starting state is correct).
        *   Ensure the pan handlers (`_handlePanStart`, etc.) are reverted to a state before the `PointerInterceptor` or `Listener` attempts, likely the version that checked for hits before calling the ViewModel.

3.  **Create `PointerRelayService` (Code Mode):**
    *   Create a new file: `lib/src/services/pointer_relay_service.dart`.
    *   Define a singleton class `PointerRelayService`.
    *   Inside the service:
        *   Create a private `StreamController<PointerEvent>.broadcast()` named `_pointerEventController`.
        *   Expose a public `Stream<PointerEvent>` getter named `events` that returns `_pointerEventController.stream`.
        *   Create a public method `publish(PointerEvent event)` that adds the event to `_pointerEventController.sink`.
        *   Implement the singleton pattern (e.g., static instance, private constructor).
        *   Include a `dispose()` method to close the stream controller.
    *   **Mermaid Diagram:**
        ```mermaid
        classDiagram
            class PointerRelayService {
                -StreamController<PointerEvent> _pointerEventController
                +Stream<PointerEvent> events
                +publish(PointerEvent event)
                +dispose()
                +static PointerRelayService instance
                -PointerRelayService()
            }
        ```

4.  **Modify `CalendarGrid` to Publish Events (Code Mode):**
    *   In `lib/src/views/widgets/calendar_grid.dart`:
    *   Import the new `PointerRelayService`.
    *   Wrap the main `Stack` widget with a `Listener`.
    *   Implement the `Listener` callbacks to publish events *selectively*. Avoid publishing `PointerScrollEvent`s to let the framework handle scrolling.
        *   `onPointerDown: (event) => PointerRelayService.instance.publish(event)`
        *   `onPointerMove: (event) => PointerRelayService.instance.publish(event)`
        *   `onPointerUp: (event) => PointerRelayService.instance.publish(event)`
        *   `onPointerCancel: (event) => PointerRelayService.instance.publish(event)`
        *   `onPointerHover: (event) => PointerRelayService.instance.publish(event)` (Publish hover for potential use in surface)
        *   *Do not* implement `onPointerSignal` here to avoid interfering with scroll wheel.

5.  **Modify `EventLayoutSurface` to Subscribe and Handle Events (Code Mode):**
    *   In `lib/src/event_rendering/event_layout_surface.dart`:
    *   Import the `PointerRelayService`.
    *   Remove the entire `GestureDetector` widget.
    *   In `EventLayoutSurfaceState`:
        *   Add a `StreamSubscription<PointerEvent>? _pointerSubscription;`.
        *   Add state variables for active pointer tracking (`_activePointerId`, `_isDragging`, `_dragTarget`).
        *   In `initState`: Subscribe `_pointerSubscription = PointerRelayService.instance.events.listen(_handlePointerEvent);`.
        *   In `dispose`: Cancel `_pointerSubscription?.cancel();`.
        *   Create `_handlePointerEvent(PointerEvent event)`.
        *   Inside `_handlePointerEvent`:
            *   Use `if/else if` to check event types (`PointerDownEvent`, `PointerMoveEvent`, `PointerUpEvent`, `PointerCancelEvent`, `PointerHoverEvent`).
            *   **`PointerDownEvent`:** Perform hit test. If hit on event/handle, record pointer ID and target. Implement tap detection logic here (e.g., record down time/position, check against up time/position).
            *   **`PointerMoveEvent`:** If dragging is active (`_activePointerId` matches), update drag state (`_isDragging`) and call `_viewModel.handlePanStart/Update`.
            *   **`PointerUpEvent`:** If dragging, call `_viewModel.handlePanEnd`. Check for tap completion based on down/up info. Reset drag state.
            *   **`PointerCancelEvent`:** If dragging, call `_viewModel.handlePanEnd`. Reset drag state.
            *   **`PointerHoverEvent`:** Update cursor using `_updateCursorOnHover`.
        *   Remove old gesture handler methods.

**Rationale:**

This approach uses a dedicated service to explicitly manage pointer event flow between the grid and the overlay, aiming for clearer separation of concerns and resolving the gesture conflicts.