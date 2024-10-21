import SwiftUI

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
    var title: LocalizedStringKey {
        if self.isCurrent {
            return "current"
        }
        if !self.isStarted {
            return "future"
        }
        return "done"
    }
}

extension Color {
    init(named: String) {
        self.init(UIColor(named: named)!)
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

extension View {
    func niceButton() -> some View {
        self
            .font(.headline)
            .padding()
            .background(Color.blue)
            .clipShape(.capsule)
            .tint(.white)
    }
}
