import SwiftUI

struct TimeLine: View {
    let selectedStage: Stage?
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(dateRange.days) { day in
                        if day.isMonthStart {
                            Text(day.monthName)
                                .foregroundStyle(Color.gray)
                        }
                        ZStack {
                            if selectedRange.contains(day) {
                                Circle()
                                    .fill(color(for: day))
                            }
                            //                            .foregroundStyle(.blue)
                            Text("\(day.dayNum)")
                                .font(.subheadline)
                                .foregroundStyle(Color.init(named: "dayNum"))
                        }
                        .padding(5)
                        .frame(width: 40, height: 40)
////                        }
                    } // foreach
                } // hstack
                .padding(.horizontal, 5)
                .clipped()
                .frame(height: 70)
            } // scroll
//            .disabled(true)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.gray, lineWidth: 3)
            )
            .padding(.horizontal, 16)
//            .onAppear {
//                proxy.scrollTo(selectedRange.middle.startOfDay, anchor: .center)
//            }
            .onChange(of: selectedStage) {
                withAnimation {
                    proxy.scrollTo(selectedRange.middle.startOfDay, anchor: .center)
                }
            }
        } // reader
    }

    var dateRange: DateInterval {
        guard let start = store.stages.map(\.begin).min(),
              let end = store.stages.map(\.end).max()
        else { return .init() }
        return DateInterval(start: start, end: end)
    }

    var selectedRange: DateInterval {
        guard let stage = selectedStage else { return .init() }
        return DateInterval(start: stage.begin.startOfDay, end: stage.end.startOfDay)
    }

    private func color(for day: Date) -> Color {
        if day == selectedRange.start || day == selectedRange.end {
            return .init(named: "strongSelection").opacity(0.8)
        }
        return .init(named: "weakSelection").opacity(0.6)
    }
}

struct StageView: View {
    @State private var stageEdit = false
    @State private var editId: String?
    @State private var stageState = EditableStage()
    @State private var selectedStage: Stage?
    @EnvironmentObject var store: Store

//    var body: some View {
//        if store.stages.isEmpty {
//            ContentUnavailableView(
//                "Stages are empty or not loaded",
//                systemImage: "exclamationmark.octagon.fill"
//            )
//        } else {
//            content
//        }
//    }

    var body: some View {
        NavigationStack {
            Group {
                if store.stages.isEmpty {
                    ContentUnavailableView(
                        "Stages are empty or not loaded",
                        systemImage: "exclamationmark.octagon.fill"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 40) {
                            TimeLine(selectedStage: selectedStage)
                                .padding(.top, 30)
                            StageCardList(selectedStage: $selectedStage)
                            if let selectedStage {
                                StageStatisticView(stage: selectedStage)
                            }
                            Spacer()
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Stage Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if store.canCreateNewStage {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New Stage") {
                            stageState = .init()
                            editId = nil
                            stageEdit = true
                        }
                    }
                }
                if let selectedStage, store.canEdit(stage: selectedStage) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit") {
                            stageState = .init(stage: selectedStage)
                            editId = selectedStage.id
                            stageEdit = true
                        }
                    }
                }
            }
            .sheet(isPresented: $stageEdit) {
                StageEditView(stage: $stageState, existingId: $editId)
            }
            .onAppear { 
                if selectedStage == nil {
                    selectedStage = store.stage
                }
            }
            .onChange(of: store.stage) {
                self.selectedStage = store.stage
            }
        } // navigation
    }
}

struct StageEditView: View {
    @Binding var stage: EditableStage
    @Binding var existingId: String?
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
                    Button("Done") {
                        dismiss()
                        Worker {
                            if let existingId {
                                await store.edit(stage: stage, with: existingId)
                            } else {
                                await store.add(stage: stage)
                            }
                        }
                    }
                    .font(.headline)
                    .disabled(!stage.isValid)
                }
            } // toolbar
        } // navigation
    }
}
