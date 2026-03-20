//
//  SankeyDiagramExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Data Models

struct SankeyNode: Identifiable {
    let id = UUID()
    var nodeID: String
    var label: String
    var category: String
    var color: Color
}

struct SankeyFlow: Identifiable {
    let id = UUID()
    var sourceID: UUID
    var targetID: UUID
    var value: Double
}

// MARK: - Layout Result Structs

struct SKNodeRect {
    var id: UUID
    var rect: CGRect
    var layer: Int
    var color: Color
    var label: String
    var inflow: Double
    var outflow: Double
}

struct SKFlowPath {
    var id: UUID
    var sourceRect: CGRect
    var targetRect: CGRect
    var sourceYOffset: CGFloat
    var targetYOffset: CGFloat
    var width: CGFloat
    var color: Color
    var value: Double
    var sourceLabel: String
    var targetLabel: String
}

// MARK: - Enums

enum SKDirection: String, CaseIterable { case leftRight = "L→R", rightLeft = "R←L", topBottom = "T↓B" }
enum SKAlignment: String, CaseIterable { case justify = "Justify", center = "Center", left = "Left", right = "Right" }
enum SKSorting: String, CaseIterable { case none_ = "None", asc = "Asc", desc = "Desc" }
enum SKLinkColor: String, CaseIterable { case source = "Source", target = "Target", custom = "Custom" }
enum SKColorMode: String, CaseIterable { case byNode = "By Node", byFlow = "By Flow", custom = "Custom" }
enum SKLabelPos: String, CaseIterable { case inside = "Inside", outside = "Outside", hidden = "Hidden" }
enum SKOverflow: String, CaseIterable { case wrap = "Wrap", truncate = "Truncate" }

// MARK: - Sankey Diagram Card

struct SankeyDiagramCard: View {

    let title: String
    let categories: [String]
    @State private var nodes: [SankeyNode]
    @State private var flows: [SankeyFlow]
    @State private var isExpanded = false
    @State private var appeared = false
    @State private var highlightedFlowID: UUID? = nil
    @State private var highlightedNodeID: UUID? = nil
    @State private var tooltipFlowID: UUID? = nil

    // Zoom & Pan
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Layout
    @State private var flowDirection: SKDirection = .leftRight
    @State private var nodeAlignment: SKAlignment = .justify
    @State private var nodeSpacing: Double = 12
    @State private var layerSpacing: Double = 80
    @State private var chartPadding: Double = 16

    // Flow behavior
    @State private var linkCurvature: Double = 60
    @State private var linkTension: Double = 50
    @State private var flowSorting: SKSorting = .none_
    @State private var mergeSmallFlows: Bool = false
    @State private var minFlowThreshold: Double = 2

    // Node styling
    @State private var nodeWidth: Double = 18
    @State private var nodeCornerRadius: Double = 4
    @State private var nodePadding: Double = 4
    @State private var nodeStroke: Bool = true

    // Link styling
    @State private var linkOpacity: Double = 0.45
    @State private var gradientFlow: Bool = true
    @State private var linkColorMode: SKLinkColor = .source
    @State private var linkHighlightOnHover: Bool = true

    // Color
    @State private var colorMode: SKColorMode = .byNode
    @State private var primaryColor: Color = SankeyDiagramCard.colorPalette[0]
    @State private var colorScale: Bool = true

    // Labels
    @State private var showNodeLabels: Bool = true
    @State private var showFlowValues: Bool = false
    @State private var labelPos: SKLabelPos = .outside
    @State private var textOverflow: SKOverflow = .truncate

    // Interaction
    @State private var hoverHighlight: Bool = true
    @State private var hoverTooltip: Bool = true
    @State private var zoomPanEnabled: Bool = false
    @State private var dragNodesEnabled: Bool = false
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.7
    @State private var nodeDragOffsets: [UUID: CGFloat] = [:]

    // Flow Analysis
    @State private var showTotals: Bool = false
    @State private var balanceIndicator: Bool = false

    // Filter
    @State private var filterByValue: Double = 0

    // MARK: - Static

    static let colorPalette = AnalyticsCard.colorPalette

    // MARK: - Init

