import SwiftUI

fileprivate extension Button {
    var arrowStyle: some View {
        self
            .font(.headline)
            .padding()
            .background(Color(named: "chevron"))
            .clipShape(.circle)
            .tint(.accentColor)
    }
}

struct StageCardList: View {
    @Binding var selectedStage: Stage?
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 20) {
                HStack {
                    Button { back(proxy: proxy) } label: {
                        Image(systemName: "chevron.left")
                    }
                    .arrowStyle
                    .disabled(selectedStage?.id == store.stages.first?.id)
                    Spacer()
                    Button { forward(proxy: proxy) } label: {
                        Image(systemName: "chevron.right")
                    }
                    .arrowStyle
                    .disabled(selectedStage?.id == store.stages.last?.id)
                }
                .padding(.horizontal)

                StageCardScroll(
                    back: { back(proxy: proxy) },
                    forward: { forward(proxy: proxy) }
                )
                .onChange(of: selectedStage) {
                    guard let selectedStage else { return }
                    withAnimation {
                        proxy.scrollTo(selectedStage.id, anchor: .center)
                    }
                }
            }
        }
    }

    private func back(proxy: ScrollViewProxy) {
        if let selectedStage {
            self.selectedStage = stage(before: selectedStage)
        }
    }
    private func forward(proxy: ScrollViewProxy) {
        if let selectedStage {
            self.selectedStage = stage(after: selectedStage)
        }
    }

    private func stage(before stage: Stage) -> Stage {
        guard let i = store.stages.firstIndex(with: stage.id), i != store.stages.firstIndex
        else { return stage }
        return store.stages[i - 1]
    }
    private func stage(after stage: Stage) -> Stage {
        guard let i = store.stages.firstIndex(with: stage.id), i != store.stages.lastIndex
        else { return stage }
        return store.stages[i + 1]
    }
}
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct StageCardScroll: View {
    let back: () -> Void
    let forward: () -> Void
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.stages) { stage in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(stage.borderColor, lineWidth: 2)
                        StageCard(stage: stage)
                    }
                    .padding(20)
                    .gesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .local)
                            .onEnded(move)
                    )
                    .frame(width: UIScreen.main.bounds.width)
                } // foreach
            } // hstack
//            .background(GeometryReader { geo in
//                Color.clear.preference(
//                    key: ViewOffsetKey.self,
//                    value: -geo.frame(in: .named("scroll")).origin.x
//                )
//            })
//            .onPreferenceChange(ViewOffsetKey.self) { value in
//                offset = value
//            }
        } // scroll
        .scrollDisabled(true)
        .coordinateSpace(name: "scroll")
        .frame(height: 240)
    }

    private func move(drag: DragGesture.Value) {
        let dx = drag.predictedEndLocation.x - drag.startLocation.x
        if dx < 0 { forward() }
        else if dx > 0 { back() }
    }
}
