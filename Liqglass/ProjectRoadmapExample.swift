//
//  ProjectRoadmapExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Roadmap Data Model

struct RoadmapTask: Identifiable {
    let id = UUID()
    var name: String
    var startPos: Double    // 0–100 on the time axis
    var endPos: Double      // 0–100 on the time axis
    var lane: Int           // 0-based lane index
    var progress: Double    // 0–100 %
    var description: String
    var taskType: RoadmapTaskType
    var status: RoadmapStatus
    var color: Color
}

enum RoadmapTaskType: String, CaseIterable {
    case fixed      = "Fixed"
    case milestone  = "Milestone"
    case continuous = "Continuous"
}

enum RoadmapStatus: String, CaseIterable {
    case completed  = "Done"
    case active     = "Active"
    case upcoming   = "Soon"
    case blocked    = "Blocked"
}

struct RoadmapLane: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
}

// MARK: - Project Roadmap Card

struct ProjectRoadmapCard: View {

    let title: String
    let categories: [String]
    @State private var tasks: [RoadmapTask]
    @State private var lanes: [RoadmapLane]
    @State private var isExpanded = false
    @State private var editingTaskID: UUID? = nil
    @State private var editingField: EditField = .name
    @State private var editingText = ""
    @State private var appeared = false
    @State private var highlightedTaskID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Timeline Layout
    @State private var orientation: RMOrientation = .horizontal
    @State private var roadmapStyle: RMStyle = .lanes
    @State private var laneHeight: Double = 52
    @State private var laneSpacing: Double = 4
    @State private var timelinePadding: Double = 12

    // Phases / Lanes
    @State private var showLaneLabels: Bool = true
    @State private var laneLabelPos: RMLaneLabelPos = .left

    // Task Blocks
    @State private var blockCornerRadius: Double = 8
    @State private var blockPadding: Double = 4
    @State private var blockStyle: RMBlockStyle = .glass

    // Task Behaviour
    @State private var progressIndicator: Bool = true
    @State private var dependencyLines: Bool = false

    // Labels
    @State private var showTaskLabel: Bool = true
    @State private var taskLabelPos: RMTaskLabelPos = .inside
    @State private var showDateLabel: Bool = true

    // Status
    @State private var statusIndicator: Bool = true
    @State private var progressFill: Bool = true

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7

    // Sorting
    @State private var sortOrder: RMSort = .chronological

