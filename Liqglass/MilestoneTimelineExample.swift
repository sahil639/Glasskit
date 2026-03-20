//
//  MilestoneTimelineExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Supporting Types

struct MilestoneItem: Identifiable {
    let id = UUID()
    var label: String
    var dateLabel: String
    var position: Double    // 0 – 100 along the timeline
    var description: String
    var category: String
    var status: MilestoneStatus
    var color: Color
}

enum MilestoneStatus: String, CaseIterable {
    case completed = "Done"
    case active    = "Active"
    case upcoming  = "Soon"
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Milestone Timeline Card

struct MilestoneTimelineCard: View {

    let title: String
    let categories: [String]
    @State private var items: [MilestoneItem]
    @State private var isExpanded = false
    @State private var editingID: UUID? = nil
    @State private var editingField: EditField = .label
    @State private var editingText = ""
    @State private var appeared = false
    @State private var highlightedID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Timeline Layout
    @State private var orientation: MLOrientation = .horizontal
    @State private var timelineStyle: MLStyle = .alternating
    @State private var itemSpacing: Double = 20
    @State private var timelinePadding: Double = 20

    // Milestone Styling
    @State private var markerSize: Double = 14
    @State private var markerShapeType: MLMarkerShape = .circle
    @State private var markerFill: Bool = true
    @State private var markerStroke: Bool = true
    @State private var connectorLine: Bool = true

    // Line Styling
    @State private var lineThickness: Double = 2.0
    @State private var lineDashed: Bool = false
    @State private var lineOpacity: Double = 0.6

    // Labels
    @State private var showLabels: Bool = true
    @State private var labelPos: MLLabelPos = .alternating
    @State private var showDateLabel: Bool = true
    @State private var showDescription: Bool = false

    // Grouping
    @State private var groupMode: Bool = false
    @State private var groupSpacing: Double = 10
    @State private var groupLabel: Bool = true

    // Status
    @State private var statusIndicator: Bool = true
    @State private var progressHighlight: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.9

