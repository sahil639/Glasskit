//
//  RadialProgressExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Radial Progress Shape (donut arc, no gap)

struct RadialProgressShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRadiusRatio
        guard endAngle.degrees > startAngle.degrees else { return Path() }
        var p = Path()
        p.move(to: CGPoint(x: c.x + innerR * CGFloat(cos(startAngle.radians)),
                           y: c.y + innerR * CGFloat(sin(startAngle.radians))))
        p.addArc(center: c, radius: innerR, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.addLine(to: CGPoint(x: c.x + outerR * CGFloat(cos(endAngle.radians)),
                              y: c.y + outerR * CGFloat(sin(endAngle.radians))))
        p.addArc(center: c, radius: outerR, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Radial Progress Arc Path (center-line arc for rounded edges)

struct RadialProgressArcPath: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let midR = outerR * (1 + innerRadiusRatio) / 2
        guard endAngle.degrees > startAngle.degrees else { return Path() }
        var p = Path()
        p.addArc(center: c, radius: midR, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return p
    }
}

// MARK: - Radial Progress Card

struct RadialProgressCard: View {
    let title: String
    let categories: [String]

    // Data
    @State private var progressLabel: String = "Goal"
    @State private var progressValue: Double = 68
    @State private var maxValue: Double = 100
    @State private var progressColor: Color = Color(red: 0.28, green: 0.16, blue: 0.72)

    // UI State
    @State private var isExpanded = false
    @State private var editingField: EditingField? = nil
    @State private var editingText = ""

    // Progress Value Controls
    @State private var progressStyle: ProgressStyle = .percent

    // Geometry
    @State private var startAngle: Double = -90
    @State private var arcPreset: ArcPreset = .full
    @State private var innerRatio: Double = 0.65

    // Track
    @State private var showTrack: Bool = true
    @State private var trackOpacity: Double = 0.08

    // Progress Styling
    @State private var gradientFill: Bool = false
    @State private var roundedEdges: Bool = true
    @State private var shadowEnabled: Bool = true

    // Animation
    @State private var animateOnLoad: Bool = true
    @State private var animationDuration: Double = 0.8
    @State private var animatedFraction: Double = 0

    // Center Content
    @State private var centerContent: CenterContent = .value
    @State private var centerAlignment: CenterAlignment = .middle
    @State private var centerSize: Double = 36

    // Labels
    @State private var showPercentage: Bool = true
    @State private var showValue: Bool = false
    @State private var labelPosition: LabelPosition = .center

    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    // MARK: - Enums

    enum EditingField: Hashable { case value, maxValue, label }

    enum ProgressStyle: String, CaseIterable { case percent = "Percent", fraction = "Fraction", raw = "Raw" }
    enum ArcPreset: String, CaseIterable {
        case half = "180°", wide = "220°", wider = "240°", quarter = "270°", full = "360°"
        var degrees: Double {
            switch self {
            case .half: return 180; case .wide: return 220
            case .wider: return 240; case .quarter: return 270; case .full: return 360
            }
        }
    }
    enum CenterContent: String, CaseIterable { case none = "None", value = "Value", label = "Label", icon = "Icon" }
    enum CenterAlignment: String, CaseIterable { case top = "Top", middle = "Mid", bottom = "Bot" }
    enum LabelPosition: String, CaseIterable { case center = "Center", outside = "Outside", hidden = "Hidden" }

    // MARK: - Computed

    var fraction: Double { maxValue > 0 ? min(1, max(0, progressValue / maxValue)) : 0 }
    var effectiveArcAngle: Double { arcPreset.degrees }
    var displayFraction: Double { animateOnLoad ? animatedFraction : fraction }

    // MARK: - Init

    init(title: String, categories: [String]) {
        self.title = title
        self.categories = categories
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            chartView
                .frame(height: 240)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .shadow(color: .black.opacity(shadowEnabled ? 0.18 : 0), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(shadowEnabled ? 0.18 : 0), radius: 3, x: 0, y: 2)

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
                    progressValueSettingsView
                    geometrySettingsView
                    trackSettingsView
                    progressStylingView
                    animationSettingsView
                    centerSettingsView
                    labelSettingsView
                    dataItemView
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
        .onTapGesture { editingField = nil }
        .onAppear {
            guard animateOnLoad else { return }
            animatedFraction = 0
            withAnimation(.easeOut(duration: animationDuration)) { animatedFraction = fraction }
        }
        .onChange(of: fraction) { _, newFraction in
            if animateOnLoad {
                withAnimation(.spring(response: animationDuration, dampingFraction: 0.8)) { animatedFraction = newFraction }
            }
        }
        .onChange(of: animateOnLoad) { _, enabled in
            if enabled {
                animatedFraction = 0
                withAnimation(.easeOut(duration: animationDuration)) { animatedFraction = fraction }
            } else {
                animatedFraction = fraction
            }
        }
    }

    // MARK: - Chart View

    var chartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerR = size / 2
            let strokeW = outerR * (1 - CGFloat(innerRatio))
            let trackEndDeg = startAngle + effectiveArcAngle
            let progressEndDeg = startAngle + effectiveArcAngle * displayFraction

            ZStack {
                // Track background arc
                if showTrack {
                    RadialProgressShape(
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(trackEndDeg),
                        innerRadiusRatio: CGFloat(innerRatio)
                    )
                    .fill(Color.black.opacity(trackOpacity))
                }

                // Progress arc
                if displayFraction > 0.002 {
                    let progressShape = RadialProgressShape(
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(progressEndDeg),
                        innerRadiusRatio: CGFloat(innerRatio)
                    )
                    let grad = LinearGradient(
                        colors: [progressColor.opacity(0.9), progressColor.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    )
                    Group {
                        if roundedEdges {
                            let arcPath = RadialProgressArcPath(
                                startAngle: .degrees(startAngle),
                                endAngle: .degrees(progressEndDeg),
                                innerRadiusRatio: CGFloat(innerRatio)
                            )
                            if gradientFill {
                                arcPath.stroke(grad, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                                    .glassEffect(.clear, in: progressShape)
                            } else {
                                arcPath.stroke(progressColor.opacity(0.75), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                                    .glassEffect(.clear, in: progressShape)
                            }
                        } else {
                            if gradientFill {
                                progressShape.fill(grad).glassEffect(.clear, in: progressShape)
                            } else {
                                progressShape.fill(progressColor.opacity(0.75)).glassEffect(.clear, in: progressShape)
                            }
                        }
                    }
                    .overlay(progressShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4))
                    .overlay(
                        progressShape
                            .stroke(Color.white, lineWidth: 8)
                            .blur(radius: 4)
                            .opacity(0.25)
                            .clipShape(progressShape)
                    )
                }

                // Center content
                if centerContent != .none {
                    centerOverlay(size: size, outerR: outerR)
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: displayFraction)
        }
    }

    @ViewBuilder
    func centerOverlay(size: CGFloat, outerR: CGFloat) -> some View {
        let actualInnerR = outerR * CGFloat(innerRatio)
        let cy: CGFloat = {
            switch centerAlignment {
            case .top: return size / 2 - actualInnerR * 0.4
            case .middle: return size / 2
            case .bottom: return size / 2 + actualInnerR * 0.4
            }
        }()
        switch centerContent {
        case .none: EmptyView()
        case .value:
            VStack(spacing: 2) {
                Text(centerValueText)
                    .font(.system(size: CGFloat(centerSize), weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                if showValue {
                    Text(String(format: "%.0f / %.0f", progressValue, maxValue))
                        .font(.system(size: CGFloat(centerSize) * 0.35, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .position(x: size / 2, y: cy)
        case .label:
            Text(progressLabel)
                .font(.system(size: CGFloat(centerSize) * 0.45, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: actualInnerR * 1.4)
                .position(x: size / 2, y: cy)
        case .icon:
            Image(systemName: "target")
                .font(.system(size: CGFloat(centerSize)))
                .foregroundStyle(.secondary)
                .position(x: size / 2, y: cy)
        }
    }

    var centerValueText: String {
        switch progressStyle {
        case .percent: return String(format: "%.0f%%", displayFraction * 100)
        case .fraction: return String(format: "%.0f/%.0f", progressValue, maxValue)
        case .raw: return String(format: "%.0f", progressValue)
        }
    }

    // MARK: - Settings: Progress Value

    var progressValueSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Value")
                Slider(value: $progressValue, in: 0...maxValue, step: 1)
                    .animation(.spring(response: 0.3), value: progressValue)
                Text(String(format: "%.0f", progressValue))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Max")
                Slider(value: $maxValue, in: 1...1000, step: 1)
                Text(String(format: "%.0f", maxValue))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Style")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(ProgressStyle.allCases, id: \.self) { s in
                            pillButton(s.rawValue, isSelected: progressStyle == s) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { progressStyle = s }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Settings: Geometry

    var geometrySettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Arc")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(ArcPreset.allCases, id: \.self) { preset in
                            pillButton(preset.rawValue, isSelected: arcPreset == preset) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { arcPreset = preset }
                            }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                settingsLabel("Start")
                Slider(value: $startAngle, in: -180...180, step: 15)
                    .animation(.spring(response: 0.3), value: startAngle)
                Text("\(Int(startAngle))°")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
            HStack(spacing: 10) {
                settingsLabel("Radius")
                Slider(value: $innerRatio, in: 0...0.8, step: 0.05)
                Text("\(Int(innerRatio * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
            }
        }
    }

    // MARK: - Settings: Track

    var trackSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Track")
                Toggle("", isOn: $showTrack).labelsHidden().scaleEffect(0.8)
                Text("Background arc").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            if showTrack {
                HStack(spacing: 10) {
                    settingsLabel("Opacity")
                    Slider(value: $trackOpacity, in: 0...0.3, step: 0.01)
                    Text("\(Int(trackOpacity * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Progress Styling

    var progressStylingView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Color")
                Button { presentColorPicker() } label: {
                    Circle()
                        .fill(progressColor)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Gradient")
                Toggle("", isOn: $gradientFill).labelsHidden().scaleEffect(0.8)
                Text("Gradient fill").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Edges")
                HStack(spacing: 4) {
                    pillButton("Sharp", isSelected: !roundedEdges) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { roundedEdges = false }
                    }
                    pillButton("Rounded", isSelected: roundedEdges) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { roundedEdges = true }
                    }
                }
                Spacer()
            }
            HStack(spacing: 10) {
                settingsLabel("Shadow")
                HStack(spacing: 4) {
                    pillButton("Soft", isSelected: shadowEnabled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shadowEnabled = true }
                    }
                    pillButton("None", isSelected: !shadowEnabled) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { shadowEnabled = false }
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Settings: Animation

    var animationSettingsView: some View {
        settingsSection {
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

    // MARK: - Settings: Center

    var centerSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Content")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(CenterContent.allCases, id: \.self) { c in
                            pillButton(c.rawValue, isSelected: centerContent == c) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { centerContent = c }
                            }
                        }
                    }
                }
            }
            if centerContent != .none {
                HStack(spacing: 10) {
                    settingsLabel("Align")
                    HStack(spacing: 4) {
                        ForEach(CenterAlignment.allCases, id: \.self) { a in
                            pillButton(a.rawValue, isSelected: centerAlignment == a) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { centerAlignment = a }
                            }
                        }
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Size")
                    Slider(value: $centerSize, in: 10...80, step: 2)
                    Text("\(Int(centerSize))pt")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Settings: Labels

    var labelSettingsView: some View {
        settingsSection {
            HStack(spacing: 10) {
                settingsLabel("Labels")
                HStack(spacing: 4) {
                    ForEach(LabelPosition.allCases, id: \.self) { p in
                        pillButton(p.rawValue, isSelected: labelPosition == p) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { labelPosition = p }
                        }
                    }
                }
                Spacer()
            }
            if labelPosition != .hidden {
                HStack(spacing: 10) {
                    settingsLabel("Show %")
                    Toggle("", isOn: $showPercentage).labelsHidden().scaleEffect(0.8)
                    Text("Show percentage").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
                HStack(spacing: 10) {
                    settingsLabel("Show Val")
                    Toggle("", isOn: $showValue).labelsHidden().scaleEffect(0.8)
                    Text("Show raw value").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Data Item View

    var dataItemView: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 20)
            HStack(spacing: 12) {
                Button { presentColorPicker() } label: {
                    Circle()
                        .fill(progressColor)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                }
                if editingField == .label {
                    TextField("Label", text: $progressLabel)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .onSubmit { editingField = nil }
                } else {
                    Button {
                        editingField = .label
                    } label: {
                        Text(progressLabel)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .underline(color: .primary.opacity(0.25))
                    }
                    .foregroundStyle(.primary)
                }
                Spacer()
                if editingField == .value {
                    HStack(spacing: 2) {
                        TextField("0", text: $editingText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 48)
                            .onChange(of: editingText) { _, val in
                                if let v = Double(val) { progressValue = min(maxValue, max(0, v)) }
                            }
                        Text("/\(Int(maxValue))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        editingField = .value
                        editingText = "\(Int(progressValue))"
                    } label: {
                        Text("\(Int(progressValue))/\(Int(maxValue))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .underline(color: .primary.opacity(0.25))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
    }

    // MARK: - Helpers

    func presentColorPicker() {
        #if os(iOS)
        let coord = ColorPickerCoordinator { color in progressColor = color }
        pickerCoordinator = coord
        let vc = UIColorPickerViewController()
        vc.selectedColor = UIColor(progressColor)
        vc.supportsAlpha = false
        vc.delegate = coord
        topViewController()?.present(vc, animated: true)
        #endif
    }

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
}

#Preview {
    ScrollView {
        RadialProgressCard(title: "Radial Progress", categories: ["Radial Progress"])
            .padding(.top, 20)
    }
}