    // Time scale labels (display-only strings for axis ticks)
    @State private var timeLabels: [String] = ["Q1", "Q2", "Q3", "Q4"]

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum EditField { case name, startPos, endPos, progress, description }
    enum RMOrientation: String, CaseIterable { case horizontal = "Horizontal", vertical = "Vertical" }
    enum RMStyle: String, CaseIterable { case lanes = "Lane-based", singleLine = "Single-line", compact = "Compact" }
    enum RMLaneLabelPos: String, CaseIterable { case left = "Left", top = "Top", hidden = "Hidden" }
    enum RMBlockStyle: String, CaseIterable { case solid = "Solid", outline = "Outline", glass = "Glass" }
    enum RMTaskLabelPos: String, CaseIterable { case inside = "Inside", above = "Above", below = "Below", hidden = "Hidden" }
    enum RMSort: String, CaseIterable { case chronological = "Chrono", reverse = "Reverse", custom = "Custom" }

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], tasks: [RoadmapTask], lanes: [RoadmapLane]) {
        self.title = title
        self.categories = categories
        self._tasks = State(initialValue: tasks)
        self._lanes = State(initialValue: lanes)
    }

    // MARK: - Computed

    var sortedTasks: [RoadmapTask] {
        switch sortOrder {
        case .chronological: return tasks.sorted { $0.startPos < $1.startPos }
        case .reverse:       return tasks.sorted { $0.startPos > $1.startPos }
        case .custom:        return tasks
        }
    }

    var laneCount: Int { max(1, lanes.count) }

    func statusColor(for task: RoadmapTask) -> Color {
        guard statusIndicator else { return task.color }
        switch task.status {
        case .completed: return task.color
        case .active:    return task.color
        case .upcoming:  return task.color.opacity(0.55)
        case .blocked:   return Color.red.opacity(0.75)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            chartView
                .frame(height: chartFrameHeight)
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
                    laneSettingsView
                    blockSettingsView
                    taskBehaviourSettingsView
                    labelSettingsView
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
        .onTapGesture { editingTaskID = nil; highlightedTaskID = nil }
    }

    var chartFrameHeight: CGFloat {
        if roadmapStyle == .compact { return CGFloat(laneCount) * (CGFloat(laneHeight) * 0.6 + CGFloat(laneSpacing)) + 50 }
        return CGFloat(laneCount) * (CGFloat(laneHeight) + CGFloat(laneSpacing)) + 50
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let labelW: CGFloat = (showLaneLabels && laneLabelPos == .left) ? 58 : 0
            let pad = CGFloat(timelinePadding)
            let leftM  = labelW + pad
            let topM: CGFloat = (showLaneLabels && laneLabelPos == .top) ? 22 : 8
            let botM: CGFloat = showDateLabel ? 22 : 8
            let chartW = geo.size.width - leftM - pad
            let lH = CGFloat(laneHeight)
            let lS = CGFloat(laneSpacing)

            ZStack(alignment: .topLeading) {

                // Lane backgrounds
                ForEach(0..<laneCount, id: \.self) { li in
                    let laneY = topM + CGFloat(li) * (lH + lS)
                    let laneCol: Color = li < lanes.count ? lanes[li].color : Self.colorPalette[li % Self.colorPalette.count]

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(laneCol.opacity(0.06))
                        .frame(width: chartW, height: lH)
                        .position(x: leftM + chartW / 2, y: laneY + lH / 2)

                    // Lane label (left)
                    if showLaneLabels && laneLabelPos == .left {
                        let laneName = li < lanes.count ? lanes[li].name : "Lane \(li + 1)"
                        Text(laneName)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(width: labelW - 6, alignment: .trailing)
                            .position(x: labelW / 2, y: laneY + lH / 2)
                    }
                }

                // Lane labels (top)
                if showLaneLabels && laneLabelPos == .top {
                    Text("Lanes")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .position(x: leftM / 2, y: topM / 2)
                }

                // Time axis ticks
                if showDateLabel {
                    ForEach(0..<timeLabels.count, id: \.self) { i in
                        let frac = CGFloat(i) / CGFloat(max(timeLabels.count - 1, 1))
                        let xPos = leftM + frac * chartW
                        let totalLanesH = CGFloat(laneCount) * (lH + lS) - lS
                        Text(timeLabels[i])
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(x: xPos, y: topM + totalLanesH + botM / 2)
                        // Tick mark
                        Path { p in
                            p.move(to: CGPoint(x: xPos, y: topM))
                            p.addLine(to: CGPoint(x: xPos, y: topM + totalLanesH))
                        }
                        .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    }
                }

                // Dependency lines (connect task end to next task start in same lane)
                if dependencyLines {
                    let sorted = sortedTasks
                    ForEach(0..<laneCount, id: \.self) { li in
                        let laneTasks = sorted.filter { $0.lane == li }.sorted { $0.startPos < $1.startPos }
                        ForEach(0..<max(0, laneTasks.count - 1), id: \.self) { ti in
                            let t1 = laneTasks[ti]
                            let t2 = laneTasks[ti + 1]
                            let laneY = topM + CGFloat(li) * (lH + lS) + lH / 2
                            let x1 = leftM + CGFloat(t1.endPos / 100) * chartW
                            let x2 = leftM + CGFloat(t2.startPos / 100) * chartW
                            Path { p in
                                p.move(to: CGPoint(x: x1, y: laneY))
                                p.addLine(to: CGPoint(x: x2, y: laneY))
                            }
                            .stroke(Color.primary.opacity(0.15), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 3]))
                        }
                    }
                }

                // Task blocks
                ForEach(Array(sortedTasks.enumerated()), id: \.element.id) { idx, task in
                    let li = max(0, min(task.lane, laneCount - 1))
                    let laneY = topM + CGFloat(li) * (lH + lS)
                    let taskX = leftM + CGFloat(task.startPos / 100) * chartW
                    let taskW = max(14, CGFloat((task.endPos - task.startPos) / 100) * chartW)
                    let blockH = lH - CGFloat(blockPadding) * 2
                    let col = statusColor(for: task)
                    let isHL = highlightedTaskID == task.id
                    let cornerR = CGFloat(blockCornerRadius)
                    let isMilestone = task.taskType == .milestone

                    if isMilestone {
                        // Milestone: diamond marker
                        let mX = taskX + taskW / 2
                        let mY = laneY + lH / 2
                        let mS: CGFloat = blockH * 0.65
                        ZStack {
                            DiamondShape()
                                .fill(col.opacity(0.85))
                                .glassEffect(.clear, in: DiamondShape())
                            DiamondShape()
                                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                        }
                        .frame(width: mS, height: mS)
                        .scaleEffect(appeared ? 1.0 : 0.01)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.65)
                                .delay(animateOnLoad ? Double(idx) * 0.05 : 0),
                            value: appeared
                        )
                        .position(x: mX, y: mY)
                        .onTapGesture {
                            guard hoverHighlight else { return }
                            withAnimation(.spring(response: 0.3)) {
                                highlightedTaskID = (highlightedTaskID == task.id) ? nil : task.id
                            }
                        }

                        // Milestone label
                        if showTaskLabel && taskLabelPos != .hidden {
                            let lY = taskLabelPos == .above ? laneY - 2 : laneY + lH + 2
                            Text(task.name)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.75))
                                .lineLimit(1)
                                .position(x: mX, y: lY)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.3).delay(animateOnLoad ? Double(idx) * 0.05 : 0), value: appeared)
                        }

                    } else {
                        // Regular task block
                        ZStack(alignment: .leading) {
                            // Base fill
                            switch blockStyle {
                            case .solid:
                                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                    .fill(col.opacity(isHL ? 0.88 : 0.72))
                            case .outline:
                                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                    .fill(col.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                            .stroke(col.opacity(0.7), lineWidth: 1.5)
                                    )
                            case .glass:
                                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                    .fill(col.opacity(isHL ? 0.82 : 0.68))
                                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerR, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                            }

                            // Progress fill
                            if progressFill && task.progress > 0 && task.progress < 100 {
                                let progW = max(0, taskW * CGFloat(task.progress / 100))
                                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                                    .fill(Color.white.opacity(0.22))
                                    .frame(width: min(progW, taskW))
                                    .frame(maxHeight: .infinity)
                                    .clipped()
                            }

                            // Task label
                            if showTaskLabel && taskLabelPos == .inside {
                                Text(task.name)
                                    .font(.system(size: min(10, blockH * 0.32), weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                            }
                        }
                        .frame(width: taskW, height: blockH)
                        .scaleEffect(x: appeared ? 1.0 : 0.01, y: 1.0, anchor: .leading)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(animateOnLoad ? Double(idx) * 0.05 : 0),
                            value: appeared
                        )
                        .position(x: taskX + taskW / 2, y: laneY + lH / 2)
                        .onTapGesture {
                            guard hoverHighlight else { return }
                            withAnimation(.spring(response: 0.3)) {
                                highlightedTaskID = (highlightedTaskID == task.id) ? nil : task.id
                            }
                        }

                        // Above / Below labels
                        if showTaskLabel && (taskLabelPos == .above || taskLabelPos == .below) {
                            let lY = taskLabelPos == .above
                                ? laneY + CGFloat(blockPadding) - 10
                                : laneY + lH - CGFloat(blockPadding) + 10
                            Text(task.name)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.7))
                                .lineLimit(1)
                                .frame(maxWidth: taskW - 4)
                                .position(x: taskX + taskW / 2, y: lY)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.3).delay(animateOnLoad ? Double(idx) * 0.05 : 0), value: appeared)
                        }

                        // Status badge
                        if statusIndicator && task.status == .blocked {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .position(x: taskX + taskW - 8, y: laneY + lH / 2)
                        } else if statusIndicator && task.status == .completed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .position(x: taskX + taskW - 8, y: laneY + lH / 2)
                        }

                        // Highlight ring
                        if isHL {
                            RoundedRectangle(cornerRadius: cornerR + 2, style: .continuous)
                                .stroke(col.opacity(0.5), lineWidth: 2)
                                .frame(width: taskW + 4, height: blockH + 4)
                                .position(x: taskX + taskW / 2, y: laneY + lH / 2)
                        }
                    }
                }

                // Tooltip
                if hoverTooltip, let hlID = highlightedTaskID,
                   let hlTask = tasks.first(where: { $0.id == hlID }) {
                    let li = max(0, min(hlTask.lane, laneCount - 1))
                    let laneY = topM + CGFloat(li) * (lH + lS)
                    let taskX = leftM + CGFloat(hlTask.startPos / 100) * chartW
                    roadmapTooltip(task: hlTask, x: taskX + 60, y: laneY - 16, chartW: chartW, leftM: leftM)
                }
            }
            .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .topLeading)
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
    }

    // MARK: - Tooltip

    @ViewBuilder
    func roadmapTooltip(task: RoadmapTask, x: CGFloat, y: CGFloat, chartW: CGFloat, leftM: CGFloat) -> some View {
        let w: CGFloat = 130
        let clampedX = max(leftM + w / 2, min(x, leftM + chartW - w / 2))
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3).fill(task.color).frame(width: 8, height: 8)
                Text(task.name)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Lane:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                let laneName = task.lane < lanes.count ? lanes[task.lane].name : "Lane \(task.lane + 1)"
                Text(laneName)
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            HStack(spacing: 4) {
                Text("Status:")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Text(task.status.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            if progressFill {
                HStack(spacing: 4) {
                    Text("Progress:")
                        .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Text("\(Int(task.progress))%")
                        .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                }
            }
            if !task.description.isEmpty {
                Text(task.description)
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
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(RMStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue.components(separatedBy: "-").first ?? s.rawValue,
                                   isSelected: roadmapStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { roadmapStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Ln Height")
                Slider(value: $laneHeight, in: 40...120, step: 4)
                Text("\(Int(laneHeight))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Ln Space")
                Slider(value: $laneSpacing, in: 0...40, step: 2)
                Text("\(Int(laneSpacing))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $timelinePadding, in: 0...40, step: 2)
                Text("\(Int(timelinePadding))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Lanes

    var laneSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Ln Labels")
                Toggle("", isOn: $showLaneLabels).labelsHidden().scaleEffect(0.8)
                Text("Show lane names").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showLaneLabels {
                HStack(spacing: 10) {
                    settingsLabel("Lbl Pos")
                    HStack(spacing: 4) {
                        ForEach(RMLaneLabelPos.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: laneLabelPos == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { laneLabelPos = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Settings: Block

    var blockSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Style")
                HStack(spacing: 4) {
                    ForEach(RMBlockStyle.allCases, id: \.self) { s in
                        pillButton(s.rawValue, isSelected: blockStyle == s) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { blockStyle = s }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $blockCornerRadius, in: 0...20, step: 1)
                Text("\(Int(blockCornerRadius))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $blockPadding, in: 0...16, step: 1)
                Text("\(Int(blockPadding))pt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Task Behaviour

    var taskBehaviourSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Progress")
                Toggle("", isOn: $progressIndicator).labelsHidden().scaleEffect(0.8)
                Text("Progress overlay").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Dep Lines")
                Toggle("", isOn: $dependencyLines).labelsHidden().scaleEffect(0.8)
                Text("Dependency lines").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Task Lbl")
                Toggle("", isOn: $showTaskLabel).labelsHidden().scaleEffect(0.8)
                Text("Show task labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showTaskLabel {
                HStack(spacing: 10) {
                    settingsLabel("Lbl Pos")
                    HStack(spacing: 4) {
                        ForEach(RMTaskLabelPos.allCases, id: \.self) { p in
                            pillButton(p.rawValue, isSelected: taskLabelPos == p) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { taskLabelPos = p }
                            }
                        }
                    }
                    Spacer()
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Date Lbl")
                Toggle("", isOn: $showDateLabel).labelsHidden().scaleEffect(0.8)
                Text("Show time axis ticks").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Settings: Status

    var statusSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Status")
                Toggle("", isOn: $statusIndicator).labelsHidden().scaleEffect(0.8)
                Text("Status icons on tasks").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Prog Fill")
                Toggle("", isOn: $progressFill).labelsHidden().scaleEffect(0.8)
                Text("Progress fill overlay").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                Text("Show task details").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
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
                    ForEach(RMSort.allCases, id: \.self) { s in
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
            // Lane manager
            laneManagerView
            Divider().padding(.horizontal, 20)

            // Task rows
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                taskRow(index: index, task: task)
            }
            Divider().padding(.horizontal, 20)
            Button { addTask() } label: {
                Text("+ Add New Item")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    var laneManagerView: some View {
        VStack(spacing: 0) {
            ForEach(Array(lanes.enumerated()), id: \.element.id) { li, lane in
                HStack(spacing: 10) {
                    Button {
                        #if os(iOS)
                        let coord = ColorPickerCoordinator { color in lanes[li].color = color }
                        pickerCoordinator = coord
                        let vc = UIColorPickerViewController()
                        vc.selectedColor = UIColor(lanes[li].color)
                        vc.supportsAlpha = false
                        vc.delegate = coord
                        topViewController()?.present(vc, animated: true)
                        #endif
                    } label: {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(lanes[li].color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                    Text("Lane \(li + 1)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(lane.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if lanes.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                lanes.remove(at: li)
                                for i in tasks.indices { if tasks[i].lane >= lanes.count { tasks[i].lane = max(0, lanes.count - 1) } }
                            }
                        } label: {
                            Image(systemName: "minus.circle").foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if li < lanes.count - 1 { Divider().padding(.horizontal, 20) }
            }
            Divider().padding(.horizontal, 20)
            Button {
                withAnimation(.spring(response: 0.4)) {
                    let ci = lanes.count % Self.colorPalette.count
                    lanes.append(RoadmapLane(name: "Lane \(lanes.count + 1)", color: Self.colorPalette[ci]))
                }
            } label: {
                Text("+ Add New Lane")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder
    func taskRow(index: Int, task: RoadmapTask) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                // Color swatch
                Button {
                    #if os(iOS)
                    let coord = ColorPickerCoordinator { color in tasks[index].color = color }
                    pickerCoordinator = coord
                    let vc = UIColorPickerViewController()
                    vc.selectedColor = UIColor(tasks[index].color)
                    vc.supportsAlpha = false
                    vc.delegate = coord
                    topViewController()?.present(vc, animated: true)
                    #endif
                } label: {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tasks[index].color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                }

                // Name
                if editingTaskID == task.id && editingField == .name {
                    TextField("Task name", text: $editingText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .onChange(of: editingText) { _, val in tasks[index].name = val }
                } else {
                    Button {
                        editingTaskID = task.id; editingField = .name; editingText = task.name
                    } label: {
                        Text(task.name.isEmpty ? "Task \(index + 1)" : task.name)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(task.name.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .underline(color: .primary.opacity(task.name.isEmpty ? 0 : 0.2))
                    }
                    .foregroundStyle(.primary)
                }

                // Lane picker (arrows)
                HStack(spacing: 2) {
                    Button {
                        if tasks[index].lane > 0 { withAnimation { tasks[index].lane -= 1 } }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("L\(tasks[index].lane + 1)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Button {
                        if tasks[index].lane < laneCount - 1 { withAnimation { tasks[index].lane += 1 } }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Status pill
                Button {
                    let all = RoadmapStatus.allCases
                    let idx2 = all.firstIndex(of: tasks[index].status) ?? 0
                    withAnimation(.spring(response: 0.3)) { tasks[index].status = all[(idx2 + 1) % all.count] }
                } label: {
                    Text(tasks[index].status.rawValue)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(statusBadgeColor(tasks[index].status), in: .capsule)
                        .foregroundStyle(.white)
                }
            }

            // Start → End slider row
            HStack(spacing: 8) {
                Text("Start")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    .frame(width: 28)
                Slider(value: $tasks[index].startPos, in: 0...tasks[index].endPos, step: 1)
                Text("\(Int(tasks[index].startPos))%")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    .frame(width: 28)
            }
            .padding(.leading, 34)

            HStack(spacing: 8) {
                Text("End")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    .frame(width: 28)
                Slider(value: $tasks[index].endPos, in: tasks[index].startPos...100, step: 1)
                Text("\(Int(tasks[index].endPos))%")
                    .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    .frame(width: 28)
            }
            .padding(.leading, 34)

            if progressFill {
                HStack(spacing: 8) {
                    Text("Prog")
                        .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                        .frame(width: 28)
                    Slider(value: $tasks[index].progress, in: 0...100, step: 5)
                    Text("\(Int(tasks[index].progress))%")
                        .font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                        .frame(width: 28)
                }
                .padding(.leading, 34)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        if index < tasks.count - 1 { Divider().padding(.horizontal, 20) }
    }

    func statusBadgeColor(_ status: RoadmapStatus) -> Color {
        switch status {
        case .completed: return .green
        case .active:    return .orange
        case .upcoming:  return .secondary
        case .blocked:   return .red
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

    func addTask() {
        let colIdx = tasks.count % Self.colorPalette.count
        let lastEnd = tasks.map { $0.endPos }.max() ?? 50
        let newStart = min(90, lastEnd + 2)
        let newEnd = min(100, newStart + 20)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            tasks.append(RoadmapTask(
                name: "Task \(tasks.count + 1)",
                startPos: newStart,
                endPos: newEnd,
                lane: tasks.count % laneCount,
                progress: 0,
                description: "",
                taskType: .fixed,
                status: .upcoming,
                color: Self.colorPalette[colIdx]
            ))
        }
    }
}

#Preview {
    ScrollView {
        ProjectRoadmapCard(
            title: "Project Roadmap",
            categories: ["Roadmap", "Project"],
            tasks: [
                RoadmapTask(name: "Research",   startPos: 0,  endPos: 20, lane: 0, progress: 100, description: "Market analysis",    taskType: .fixed,      status: .completed, color: AnalyticsCard.colorPalette[0]),
                RoadmapTask(name: "Wireframes", startPos: 15, endPos: 38, lane: 1, progress: 100, description: "UX designs",         taskType: .fixed,      status: .completed, color: AnalyticsCard.colorPalette[1]),
                RoadmapTask(name: "Backend",    startPos: 20, endPos: 65, lane: 2, progress: 70,  description: "API development",    taskType: .continuous, status: .active,    color: AnalyticsCard.colorPalette[2]),
                RoadmapTask(name: "iOS App",    startPos: 35, endPos: 75, lane: 1, progress: 45,  description: "SwiftUI screens",   taskType: .fixed,      status: .active,    color: AnalyticsCard.colorPalette[3]),
                RoadmapTask(name: "Launch",     startPos: 75, endPos: 78, lane: 0, progress: 0,   description: "App Store release", taskType: .milestone,  status: .upcoming,  color: AnalyticsCard.colorPalette[4]),
                RoadmapTask(name: "Marketing",  startPos: 65, endPos: 100,lane: 2, progress: 10,  description: "Campaign rollout",  taskType: .fixed,      status: .upcoming,  color: AnalyticsCard.colorPalette[5]),
            ],
            lanes: [
                RoadmapLane(name: "Strategy", color: AnalyticsCard.colorPalette[0]),
                RoadmapLane(name: "Design",   color: AnalyticsCard.colorPalette[1]),
                RoadmapLane(name: "Engineering", color: AnalyticsCard.colorPalette[2]),
            ]
        )
        .padding(.top, 20)
    }
}
