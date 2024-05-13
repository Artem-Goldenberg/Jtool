import SwiftUI

struct TimeLine: View {
    let offset: CGFloat

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<20, id: \.self) { id in
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
        } // scroll
//        .disabled(true)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.gray, lineWidth: 5)
                .clipShape(.capsule)
        )
        .padding(.horizontal, 25)
        .frame(height: 120)
    }
}

struct StageCardList: View {
    @Binding var offset: CGFloat
    @EnvironmentObject var store: Store

    private let width = UIScreen.main.bounds.width
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.stages) { stage in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.orange, lineWidth: 2)
                        StageCard(stage: stage)
                    }
                    .padding(20)
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
        .coordinateSpace(name: "scroll")
        .frame(height: 240)
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
    @EnvironmentObject var store: Store

    private var width = UIScreen.main.bounds.size.width
    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(alignment: .center, spacing: 20) {
//                    ForEach(store.stages) { stage in
//                        ZStack(alignment: .center) {
//                            RoundedRectangle(cornerRadius: 20)
//                                .stroke(.orange, lineWidth: 4)
//                            StageCard(stage: stage)
//                        }
//                        .frame(width: width - 20, height: 240)
//                        .id(stage.id)
//                        .onTapGesture {
//                            proxy.scrollTo(stage.id, anchor: .center)
//                        }
//                    } // foreach
//                } // hstack
//                .padding(.horizontal, 10)
//            } // scroll view
//        }
        NavigationStack {
            VStack(spacing: 60) {
                TimeLine(offset: scrollOffset)
                StageCardList(offset: $scrollOffset)
                Spacer()
            }
            .navigationTitle("Stage Info")
            .navigationBarTitleDisplayMode(.inline)
        } // navigation
    }
}

struct StageCard: View {
    let stage: Stage

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Stage #\(stage.number):")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(stageTitle)
                    .font(.headline)
                    .foregroundStyle(stageTitleColor)
                // TODO: align baselines
            }
            HStack {
                Text("completed: ")
                    .foregroundStyle(.gray)
                Text("\(stage.completedCount) / \(stage.tasks.count)")
                    .font(.headline)
            }
            Spacer()
            HStack {
                Spacer()
                NavigationLink("Tasks  ⃕ ") {
                    TaskListView()
                }
                .font(.title)
            }
        } // vstack
        .padding()
    }

    var stageTitleColor: Color {
        if stage.isCurrent {
            return .orange
        }
        if !stage.isStarted {
            return .purple
        }
        return .green
    }

    var stageTitle: String {
        if stage.isCurrent {
            return "current"
        }
        if !stage.isStarted {
            return "future"
        }
        return "done"
    }
}

//#Preview {
//    StageView()
//}