    init(title: String, categories: [String], nodes: [SankeyNode], flows: [SankeyFlow]) {
        self.title = title
        self.categories = categories
        self._nodes = State(initialValue: nodes)
        self._flows = State(initialValue: flows)
    }

    // MARK: - Computed

    var uniqueCategories: [String] { Array(Set(nodes.map { $0.category })).sorted() }

    var activeFlows: [SankeyFlow] {
        var f = flows.filter { $0.value >= filterByValue }
        if mergeSmallFlows {
            f = f.filter { $0.value >= minFlowThreshold }
        }
        return f
    }

    var maxFlowValue: Double {
        flows.map { $0.value }.max() ?? 100
    }

    func nodeColor(for n: SankeyNode) -> Color {
        switch colorMode {
        case .byNode:
            let idx = uniqueCategories.firstIndex(of: n.category) ?? 0
            return SankeyDiagramCard.colorPalette[idx % SankeyDiagramCard.colorPalette.count]
        case .byFlow:
            let idx = nodes.firstIndex(where: { $0.id == n.id }) ?? 0
            return SankeyDiagramCard.colorPalette[idx % SankeyDiagramCard.colorPalette.count]
        case .custom:
            return primaryColor
        }
    }

    // MARK: - Layout Algorithm

    func computeLayout(size: CGSize) -> (nodes: [SKNodeRect], flows: [SKFlowPath]) {
        guard !nodes.isEmpty else { return ([], []) }

        var outgoing: [UUID: [UUID]] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, [UUID]()) })
        var incoming: [UUID: [UUID]] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, [UUID]()) })
        for f in activeFlows {
            outgoing[f.sourceID]?.append(f.targetID)
            incoming[f.targetID]?.append(f.sourceID)
        }

        var layers: [UUID: Int] = [:]
        let sources = nodes.filter { incoming[$0.id]?.isEmpty ?? true }.map { $0.id }
        for sid in sources { layers[sid] = 0 }

        var queue = sources
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            let curLayer = layers[cur] ?? 0
            for next in outgoing[cur] ?? [] {
                let newLayer = curLayer + 1
                if (layers[next] ?? -1) < newLayer {
                    layers[next] = newLayer
                    queue.append(next)
                }
            }
        }
        let maxLayer = layers.values.max() ?? 0
        nodes.forEach { if layers[$0.id] == nil { layers[$0.id] = maxLayer } }

        var byLayer: [Int: [SankeyNode]] = [:]
        for n in nodes { byLayer[layers[n.id] ?? 0, default: []].append(n) }
        let sortedLayers = byLayer.keys.sorted()
        let numLayers = sortedLayers.count

        var inflowMap: [UUID: Double] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0.0) })
        var outflowMap: [UUID: Double] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, 0.0) })
        for f in activeFlows {
            outflowMap[f.sourceID, default: 0] += f.value
            inflowMap[f.targetID, default: 0] += f.value
        }

        let pad = CGFloat(chartPadding)
        let nw = CGFloat(nodeWidth)
        let ns = CGFloat(nodeSpacing)
        let usableW = size.width - pad * 2
        let usableH = size.height - pad * 2

        let layerX: (Int) -> CGFloat = { layerIdx in
            let fraction = numLayers > 1 ? CGFloat(layerIdx) / CGFloat(numLayers - 1) : 0.5
            let x = pad + fraction * (usableW - nw)
            return self.flowDirection == .rightLeft ? size.width - x - nw : x
        }

        var nodeRects: [UUID: CGRect] = [:]
        for li in sortedLayers {
            let nodesInLayer = byLayer[li] ?? []
            let layerNodes: [SankeyNode]
            switch flowSorting {
            case .none_: layerNodes = nodesInLayer
            case .asc:   layerNodes = nodesInLayer.sorted { max(inflowMap[$0.id] ?? 0, outflowMap[$0.id] ?? 0) < max(inflowMap[$1.id] ?? 0, outflowMap[$1.id] ?? 0) }
            case .desc:  layerNodes = nodesInLayer.sorted { max(inflowMap[$0.id] ?? 0, outflowMap[$0.id] ?? 0) > max(inflowMap[$1.id] ?? 0, outflowMap[$1.id] ?? 0) }
            }
            let totalFlow = layerNodes.reduce(0.0) { $0 + max(inflowMap[$1.id] ?? 0, outflowMap[$1.id] ?? 0, 1) }
            let totalSpacing = ns * CGFloat(max(0, layerNodes.count - 1))
            let availH = usableH - totalSpacing
            var yOffset: CGFloat = pad

            for n in layerNodes {
                let nodeFlow = max(inflowMap[n.id] ?? 0, outflowMap[n.id] ?? 0, 1)
                var h = availH * CGFloat(nodeFlow / max(1, totalFlow))
                h = max(h, 12)
                let x = layerX(li)
                let dragOff = nodeDragOffsets[n.id] ?? 0
                let y = yOffset + dragOff
                nodeRects[n.id] = CGRect(x: x, y: y, width: nw, height: h)
                yOffset += h + ns
            }
        }

        var srcYOffset: [UUID: CGFloat] = nodeRects.mapValues { $0.minY }
        var tgtYOffset: [UUID: CGFloat] = nodeRects.mapValues { $0.minY }

        let resultNodes: [SKNodeRect] = nodes.compactMap { n in
            guard let r = nodeRects[n.id] else { return nil }
            return SKNodeRect(id: n.id, rect: r, layer: layers[n.id] ?? 0,
                              color: nodeColor(for: n), label: n.label,
                              inflow: inflowMap[n.id] ?? 0, outflow: outflowMap[n.id] ?? 0)
        }

        var resultFlows: [SKFlowPath] = []

        for f in activeFlows {
            guard let srcRect = nodeRects[f.sourceID], let tgtRect = nodeRects[f.targetID] else { continue }
            let srcNode = nodes.first(where: { $0.id == f.sourceID })
            let tgtNode = nodes.first(where: { $0.id == f.targetID })

            let srcTotalOut = max(1, outflowMap[f.sourceID] ?? 1)
            let tgtTotalIn = max(1, inflowMap[f.targetID] ?? 1)
            let srcH = srcRect.height * CGFloat(f.value / srcTotalOut)
            let tgtH = tgtRect.height * CGFloat(f.value / tgtTotalIn)
            let w = max(srcH, tgtH)

            let sY = srcYOffset[f.sourceID] ?? srcRect.minY
            let tY = tgtYOffset[f.targetID] ?? tgtRect.minY

            let flowColor: Color
            switch linkColorMode {
            case .source: flowColor = nodeColor(for: srcNode ?? nodes[0])
            case .target: flowColor = nodeColor(for: tgtNode ?? nodes[0])
            case .custom: flowColor = primaryColor
            }

            resultFlows.append(SKFlowPath(
                id: f.id, sourceRect: srcRect, targetRect: tgtRect,
                sourceYOffset: sY, targetYOffset: tY, width: w,
                color: flowColor, value: f.value,
                sourceLabel: srcNode?.label ?? "?", targetLabel: tgtNode?.label ?? "?"
            ))
            srcYOffset[f.sourceID] = (srcYOffset[f.sourceID] ?? srcRect.minY) + srcH
            tgtYOffset[f.targetID] = (tgtYOffset[f.targetID] ?? tgtRect.minY) + tgtH
        }

        return (resultNodes, resultFlows)
    }

    // MARK: - Flow Path Drawing

    func sankeyFlowPath(flow: SKFlowPath) -> Path {
        let sx = flow.sourceRect.maxX
        let tx = flow.targetRect.minX
        let curveX = sx + (tx - sx) * CGFloat(linkCurvature) / 100

        return Path { p in
            p.move(to: CGPoint(x: sx, y: flow.sourceYOffset))
            p.addCurve(to: CGPoint(x: tx, y: flow.targetYOffset),
                       control1: CGPoint(x: curveX, y: flow.sourceYOffset),
                       control2: CGPoint(x: tx - (tx - sx) * CGFloat(linkCurvature) / 100, y: flow.targetYOffset))
            p.addLine(to: CGPoint(x: tx, y: flow.targetYOffset + flow.width))
            p.addCurve(to: CGPoint(x: sx, y: flow.sourceYOffset + flow.width),
                       control1: CGPoint(x: tx - (tx - sx) * CGFloat(linkCurvature) / 100, y: flow.targetYOffset + flow.width),
                       control2: CGPoint(x: curveX, y: flow.sourceYOffset + flow.width))
            p.closeSubpath()
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = geo.size
            let layout = computeLayout(size: size)
            let nodeRects = layout.nodes
            let flowPaths = layout.flows

            ZStack {
                // Draw flows first (behind nodes)
                ForEach(flowPaths, id: \.id) { flow in
                    let isHL = highlightedFlowID == flow.id
                    let path = sankeyFlowPath(flow: flow)

                    ZStack {
                        if gradientFlow {
                            path.fill(
                                LinearGradient(
                                    colors: [flow.color.opacity(isHL ? linkOpacity * 1.8 : linkOpacity),
                                             flow.color.opacity((isHL ? linkOpacity * 1.8 : linkOpacity) * 0.6)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        } else {
                            path.fill(flow.color.opacity(isHL ? linkOpacity * 1.8 : linkOpacity))
                        }
                        path.stroke(Color.white.opacity(0.15), lineWidth: 0.5)

                        path.fill(Color.clear).contentShape(path)
                            .onTapGesture {
                                guard hoverHighlight || hoverTooltip else { return }
                                withAnimation(.spring(response: 0.3)) {
                                    highlightedFlowID = highlightedFlowID == flow.id ? nil : flow.id
                                    tooltipFlowID = hoverTooltip ? (tooltipFlowID == flow.id ? nil : flow.id) : nil
                                }
                            }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: animationDuration), value: appeared)

                // Draw nodes on top
                ForEach(nodeRects, id: \.id) { n in
                    let nr = CGFloat(nodeCornerRadius)
                    let shape = RoundedRectangle(cornerRadius: nr, style: .continuous)
                    let isHL = highlightedNodeID == n.id

                    ZStack {
                        shape.fill(n.color.opacity(0.15)).blur(radius: 3).offset(y: 2)
                        shape.fill(n.color.opacity(0.88)).glassEffect(.clear, in: shape)
                        if nodeStroke { shape.stroke(Color.white.opacity(0.35), lineWidth: 0.5) }
                        shape.stroke(Color.white, lineWidth: 4).blur(radius: 2.5).opacity(isHL ? 0.45 : 0.22).clipShape(shape)

                        if showTotals {
                            VStack(spacing: 1) {
                                if n.inflow > 0 { Text(String(format: "↓%.0f", n.inflow)).font(.system(size: 7, design: .rounded)).foregroundStyle(.white.opacity(0.7)) }
                                if n.outflow > 0 { Text(String(format: "↑%.0f", n.outflow)).font(.system(size: 7, design: .rounded)).foregroundStyle(.white.opacity(0.7)) }
                            }
                        }
                        if balanceIndicator {
                            let diff = n.inflow - n.outflow
                            let sym = diff > 0.5 ? "+" : diff < -0.5 ? "−" : "="
                            Text(sym).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .frame(width: n.rect.width, height: n.rect.height)
                    .position(x: n.rect.midX, y: n.rect.midY)
                    .scaleEffect(appeared ? 1 : 0.01)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(animateOnLoad ? Double.random(in: 0...0.2) : 0), value: appeared)
                    .gesture(
                        dragNodesEnabled ?
                        DragGesture()
                            .onChanged { v in
                                nodeDragOffsets[n.id] = (nodeDragOffsets[n.id] ?? 0) + v.translation.height / 20
                            }
                            .simultaneously(with: TapGesture().onEnded {}) : nil
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            highlightedNodeID = highlightedNodeID == n.id ? nil : n.id
                        }
                    }

                    if showNodeLabels && labelPos != .hidden {
                        let isLeft = n.rect.midX < size.width / 2
                        Text(n.label)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(textOverflow == .truncate ? 1 : 2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 70, alignment: isLeft ? .trailing : .leading)
                            .position(
                                x: isLeft ? n.rect.minX - 38 : n.rect.maxX + 38,
                                y: n.rect.midY
                            )
                    }

                    if showFlowValues {
                        let totalVal = n.outflow > 0 ? n.outflow : n.inflow
                        if totalVal > 0 {
                            Text(String(format: "%.0f", totalVal))
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .position(x: n.rect.midX, y: n.rect.midY)
                        }
                    }
                }

                // Tooltip
                if hoverTooltip, let tid = tooltipFlowID, let flow = flowPaths.first(where: { $0.id == tid }) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(flow.sourceLabel) → \(flow.targetLabel)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Divider()
                        HStack(spacing: 4) {
                            Text("Value:").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                            Text(String(format: "%.1f", flow.value)).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color(uiColor: .systemBackground).opacity(0.92), in: .rect(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .frame(width: 140)
                    .position(
                        x: min(max((flow.sourceRect.maxX + flow.targetRect.minX) / 2, 80), size.width - 80),
                        y: max((flow.sourceYOffset + flow.targetYOffset) / 2 - 40, 30)
                    )
                }
            }
            .scaleEffect(zoomPanEnabled ? zoomScale * magnifyBy : 1.0, anchor: .center)
            .offset(x: zoomPanEnabled ? panOffset.width + dragTranslation.width : 0,
                    y: zoomPanEnabled ? panOffset.height + dragTranslation.height : 0)
            .gesture(MagnificationGesture().updating($magnifyBy) { v, s, _ in s = zoomPanEnabled ? v : 1.0 }.onEnded { v in if zoomPanEnabled { zoomScale = min(5, max(0.3, zoomScale * v)) } })
            .simultaneousGesture(DragGesture(minimumDistance: 14).updating($dragTranslation) { v, s, _ in s = zoomPanEnabled ? v.translation : .zero }.onEnded { v in if zoomPanEnabled { panOffset.width += v.translation.width; panOffset.height += v.translation.height } })
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    highlightedFlowID = nil
                    highlightedNodeID = nil
                    tooltipFlowID = nil
                }
            }
            .clipped()
        }
    }

    // MARK: - Settings Helpers

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

    // MARK: - Settings Sections

    var layoutSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Direction")
                HStack(spacing: 4) {
                    ForEach(SKDirection.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: flowDirection == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { flowDirection = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Alignment")
                HStack(spacing: 4) {
                    ForEach(SKAlignment.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: nodeAlignment == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { nodeAlignment = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Node Spacing")
                Slider(value: $nodeSpacing, in: 0...60)
                Text("\(Int(nodeSpacing))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Layer Spacing")
                Slider(value: $layerSpacing, in: 20...120)
                Text("\(Int(layerSpacing))pt").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Padding")
                Slider(value: $chartPadding, in: 0...60)
                Text("\(Int(chartPadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var flowBehaviorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Curvature")
                Slider(value: $linkCurvature, in: 0...100)
                Text("\(Int(linkCurvature))%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Tension")
                Slider(value: $linkTension, in: 0...100)
                Text("\(Int(linkTension))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Sorting")
                HStack(spacing: 4) {
                    ForEach(SKSorting.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: flowSorting == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { flowSorting = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Merge Small")
                Toggle("", isOn: $mergeSmallFlows).labelsHidden().scaleEffect(0.8)
                Text("hide small flows").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if mergeSmallFlows {
                HStack(spacing: 10) {
                    settingsLabel("Min Flow")
                    Slider(value: $minFlowThreshold, in: 0...10)
                    Text(String(format: "%.1f", minFlowThreshold)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    var nodeStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Node Width")
                Slider(value: $nodeWidth, in: 10...40)
                Text("\(Int(nodeWidth))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Corner Radius")
                Slider(value: $nodeCornerRadius, in: 0...12)
                Text("\(Int(nodeCornerRadius))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Node Padding")
                Slider(value: $nodePadding, in: 0...20)
                Text("\(Int(nodePadding))").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Node Stroke")
                Toggle("", isOn: $nodeStroke).labelsHidden().scaleEffect(0.8)
                Text("border outline").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var linkStyleSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Opacity")
                Slider(value: $linkOpacity, in: 0...1)
                Text("\(Int(linkOpacity * 100))%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFlow).labelsHidden().scaleEffect(0.8)
                Text("gradient fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Link Color")
                HStack(spacing: 4) {
                    ForEach(SKLinkColor.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: linkColorMode == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { linkColorMode = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Highlight")
                Toggle("", isOn: $linkHighlightOnHover).labelsHidden().scaleEffect(0.8)
                Text("highlight on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var colorSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color Mode")
                HStack(spacing: 4) {
                    ForEach(SKColorMode.allCases, id: \.self) { c in
                        pillButton(c.rawValue, isSelected: colorMode == c) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { colorMode = c }
                        }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Color Scale")
                Toggle("", isOn: $colorScale).labelsHidden().scaleEffect(0.8)
                Text("scaled by value").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Node Labels")
                Toggle("", isOn: $showNodeLabels).labelsHidden().scaleEffect(0.8)
                Text("show labels").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Flow Values")
                Toggle("", isOn: $showFlowValues).labelsHidden().scaleEffect(0.8)
                Text("show values").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showNodeLabels {
                HStack(spacing: 10) {
                    settingsLabel("Label Pos")
                    HStack(spacing: 4) {
                        ForEach(SKLabelPos.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: labelPos == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPos = c }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Text Overflow")
                    HStack(spacing: 4) {
                        ForEach(SKOverflow.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: textOverflow == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { textOverflow = c }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    var interactionSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Hover HL")
                Toggle("", isOn: $hoverHighlight).labelsHidden().scaleEffect(0.8)
                Text("highlight on tap").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Tooltip")
                Toggle("", isOn: $hoverTooltip).labelsHidden().scaleEffect(0.8)
                Text("show tooltip").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Zoom & Pan")
                Toggle("", isOn: $zoomPanEnabled).labelsHidden().scaleEffect(0.8)
                Text("enable zoom/pan").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Drag Nodes")
                Toggle("", isOn: $dragNodesEnabled).labelsHidden().scaleEffect(0.8)
                Text("drag to reorder").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Animate")
                Toggle("", isOn: $animateOnLoad).labelsHidden().scaleEffect(0.8)
                Text("on appear").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Duration")
                Slider(value: $animationDuration, in: 0.1...2.0)
                Text(String(format: "%.1fs", animationDuration)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    var flowAnalysisSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Show Totals")
                Toggle("", isOn: $showTotals).labelsHidden().scaleEffect(0.8)
                Text("in/out totals").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Balance")
                Toggle("", isOn: $balanceIndicator).labelsHidden().scaleEffect(0.8)
                Text("balance indicator").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    var filterSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Min Value")
                Slider(value: $filterByValue, in: 0...maxFlowValue)
                Text(String(format: "%.0f", filterByValue)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Data List View

    var dataListView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nodes").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Spacer()
                Button {
                    let idx = nodes.count % SankeyDiagramCard.colorPalette.count
                    withAnimation(.spring(response: 0.4)) {
                        nodes.append(SankeyNode(nodeID: "n\(nodes.count+1)", label: "Node \(nodes.count+1)", category: "Group \(nodes.count%3+1)", color: SankeyDiagramCard.colorPalette[idx]))
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(SankeyDiagramCard.colorPalette[nodes.count % SankeyDiagramCard.colorPalette.count]) }
            }
            .padding(.horizontal, 20).padding(.bottom, 10)

            ForEach(Array(nodes.enumerated()), id: \.element.id) { i, n in
                HStack(spacing: 10) {
                    Circle().fill(nodeColor(for: n)).frame(width: 8, height: 8)
                    Text(n.label).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.primary)
                    Spacer()
                    Text(n.category).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                    if nodes.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                let nid = n.id
                                nodes.removeSubrange(i...i)
                                flows.removeAll { $0.sourceID == nid || $0.targetID == nid }
                            }
                        } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if i < nodes.count - 1 { Divider().padding(.horizontal, 20) }
            }

            Divider().padding(.horizontal, 20).padding(.top, 6)

            HStack {
                Text("Flows").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.primary)
                Spacer()
                Button {
                    guard nodes.count >= 2 else { return }
                    withAnimation(.spring(response: 0.4)) {
                        let src = nodes[0].id
                        let tgt = nodes[min(1, nodes.count-1)].id
                        flows.append(SankeyFlow(sourceID: src, targetID: tgt, value: Double.random(in: 10...60)))
                    }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10)

            ForEach(Array(flows.enumerated()), id: \.element.id) { i, f in
                let srcLabel = nodes.first(where: { $0.id == f.sourceID })?.label ?? "?"
                let tgtLabel = nodes.first(where: { $0.id == f.targetID })?.label ?? "?"
                HStack(spacing: 10) {
                    Text("\(srcLabel) → \(tgtLabel)").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.primary).lineLimit(1)
                    Spacer()
                    Slider(value: Binding(get: { f.value }, set: { flows[i].value = $0 }), in: 1...100).frame(width: 80)
                    Text(String(format: "%.0f", f.value)).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.primary).frame(width: 28, alignment: .trailing)
                    Button { withAnimation(.spring(response: 0.4)) { flows.removeSubrange(i...i) } } label: { Image(systemName: "minus.circle").font(.system(size: 16)).foregroundStyle(.secondary) }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                if i < flows.count - 1 { Divider().padding(.horizontal, 20) }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 260)
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
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                }
                VStack(spacing: 14) {
                    Divider().padding(.horizontal, 20)
                    layoutSettingsView
                    flowBehaviorSettingsView
                    nodeStyleSettingsView
                    linkStyleSettingsView
                    colorSettingsView
                    labelSettingsView
                    interactionSettingsView
                    flowAnalysisSettingsView
                    filterSettingsView
                    dataListView
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
                    zoomScale = 1
                    panOffset = .zero
                }
            }
        }
    }
}

// MARK: - Example Usage View

struct SankeyDiagramExample: View {

    static func makeSampleData() -> (nodes: [SankeyNode], flows: [SankeyFlow]) {
        let palette = AnalyticsCard.colorPalette

        let visit   = SankeyNode(nodeID: "visit",   label: "Visits",    category: "Source",    color: palette[0])
        let organic = SankeyNode(nodeID: "organic", label: "Organic",   category: "Channel",   color: palette[1])
        let paid    = SankeyNode(nodeID: "paid",    label: "Paid",      category: "Channel",   color: palette[2])
        let direct  = SankeyNode(nodeID: "direct",  label: "Direct",    category: "Channel",   color: palette[3])
        let signup  = SankeyNode(nodeID: "signup",  label: "Sign Up",   category: "Action",    color: palette[4])
        let browse  = SankeyNode(nodeID: "browse",  label: "Browse",    category: "Action",    color: palette[5])
        let convert = SankeyNode(nodeID: "convert", label: "Convert",   category: "Outcome",   color: palette[0])
        let bounce  = SankeyNode(nodeID: "bounce",  label: "Bounce",    category: "Outcome",   color: palette[1])

        let nodes = [visit, organic, paid, direct, signup, browse, convert, bounce]

        let flows: [SankeyFlow] = [
            SankeyFlow(sourceID: visit.id,   targetID: organic.id, value: 60),
            SankeyFlow(sourceID: visit.id,   targetID: paid.id,    value: 30),
            SankeyFlow(sourceID: visit.id,   targetID: direct.id,  value: 20),
            SankeyFlow(sourceID: organic.id, targetID: signup.id,  value: 35),
            SankeyFlow(sourceID: organic.id, targetID: browse.id,  value: 25),
            SankeyFlow(sourceID: paid.id,    targetID: signup.id,  value: 18),
            SankeyFlow(sourceID: paid.id,    targetID: browse.id,  value: 12),
            SankeyFlow(sourceID: direct.id,  targetID: signup.id,  value: 14),
            SankeyFlow(sourceID: direct.id,  targetID: bounce.id,  value: 6),
            SankeyFlow(sourceID: signup.id,  targetID: convert.id, value: 45),
            SankeyFlow(sourceID: signup.id,  targetID: bounce.id,  value: 22),
            SankeyFlow(sourceID: browse.id,  targetID: convert.id, value: 20),
            SankeyFlow(sourceID: browse.id,  targetID: bounce.id,  value: 17),
        ]

        return (nodes, flows)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                let sample = Self.makeSampleData()
                SankeyDiagramCard(
                    title: "Sankey Diagram",
                    categories: ["Source", "Channel", "Action", "Outcome"],
                    nodes: sample.nodes,
                    flows: sample.flows
                )
            }
            .padding(.vertical, 20)
        }
        .background(Color(uiColor: .systemBackground))
    }
}
