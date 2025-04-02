# Plan: Diagnose and Fix Event Positioning &amp; Scrolling Issue

**Goal:** Ensure events are rendered at the correct time slot initially and scroll correctly with the `CalendarGrid`.

**Plan:**

**Phase 1: Information Gathering &amp; Analysis**

1.  **Examine `TimePositionService`:**
    *   **Action:** Read `lib/src/services/time_position_service.dart`.
    *   **Purpose:** Understand how `DateTime` is converted to a vertical pixel offset. Verify the logic (e.g., pixels per hour/minute calculation).
2.  **Examine `EventLayoutService`:**
    *   **Action:** Read `lib/src/event_rendering/event_layout_service.dart`.
    *   **Purpose:** See how it uses `TimePositionService` and potentially `GridLayoutBroker` data to calculate the initial `top` and `height` for event layout.
3.  **Examine `CalendarGrid` &amp; `EventLayoutSurface`:**
    *   **Action:** Read `lib/src/views/widgets/calendar_grid.dart` and `lib/src/event_rendering/event_layout_surface.dart`.
    *   **Purpose:** Understand how the scroll offset is detected (`ScrollController` in `CalendarGrid`?) and passed to `EventLayoutSurface` and then to `EventRenderer`.
4.  **Examine `EventRenderer`:**
    *   **Action:** Read `lib/src/event_rendering/event_renderer.dart`.
    *   **Purpose:** Analyze the `paint` method. How does it combine the initial layout info (from `EventLayoutService`) and the scroll offset to determine the final drawing position? Confirm the offset math is correct (e.g., `final drawTop = initialTop - scrollOffset;`).

**Phase 2: Hypothesis Verification &amp; Solution Design**

1.  **Trace Data Flow:** Mentally trace the calculations for a sample event through the components identified in Phase 1.
    *   Event Time -> `TimePositionService` -> Initial Pixel Offset
    *   Initial Pixel Offset -> `EventLayoutService` -> Event Layout Info (top, height)
    *   Event Layout Info -> `EventLayoutSurfaceViewModel` -> `EventRenderer`
    *   `CalendarGrid` Scroll -> Scroll Offset -> `EventLayoutSurface` -> `EventRenderer`
    *   `EventRenderer`: `paint` method combines Event Layout Info + Scroll Offset -> Final Draw Position.
2.  **Identify Discrepancy:** Pinpoint where the calculation deviates from the expected behavior.
    *   Is the initial position calculation in `EventLayoutService` (using `TimePositionService`) incorrect?
    *   Is the scroll offset value incorrect?
    *   Is the scroll offset being applied incorrectly in `EventRenderer` (e.g., applied twice, not applied, wrong sign)?
    *   Is there a mismatch between how `TimePositionService` calculates position and how the grid itself is laid out?
3.  **Formulate Solution:** Based on the identified discrepancy, design the necessary code changes. This might involve correcting logic in one or more services/widgets or adjusting how data (especially the scroll offset) is passed between them.

**Phase 3: Implementation &amp; Testing (To be done in Code Mode)**

1.  **Apply Code Changes:** Modify the relevant `.dart` files based on the solution designed in Phase 2.
2.  **Test Thoroughly:**
    *   **Basic Functionality:** Create events at specific times (e.g., 9:00 AM, 2:30 PM) and verify their initial rendering position is correct relative to the time labels on the grid.
    *   **Scrolling:** Scroll the grid up and down. Confirm events move pixel-for-pixel with the grid lines, maintaining their correct time slot position.
    *   **Edge Cases:** Test events starting at the very beginning of the view (e.g., 00:00), ending at the very end, very short events (e.g., 15 minutes), and very long events (spanning multiple hours).
    *   **Different Views:** If the rendering logic is shared, test in Day, Week, Work Week, and Timeline views.
    *   **Interactions:** Ensure tapping, dragging, and resizing events still work correctly after the changes.

**Visualizing the Interaction (Mermaid Diagram):**

```mermaid
graph TD
    subgraph CalendarGrid
        ScrollController -- Scroll Offset --> EventLayoutSurface
    end

    subgraph Event Rendering
        EventLayoutSurface -- Scroll Offset &amp; Event Data --> EventLayoutSurfaceViewModel
        EventLayoutSurfaceViewModel -- Event Layout Request --> EventLayoutService
        EventLayoutService -- Time --> TimePositionService
        TimePositionService -- Pixel Offset --> EventLayoutService
        EventLayoutService -- Event Layout Info --> EventLayoutSurfaceViewModel
        EventLayoutSurfaceViewModel -- Event Layout Info &amp; Scroll Offset --> EventRenderer
        EventRenderer -- Draws on Canvas --> EventLayoutSurface
    end

    CalendarController -- Manages State --> EventLayoutService
    GridLayoutBroker -- Layout Context --> EventLayoutService
    GridLayoutBroker -- Layout Context --> TimePositionService

    style EventRenderer fill:#f9f,stroke:#333,stroke-width:2px
    style TimePositionService fill:#ccf,stroke:#333,stroke-width:2px
    style EventLayoutService fill:#cfc,stroke:#333,stroke-width:2px