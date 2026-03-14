//
//  AnalyticsExample.swift
//  GlassKit
//

import SwiftUI

// MARK: - Color Picker Coordinator (iOS)

#if os(iOS)
final class ColorPickerCoordinator: NSObject, UIColorPickerViewControllerDelegate {
    var onSelect: (Color) -> Void
    init(_ onSelect: @escaping (Color) -> Void) { self.onSelect = onSelect }

    func colorPickerViewController(_ vc: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        onSelect(Color(color))
    }
}

func topViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }),
          var vc = window.rootViewController else { return nil }
    while let presented = vc.presentedViewController { vc = presented }
    return vc
}
#endif

// MARK: - Analytics Data Model

struct AnalyticsDataItem: Identifiable {
    let id = UUID()
    let label: String
    var percentage: Double
    var color: Color
}

// MARK: - Pie Slice Shape

struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat = 0.52
    var gap: Double = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRadiusRatio
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees else { return Path() }
        var p = Path()
        p.move(to: CGPoint(x: c.x + innerR * CGFloat(cos(s.radians)), y: c.y + innerR * CGFloat(sin(s.radians))))
        p.addArc(center: c, radius: innerR, startAngle: s, endAngle: e, clockwise: false)
        p.addLine(to: CGPoint(x: c.x + outerR * CGFloat(cos(e.radians)), y: c.y + outerR * CGFloat(sin(e.radians))))
        p.addArc(center: c, radius: outerR, startAngle: e, endAngle: s, clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Pie Arc Path (for rounded edges stroke rendering)

struct PieArcPath: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat = 0.52
    var gap: Double = 1.5

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let midR = outerR * (1 + innerRadiusRatio) / 2
        let s = Angle(degrees: startAngle.degrees + gap)
        let e = Angle(degrees: endAngle.degrees - gap)
        guard e.degrees > s.degrees else { return Path() }
        var p = Path()
        p.addArc(center: c, radius: midR, startAngle: s, endAngle: e, clockwise: false)
        return p
    }
}

// MARK: - Analytics Card

struct AnalyticsCard: View {
    let title: String
    let categories: [String]
    @State private var items: [AnalyticsDataItem]
    @State private var isExpanded: Bool = false
    @State private var editingID: UUID? = nil
    @State private var editingText: String = ""
    @State private var sliceGap: Double = 1.5
    @State private var chartStartAngle: Double = -90.0
    @State private var sortOrder: SortOrder = .none
    @State private var roundedEdges: Bool = false
    #if os(iOS)
    @State private var pickerCoordinator: ColorPickerCoordinator? = nil
    #endif

    static let colorPalette: [Color] = [
        Color(red: 0.28, green: 0.16, blue: 0.72),
        Color(red: 0.62, green: 0.52, blue: 0.88),
        Color(red: 0.82, green: 0.78, blue: 0.94),
        Color(red: 0.56, green: 0.82, blue: 0.72),
        Color(red: 0.38, green: 0.65, blue: 0.58),
        Color(red: 0.82, green: 0.92, blue: 0.88),
    ]

    enum SortOrder: String, CaseIterable {
        case none = "Default"
        case ascending = "Asc"
        case descending = "Desc"
    }

    init(title: String, categories: [String], items: [AnalyticsDataItem]) {
        self.title = title
        self.categories = categories
        self._items = State(initialValue: items)
    }

    // MARK: Slice computation

    struct Slice: Identifiable {
        let id: UUID
        var startAngle: Angle
        var endAngle: Angle
        let color: Color
    }

