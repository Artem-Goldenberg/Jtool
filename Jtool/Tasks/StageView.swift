import SwiftUI

struct TimeLine: View {
    let offset: CGFloat

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<40, id: \.self) { id in
                    ZStack() {
                        Circle()
                            .fill(Color.blue)
//                            .foregroundStyle(.blue)
                        Text("\(id)")
                            .foregroundStyle(.white)
//                            .background(in: .circle)
                    }
                    .padding(5)
                    .frame(width: 40, height: 40)
                }
            }
            .offset(x: -offset)
            .clipped()
            .frame(height: 70)
        } // scroll
//        .disabled(true)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .circular)
                .stroke(.gray, lineWidth: 3)
        )
        .padding(.horizontal, 25)
    }
}

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension View {
    func delayTouches() -> some View {
        Button(action: {}) {
            highPriorityGesture(TapGesture())
        }
        .buttonStyle(NoButtonStyle())
    }
}

struct StageCardList: View {
    @Binding var offset: CGFloat
    @State private var currentStage: Stage?
    @EnvironmentObject var store: Store

    private var stages: [Stage] {
        store.stages.sorted(using: KeyPathComparator(\.begin))
    }

    private let width = UIScreen.main.bounds.width
    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 20) {
                HStack {
                    Button {
                        if let currentStage {
                            move(to: stage(before: currentStage), proxy: proxy)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color(named: "chevronColor"))
                    .clipShape(.circle)
                    .tint(.accentColor)
                    .disabled(currentStage.map { $0.id == stages.first?.id } ?? false)

                    Spacer()

                    Button {
                        if let currentStage {
                            move(to: stage(after: currentStage), proxy: proxy)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color(named: "chevronColor"))
                    .clipShape(.circle)
                    .tint(.accentColor)
                    .disabled(currentStage.map { $0.id == stages.last?.id } ?? false)
                }
                .padding(.horizontal)
                scroll(proxy: proxy)
            }
        }
    }
    @ViewBuilder
    func scroll(proxy: ScrollViewProxy) -> some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(stages) { stage in
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(stage.borderColor, lineWidth: 2)
                            StageCard(stage: stage)
                        }
                        .padding(20)
                        .gesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onEnded { v in
                                    let dx = v.predictedEndLocation.x - v.startLocation.x
                                    if dx < 0 {
                                        move(to: self.stage(after: stage), proxy: proxy)
                                    } else if dx > 0 {
                                        move(to: self.stage(before: stage), proxy: proxy)
                                    }
                                }
                        )
//                        .delayTouches()
                        .frame(width: width)
                    } // foreach
                } // hstack
                .background(GeometryReader { geo in
                    Color.clear.preference(
                        key: ViewOffsetKey.self,
                        value: -geo.frame(in: .named("scroll")).origin.x
                    )
                })
                .onPreferenceChange(ViewOffsetKey.self) { value in
                    offset = value
                }
            } // scroll
            .scrollDisabled(true)
            .coordinateSpace(name: "scroll")
            .frame(height: 240)
//        }
    }

    private func move(to stage: Stage, proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(stage.id, anchor: .center)
        }
        currentStage = stage
    }

    private func stage(before stage: Stage) -> Stage {
        stages
            .firstIndex { $0.id == stage.id }
            .map {
                $0 == 0 ? stages[0] : stages[$0 - 1]
            }!
    }

    private func stage(after stage: Stage) -> Stage {
        stages
            .firstIndex { $0.id == stage.id }
            .map {
                $0 == stages.endIndex - 1 ? stages[$0] : stages[$0 + 1]
            }!
    }
}
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct StageView: View {
    @State private var scrollOffset: CGFloat = .zero
    @State private var creating = false
    @State private var newStage = EditableStage()
    @EnvironmentObject var store: Store

    private var width = UIScreen.main.bounds.size.width
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                TimeLine(offset: scrollOffset)
                    .padding(.top, 30)
                StageCardList(offset: $scrollOffset)
                Spacer()
            }
            .navigationTitle("Stage Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if store.canCreateNewStage {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Stage") {
                            creating = true
                        }
                    }
                }
            }
            .sheet(isPresented: $creating) {
                StageEditView(stage: $newStage)
            }
        } // navigation
    }
}

struct StageEditView: View {
    @Binding var stage: EditableStage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Starts At", selection: $stage.begin)
                }
                Section {
                    DatePicker("Ends At", selection: $stage.end)
                }
            }
            .navigationTitle("New Stage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        dismiss()
                        Worker {
                            await store.add(stage: stage)
                        }
                    }
                    .font(.headline)
                    .disabled(!stage.isValid)
                }
            }
        }
    }
}

struct StageCard: View {
    let stage: Stage
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text("Stage #\(stage.number):")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(stage.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(stage.titleColor)
                    .padding(.leading)
            }
            if !stage.tasks.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Text("completed: ")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    Text("\(stage.completedCount) / \(stage.tasks.count)")
                        .font(.headline)
                }
            }
            Spacer()
            HStack {
                if store.canFinish(stage: stage) {
                    Button("Finish") {
                        Worker {
                            await store.finish(stage: stage)
                        }
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .clipShape(.capsule)
                    .tint(.white)
                }
                Spacer()
                NavigationLink("Tasks") {
                    TaskListView(stage: stage)
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .clipShape(.capsule)
                .tint(.white)
            }
        } // vstack
        .padding()
    }

}

extension Stage {
    var borderColor: Color {
        if self.isCurrent {
            return .orange
        }
        if !self.isStarted {
            return .purple
        }
        return .green
    }
    var titleColor: Color {
        if self.isCurrent {
            return .orange
        }
        if !self.isStarted {
            return .purple
        }
        return .green
    }
    var title: String {
        if self.isCurrent {
            return "current"
        }
        if !self.isStarted {
            return "future"
        }
        return "done"
    }
}

//#Preview {
//    StageView()
//}

extension Color {
    init?(named: String) {
        if let color = UIColor(named: named) {
            self.init(color)
        }
        return nil
    }
}