    // Sorting
    @State private var sortOrder: MLSort = .chronological

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum EditField { case label, date, description }
    enum MLOrientation: String, CaseIterable { case horizontal = "Horizontal", vertical = "Vertical" }
    enum MLStyle: String, CaseIterable { case line = "Line", centered = "Centered", alternating = "Alternating" }
    enum MLMarkerShape: String, CaseIterable { case circle = "Circle", square = "Square", diamond = "Diamond" }
    enum MLLabelPos: String, CaseIterable { case above = "Above", below = "Below", alternating = "Alternate", side = "Side" }
    enum MLSort: String, CaseIterable { case chronological = "Chrono", reverse = "Reverse", custom = "Custom" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], items: [MilestoneItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: - Computed

    var sortedItems: [MilestoneItem] {
        switch sortOrder {
        case .chronological: return items.sorted { $0.position < $1.position }
        case .reverse:       return items.sorted { $0.position > $1.position }
        case .custom:        return items
        }
    }

    var maxCompletedPos: Double {
        items.filter { $0.status == .completed }.map { $0.position }.max() ?? 0
    }

    func markerAnyShape() -> AnyShape {
        switch markerShapeType {
        case .circle:  return AnyShape(Circle())
        case .square:  return AnyShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        case .diamond: return AnyShape(DiamondShape())
        }
    }

    func statusColor(for item: MilestoneItem) -> Color {
        guard statusIndicator else { return item.color }
        switch item.status {
        case .completed: return item.color
        case .active:    return item.color.opacity(0.75)
        case .upcoming:  return item.color.opacity(0.35)
        }
    }

    func effectiveLabelPos(for index: Int) -> MLLabelPos {
        switch labelPos {
        case .alternating: return index % 2 == 0 ? .above : .below
        default: return labelPos
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            chartView
                .frame(height: orientation == .horizontal ? 260 : 340)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            Divider().padding(.top, 16).padding(.horizontal, 12)

            VStack(spacing: 0) {
                Button { isExpanded.toggle() } label: {
                    ZStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                }

                VStack(spacing: 14) {
                    Divider().padding(.horizontal, 20)
                    layoutSettingsView
                    milestoneStyleSettingsView
                    lineStyleSettingsView
                    labelSettingsView
                    groupingSettingsView
                    statusSettingsView
                    interactionSettingsView
                    sortingSettingsView
                    itemListView
                }
                .frame(maxHeight: isExpanded ? .infinity : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
            }
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .onAppear {
            if animateOnLoad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: animationDuration)) { appeared = true }
                }
            } else {
                appeared = true
            }
        }
        .onChange(of: zoomPanEnabled) { _, enabled in
            if !enabled {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    zoomScale = 1.0; panOffset = .zero
                }
            }
        }
        .onTapGesture { editingID = nil; highlightedID = nil }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            if orientation == .horizontal {
                horizontalTimeline(geo: geo)
            } else {
                verticalTimeline(geo: geo)
            }
        }
    }

    // MARK: - Horizontal Timeline

    @ViewBuilder
    func horizontalTimeline(geo: GeometryProxy) -> some View {
        let pad = CGFloat(timelinePadding)
        let leftM  = pad
        let rightM = pad
        let chartW = geo.size.width - leftM - rightM
        let chartH = geo.size.height

        // Timeline Y position based on style / label position
        let timelineY: CGFloat = {
            switch timelineStyle {
            case .alternating, .centered: return chartH / 2
            case .line:
                if labelPos == .above { return chartH * 0.62 }
                if labelPos == .below { return chartH * 0.38 }
                return chartH / 2
            }
        }()

        let mR = CGFloat(markerSize) / 2
        let connLen: CGFloat = connectorLine ? 22 : 0

        let sorted = sortedItems

        ZStack(alignment: .topLeading) {

            // Background timeline track
            Path { p in
                p.move(to: CGPoint(x: leftM, y: timelineY))
                p.addLine(to: CGPoint(x: leftM + chartW, y: timelineY))
            }
            .stroke(
                Color.primary.opacity(lineOpacity * 0.4),
                style: StrokeStyle(lineWidth: CGFloat(lineThickness), lineCap: .round, dash: lineDashed ? [6, 4] : [])
            )

            // Progress highlight (completed portion)
            if progressHighlight && maxCompletedPos > 0 {
                let progressX = leftM + CGFloat(maxCompletedPos / 100) * chartW
                Path { p in
                    p.move(to: CGPoint(x: leftM, y: timelineY))
                    p.addLine(to: CGPoint(x: progressX, y: timelineY))
                }
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(
                    Color.green.opacity(lineOpacity),
                    style: StrokeStyle(lineWidth: CGFloat(lineThickness), lineCap: .round)
                )
            }

            // Group bands
            if groupMode {
                let groups = Dictionary(grouping: sorted, by: { $0.category })
                    .filter { !$0.key.isEmpty }
                ForEach(Array(groups.keys.enumerated()), id: \.element) { ki, key in
                    let gItems = groups[key]!
                    let minPos = gItems.map { $0.position }.min() ?? 0
                    let maxPos = gItems.map { $0.position }.max() ?? 100
                    let gX = leftM + CGFloat(minPos / 100) * chartW - CGFloat(groupSpacing)
                    let gW = CGFloat((maxPos - minPos) / 100) * chartW + CGFloat(groupSpacing) * 2
                    let bandH: CGFloat = 8
                    let col = gItems.first?.color ?? AnalyticsCard.colorPalette[ki % AnalyticsCard.colorPalette.count]
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(col.opacity(0.1))
                        .frame(width: max(gW, 0), height: bandH)
                        .position(x: gX + max(gW, 0) / 2, y: timelineY)
                    if groupLabel {
                        Text(key)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(col.opacity(0.8))
                            .position(x: gX + max(gW, 0) / 2, y: timelineY - bandH / 2 - 8)
                    }
                }
            }

            // Milestones
            ForEach(Array(sorted.enumerated()), id: \.element.id) { i, item in
                let mX = leftM + CGFloat(item.position / 100) * chartW
                let isHL = highlightedID == item.id
                let col = statusColor(for: item)
                let displayR = mR * (isHL ? 1.25 : 1.0)
                let effPos = effectiveLabelPos(for: i)
                let labelAbove = effPos == .above
                let connDir: CGFloat = labelAbove ? -1 : 1
                let shapeAny = markerAnyShape()

                // Connector line
                if connectorLine {
                    Path { p in
                        p.move(to: CGPoint(x: mX, y: timelineY + connDir * displayR))
                        p.addLine(to: CGPoint(x: mX, y: timelineY + connDir * (displayR + connLen)))
                    }
                    .stroke(col.opacity(0.4), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                }

                // Marker
                ZStack {
                    if markerFill {
                        shapeAny
                            .fill(col)
                            .glassEffect(.clear, in: shapeAny)
                    }
                    if markerStroke {
                        shapeAny.stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        shapeAny.stroke(Color.white, lineWidth: 4)
                            .blur(radius: 2.5).opacity(0.3).clipShape(shapeAny)
                    }
                    // Status icon (completed = checkmark)
                    if statusIndicator && item.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: displayR * 0.75, weight: .bold))
                            .foregroundStyle(.white)
                    } else if statusIndicator && item.status == .active {
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: displayR * 0.5, height: displayR * 0.5)
                    }
                }
                .frame(width: displayR * 2, height: displayR * 2)
                .scaleEffect(appeared ? 1.0 : 0.01)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.65)
                        .delay(animateOnLoad ? Double(i) * 0.06 : 0),
                    value: appeared
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHL)
                .position(x: mX, y: timelineY)
                .onTapGesture {
                    guard hoverHighlight else { return }
                    withAnimation(.spring(response: 0.3)) {
                        highlightedID = (highlightedID == item.id) ? nil : item.id
                    }
                }

                // Labels
                if showLabels && effPos != .side {
                    let labelBaseY = timelineY + connDir * (displayR + connLen + 4)
                    VStack(spacing: 1) {
                        if showDateLabel {
                            Text(item.dateLabel)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(col.opacity(0.7))
                        }
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if showDescription && !item.description.isEmpty {
                            Text(item.description)
                                .font(.system(size: 8, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 72)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .easeOut(duration: 0.3)
                            .delay(animateOnLoad ? Double(i) * 0.06 + 0.1 : 0),
                        value: appeared
                    )
                    .position(x: mX, y: labelBaseY + (showDescription && !item.description.isEmpty ? 6 : 0))
                }

                // Highlight ring
                if isHL {
                    shapeAny
                        .stroke(col.opacity(0.45), lineWidth: 2)
                        .frame(width: displayR * 2 + 7, height: displayR * 2 + 7)
                        .position(x: mX, y: timelineY)
                }
            }

            // Tooltip
            if hoverTooltip, let hlID = highlightedID,
               let hlItem = items.first(where: { $0.id == hlID }) {
                let hlPos = leftM + CGFloat(hlItem.position / 100) * chartW
                milestoneTooltip(item: hlItem, x: hlPos, y: timelineY - mR - 8, chartW: chartW, leftM: leftM)
            }
        }
        .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
        .offset(
            x: zoomPanEnabled ? panOffset.width  + dragTranslation.width  : 0,
            y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0
        )
        .gesture(
            MagnificationGesture()
                .updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }
                .onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.5, zoomScale * v)) } }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .updating($dragTranslation) { v, s, _ in s = zoomPanEnabled ? v.translation : .zero }
                .onEnded { v in
                    if zoomPanEnabled {
                        panOffset.width  += v.translation.width
                        panOffset.height += v.translation.height
                    }
                }
        )
    }

    // MARK: - Vertical Timeline

    @ViewBuilder
    func verticalTimeline(geo: GeometryProxy) -> some View {
        let pad = CGFloat(timelinePadding)
        let topM   = pad
        let botM   = pad
        let chartH = geo.size.height - topM - botM
        let chartW = geo.size.width

        let timelineX: CGFloat = {
            switch timelineStyle {
            case .alternating, .centered: return chartW / 2
            case .line: return chartW * 0.25
            }
        }()

        let mR = CGFloat(markerSize) / 2
        let connLen: CGFloat = connectorLine ? 20 : 0
        let sorted = sortedItems

        ZStack(alignment: .topLeading) {

            // Background track
            Path { p in
                p.move(to: CGPoint(x: timelineX, y: topM))
                p.addLine(to: CGPoint(x: timelineX, y: topM + chartH))
            }
            .stroke(
                Color.primary.opacity(lineOpacity * 0.4),
                style: StrokeStyle(lineWidth: CGFloat(lineThickness), lineCap: .round, dash: lineDashed ? [6, 4] : [])
            )

            // Progress highlight
            if progressHighlight && maxCompletedPos > 0 {
                let progressY = topM + CGFloat(maxCompletedPos / 100) * chartH
                Path { p in
                    p.move(to: CGPoint(x: timelineX, y: topM))
                    p.addLine(to: CGPoint(x: timelineX, y: progressY))
                }
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(Color.green.opacity(lineOpacity), style: StrokeStyle(lineWidth: CGFloat(lineThickness), lineCap: .round))
            }

            // Milestones
            ForEach(Array(sorted.enumerated()), id: \.element.id) { i, item in
                let mY = topM + CGFloat(item.position / 100) * chartH
                let isHL = highlightedID == item.id
                let col = statusColor(for: item)
                let displayR = mR * (isHL ? 1.25 : 1.0)
                let effPos = effectiveLabelPos(for: i)
                let labelRight = !(timelineStyle == .alternating && i % 2 == 1)
                let connDir: CGFloat = labelRight ? 1 : -1
                let shapeAny = markerAnyShape()

                // Connector
                if connectorLine {
                    Path { p in
                        p.move(to: CGPoint(x: timelineX + connDir * displayR, y: mY))
                        p.addLine(to: CGPoint(x: timelineX + connDir * (displayR + connLen), y: mY))
                    }
                    .stroke(col.opacity(0.4), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                }

                // Marker
                ZStack {
                    if markerFill {
                        shapeAny.fill(col).glassEffect(.clear, in: shapeAny)
                    }
                    if markerStroke {
                        shapeAny.stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        shapeAny.stroke(Color.white, lineWidth: 4)
                            .blur(radius: 2.5).opacity(0.3).clipShape(shapeAny)
                    }
                    if statusIndicator && item.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: displayR * 0.75, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: displayR * 2, height: displayR * 2)
                .scaleEffect(appeared ? 1.0 : 0.01)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.65)
                        .delay(animateOnLoad ? Double(i) * 0.06 : 0),
                    value: appeared
                )
                .position(x: timelineX, y: mY)
                .onTapGesture {
                    guard hoverHighlight else { return }
                    withAnimation(.spring(response: 0.3)) {
                        highlightedID = (highlightedID == item.id) ? nil : item.id
                    }
                }

                // Label
                if showLabels && effPos != .side {
                    let lX = timelineX + connDir * (displayR + connLen + 8)
                    HStack(spacing: 4) {
                        if !labelRight {
                            Spacer()
                            labelStack(for: item, col: col)
                        } else {
                            labelStack(for: item, col: col)
                            Spacer()
                        }
                    }
                    .frame(width: 100)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(animateOnLoad ? Double(i) * 0.06 : 0), value: appeared)
                    .position(x: lX + (labelRight ? 50 : -50), y: mY)
                }
            }

            // Tooltip
            if hoverTooltip, let hlID = highlightedID,
               let hlItem = items.first(where: { $0.id == hlID }) {
                let hlY = topM + CGFloat(hlItem.position / 100) * chartH
                milestoneTooltip(item: hlItem, x: timelineX + 12, y: hlY - 50, chartW: chartW, leftM: 0)
            }
        }
        .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
        .offset(
            x: zoomPanEnabled ? panOffset.width  + dragTranslation.width  : 0,
            y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0
        )
        .gesture(
            MagnificationGesture()
                .updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }
                .onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.5, zoomScale * v)) } }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .updating($dragTranslation) { v, s, _ in s = zoomPanEnabled ? v.translation : .zero }
                .onEnded { v in
                    if zoomPanEnabled {
                        panOffset.width  += v.translation.width
                        panOffset.height += v.translation.height
                    }
                }
        )
    }

    @ViewBuilder
    func labelStack(for item: MilestoneItem, col: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if showDateLabel {
                Text(item.dateLabel)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(col.opacity(0.7))
            }
            Text(item.label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            if showDescription && !item.description.isEmpty {
                Text(item.description)
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tooltip

    @ViewBuilder
    func milestoneTooltip(item: MilestoneItem, x: CGFloat, y: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let w: CGFloat = 120
        let clampedX = max(leftM + w / 2, min(x, leftM + chartW - w / 2))
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle().fill(item.color).frame(width: 8, height: 8)
                Text(item.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            if !item.dateLabel.isEmpty {
                Text(item.dateLabel)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text("Status:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(item.status.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        .position(x: clampedX, y: max(30, y))
    }

    // MARK: - Settings: Layout

    var layoutSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Orient")
                HStack(spacing: 4) {
                    ForEach(MLOrientation.allCases, id: \.self) { o in
                        pillButton(o.rawValue, isSelected: orientation == o) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { orientation = o }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(MLStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: timelineStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { timelineStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $timelinePadding, in: 0...60, step: 2)
                Text("\(Int(timelinePadding))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Milestone Style

    var milestoneStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Mk Size")
                Slider(value: $markerSize, in: 6...30, step: 1)
                Text("\(Int(markerSize))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Shape")
                HStack(spacing: 4) {
                    ForEach(MLMarkerShape.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: markerShapeType == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { markerShapeType = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Fill")
                Toggle("", isOn: $markerFill).labelsHidden().scaleEffect(0.8)
                Text("Fill marker").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Stroke")
                Toggle("", isOn: $markerStroke).labelsHidden().scaleEffect(0.8)
                Text("Glass stroke").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Connect")
                Toggle("", isOn: $connectorLine).labelsHidden().scaleEffect(0.8)
                Text("Connector line").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Line Style

    var lineStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Thickness")
                Slider(value: $lineThickness, in: 1...6, step: 0.5)
                Text(String(format: "%.1fpt", lineThickness))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    pillButton("Solid", isSelected: !lineDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { lineDashed = false }
                    }
                    pillButton("Dashed", isSelected: lineDashed) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { lineDashed = true }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $lineOpacity, in: 0...1, step: 0.05)
                Text("\(Int(lineOpacity * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                Toggle("", isOn: $showLabels).labelsHidden().scaleEffect(0.8)
                Text("Show milestone labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showLabels {
                HStack(spacing: 10) {
                    settingsLabel("Position")
                    HStack(spacing: 4) {
                        ForEach(MLLabelPos.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: labelPos == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPos = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Date")
                Toggle("", isOn: $showDateLabel).labelsHidden().scaleEffect(0.8)
                Text("Show date text").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Desc")
                Toggle("", isOn: $showDescription).labelsHidden().scaleEffect(0.8)
                Text("Show description").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Grouping

    var groupingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Groups")
                Toggle("", isOn: $groupMode).labelsHidden().scaleEffect(0.8)
                Text("Group by category").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if groupMode {
                HStack(spacing: 10) {
                    settingsLabel("Spacing")
                    Slider(value: $groupSpacing, in: 0...40, step: 2)
                    Text("\(Int(groupSpacing))pt")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    settingsLabel("Lbl")
                    Toggle("", isOn: $groupLabel).labelsHidden().scaleEffect(0.8)
                    Text("Show group labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings: Status

    var statusSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Status")
                Toggle("", isOn: $statusIndicator).labelsHidden().scaleEffect(0.8)
                Text("Status icons on markers").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Progress")
                Toggle("", isOn: $progressHighlight).labelsHidden().scaleEffect(0.8)
                Text("Highlight completed path").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Interaction

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("Tap to highlight").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("Show milestone details").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom/Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("Pinch zoom & drag pan").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("Animate on load").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if animateOnLoad {
                HStack(spacing: 10) {
                    settingsLabel("Duration")
                    Slider(value: $animationDuration, in: 0.2...2.0, step: 0.1)
                    Text(String(format: "%.1fs", animationDuration))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Sorting

    var sortingSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Sort")
                HStack(spacing: 4) {
                    ForEach(MLSort.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: sortOrder == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { sortOrder = s }
                        }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Item List

    var itemListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(index: index, item: item)
            }
            Divider().padding(.horizontal, 20)
            Button { addItem() } label: {
                Text("+ Add New Item")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    func itemRow(index: Int, item: MilestoneItem) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {

                // Color swatch
                Button {
                    #if os(iOS)
                    let coord = ColorPickerCoordinator { color in items[index].color = color }
                    pickerCoordinator = coord
                    let vc = UIColorPickerViewController()
                    vc.selectedColor = UIColor(items[index].color)
                    vc.supportsAlpha = false
                    vc.delegate = coord
                    topViewController()?.present(vc, animated: true)
                    #endif
                } label: {
                    Circle()
                        .fill(items[index].color)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }

                // Label
                if editingID == item.id && editingField == .label {
                    TextField("Label", text: $editingText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .onChange(of: editingText) { _, val in items[index].label = val }
                } else {
                    Button {
                        editingID = item.id; editingField = .label; editingText = item.label
                    } label: {
                        Text(item.label.isEmpty ? "Milestone \(index + 1)" : item.label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(item.label.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .underline(color: .primary.opacity(item.label.isEmpty ? 0 : 0.2))
                    }
                    .foregroundStyle(.primary)
                }

                // Date label
                if editingID == item.id && editingField == .date {
                    TextField("Date", text: $editingText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editingText) { _, val in items[index].dateLabel = val }
                } else {
                    Button {
                        editingID = item.id; editingField = .date; editingText = item.dateLabel
                    } label: {
                        Text(item.dateLabel.isEmpty ? "Date" : item.dateLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .underline(color: .secondary.opacity(0.3))
                    }
                    .foregroundStyle(.secondary)
                }

                // Status pill
                Button {
                    let all = MilestoneStatus.allCases
                    let idx = all.firstIndex(of: items[index].status) ?? 0
                    withAnimation(.spring(response: 0.3)) {
                        items[index].status = all[(idx + 1) % all.count]
                    }
                } label: {
                    Text(items[index].status.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusBadgeColor(items[index].status), in: .capsule)
                        .foregroundStyle(.white)
                }
            }

            // Position slider
            HStack(spacing: 8) {
                Text("Pos")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Slider(value: $items[index].position, in: 0...100, step: 1)
                Text("\(Int(items[index].position))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
            .padding(.leading, 36)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        if index < items.count - 1 { Divider().padding(.horizontal, 20) }
    }

    func statusBadgeColor(_ status: MilestoneStatus) -> Color {
        switch status {
        case .completed: return .green
        case .active:    return .orange
        case .upcoming:  return .secondary
        }
    }

    // MARK: - UI Helpers

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 4)
    }

    func settingsLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(width: 62, alignment: .leading)
    }

    func pillButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(isSelected ? Color.black.opacity(0.1) : Color.clear, in: .capsule)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
    }

    // MARK: - Logic

    func addItem() {
        let colIdx = items.count % Self.colorPalette.count
        let lastPos = items.map { $0.position }.max() ?? 70
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(MilestoneItem(
                label: "Milestone \(items.count + 1)",
                dateLabel: "TBD",
                position: min(100, lastPos + 12),
                description: "",
                category: "",
                status: .upcoming,
                color: Self.colorPalette[colIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        MilestoneTimelineCard(
            title: "Milestone Timeline",
            categories: ["Timeline", "Milestone"],
            items: [
                MilestoneItem(label: "Kickoff",   dateLabel: "Jan",  position: 0,   description: "Project begins",         category: "Planning",  status: .completed, color: AnalyticsCard.colorPalette[0]),
                MilestoneItem(label: "Design",    dateLabel: "Feb",  position: 18,  description: "UI/UX finalised",         category: "Design",    status: .completed, color: AnalyticsCard.colorPalette[1]),
                MilestoneItem(label: "Alpha",     dateLabel: "Apr",  position: 36,  description: "Internal testing",        category: "Dev",       status: .completed, color: AnalyticsCard.colorPalette[2]),
                MilestoneItem(label: "Beta",      dateLabel: "Jun",  position: 55,  description: "Public beta launch",      category: "Dev",       status: .active,    color: AnalyticsCard.colorPalette[3]),
                MilestoneItem(label: "Launch",    dateLabel: "Sep",  position: 76,  description: "App Store release",       category: "Release",   status: .upcoming,  color: AnalyticsCard.colorPalette[4]),
                MilestoneItem(label: "v2.0",      dateLabel: "Dec",  position: 100, description: "Major update",            category: "Release",   status: .upcoming,  color: AnalyticsCard.colorPalette[5]),
            ]
        )
        .padding(.top, 20)
    }
}