    var slices: [Slice] {
        var result: [Slice] = []
        var cursor = chartStartAngle
        let sorted: [AnalyticsDataItem] = {
            switch sortOrder {
            case .none: return items
            case .ascending: return items.sorted { $0.percentage < $1.percentage }
            case .descending: return items.sorted { $0.percentage > $1.percentage }
            }
        }()
        let total = sorted.reduce(0) { $0 + $1.percentage }
        guard total > 0 else { return [] }
        for item in sorted {
            let sweep = 360.0 * item.percentage / total
            result.append(Slice(id: item.id, startAngle: .degrees(cursor), endAngle: .degrees(cursor + sweep), color: item.color))
            cursor += sweep
        }
        return result
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {

            // TOP — pie chart (always visible)
            pieChartView
                .frame(height: 240)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
            Divider().padding(.top, 16).padding(.horizontal, 12)

            // BOTTOM — title row + collapsible controls
            VStack(spacing: 0) {

                // Title row with dropdown toggle
                Button {
                    isExpanded.toggle()
                } label: {
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }

                // Always rendered — height clips to 0 when collapsed
                VStack(spacing: 14) {
                    Divider().padding(.horizontal, 20)
                    pieSettingsView
                    itemListView
                }
                .frame(maxHeight: isExpanded ? .infinity : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isExpanded)
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemGray6), in: .rect(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .onTapGesture { editingID = nil }
    }

    // MARK: Pie settings

    var pieSettingsView: some View {
        VStack(spacing: 10) {
            // Slice Spacing
            HStack(spacing: 10) {
                Text("Spacing")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .leading)
                Slider(value: $sliceGap, in: 0...10, step: 0.5)
                    .animation(.spring(response: 0.3), value: sliceGap)
                Text(String(format: "%.1f°", sliceGap))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }

            // Start Angle
            HStack(spacing: 10) {
                Text("Start")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .leading)
                Slider(value: $chartStartAngle, in: -180...180, step: 15)
                    .animation(.spring(response: 0.3), value: chartStartAngle)
                Text("\(Int(chartStartAngle))°")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }

            // Sort Order
            HStack(spacing: 10) {
                Text("Sort")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .leading)
                HStack(spacing: 4) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                sortOrder = order
                            }
                        } label: {
                            Text(order.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(sortOrder == order ? Color.black.opacity(0.1) : Color.clear, in: .capsule)
                        }
                        .foregroundStyle(sortOrder == order ? .primary : .secondary)
                    }
                }
                Spacer()
            }

            // Edges
            HStack(spacing: 10) {
                Text("Edges")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .leading)
                HStack(spacing: 4) {
                    ForEach(["Sharp", "Rounded"], id: \.self) { style in
                        let isSelected = style == "Rounded" ? roundedEdges : !roundedEdges
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                roundedEdges = style == "Rounded"
                            }
                        } label: {
                            Text(style)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(isSelected ? Color.black.opacity(0.1) : Color.clear, in: .capsule)
                        }
                        .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.04), in: .rect(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 4)
    }

    // MARK: Item list view

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
    func itemRow(index: Int, item: AnalyticsDataItem) -> some View {
        HStack(spacing: 12) {
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
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            }
            Text(item.label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            if editingID == item.id {
                HStack(spacing: 2) {
                    TextField("0", text: $editingText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .onChange(of: editingText) { _, val in
                            if let v = Double(val) { redistribute(for: item.id, to: v) }
                        }
                    Text("%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    editingID = item.id
                    editingText = "\(Int(item.percentage))"
                } label: {
                    Text("\(Int(item.percentage))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .underline(color: .primary.opacity(0.25))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        if index < items.count - 1 { Divider().padding(.horizontal, 20) }
    }

    // MARK: Pie chart

    var pieChartView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerR = size / 2
            let innerRadiusRatio: CGFloat = 0.52
            let strokeWidth = outerR * (1 - innerRadiusRatio)
            ZStack {
                ForEach(slices) { slice in
                    let sliceShape = PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle, gap: sliceGap)
                    Group {
                        if roundedEdges {
                            PieArcPath(startAngle: slice.startAngle, endAngle: slice.endAngle, gap: sliceGap)
                                .stroke(slice.color.opacity(0.75), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                                .glassEffect(.clear, in: sliceShape)
                        } else {
                            sliceShape
                                .fill(slice.color.opacity(0.75))
                                .glassEffect(.clear, in: sliceShape)
                        }
                    }
                    .overlay(sliceShape.stroke(Color.white.opacity(0.25), lineWidth: 0.4))
                    .overlay(
                        sliceShape
                            .stroke(Color.white, lineWidth: 8)
                            .blur(radius: 4)
                            .opacity(0.25)
                            .clipShape(sliceShape)
                    )
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: slices.map { $0.startAngle.degrees })
        }
    }

    // MARK: Logic

    func redistribute(for id: UUID, to newValue: Double) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let clamped = min(100, max(0, newValue))
        let remaining = 100.0 - clamped
        let others = items.indices.filter { $0 != idx }
        let otherSum = others.reduce(0.0) { $0 + items[$1].percentage }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items[idx].percentage = clamped
            if otherSum > 0 {
                let scale = remaining / otherSum
                for i in others { items[i].percentage = max(0, items[i].percentage * scale) }
            } else if !others.isEmpty {
                let share = remaining / Double(others.count)
                for i in others { items[i].percentage = share }
            }
        }
    }

    func addItem() {
        let colorIdx = items.count % Self.colorPalette.count
        let gap = max(0.0, 100.0 - items.reduce(0) { $0 + $1.percentage })
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.append(AnalyticsDataItem(
                label: "Item \(items.count + 1)",
                percentage: gap,
                color: Self.colorPalette[colorIdx]
            ))
        }
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @State private var selectedFilter = "All"
    @Namespace private var filterNamespace

    let filters: [(label: String, count: Int)] = [
        ("All", 24), ("Pie Chart", 12), ("Half Donut", 6),
        ("Gantt Chart", 5), ("Histogram", 2)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let pieCategories = ["Pie Chart", "Gantt Chart"]
                if selectedFilter == "All" || pieCategories.contains(selectedFilter) {
                    AnalyticsCard(
                        title: "Simple Pie Chart",
                        categories: pieCategories,
                        items: [
                            AnalyticsDataItem(label: "Item 1", percentage: 32, color: AnalyticsCard.colorPalette[0]),
                            AnalyticsDataItem(label: "Item 2", percentage: 12, color: AnalyticsCard.colorPalette[1]),
                            AnalyticsDataItem(label: "Item 3", percentage: 56, color: AnalyticsCard.colorPalette[2]),
                        ]
                    )
                }
                let donutCategories = ["Half Donut", "Pie Chart"]
                if selectedFilter == "All" || donutCategories.contains(selectedFilter) {
                    HalfDonutCard(
                        title: "Half Donut Chart",
                        categories: donutCategories,
                        items: [
                            AnalyticsDataItem(label: "Design", percentage: 40, color: AnalyticsCard.colorPalette[0]),
                            AnalyticsDataItem(label: "Dev", percentage: 35, color: AnalyticsCard.colorPalette[1]),
                            AnalyticsDataItem(label: "Other", percentage: 25, color: AnalyticsCard.colorPalette[2]),
                        ]
                    )
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .top) {
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(filters, id: \.label) { filter in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedFilter = filter.label
                                }
                            } label: {
                                HStack(spacing: 7) {
                                    Text(filter.label)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.black)

                                    Text("\(filter.count)")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.blue, in: .capsule)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 9)
                                .background {
                                    if selectedFilter == filter.label {
                                        Capsule()
                                            .fill(Color.black.opacity(0.12))
                                            .matchedGeometryEffect(id: "filterSelection", in: filterNamespace)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.25), lineWidth: 1))
            .glassEffect(.clear, in: .capsule)
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
    }
}


#Preview {
    AnalyticsView()
}
