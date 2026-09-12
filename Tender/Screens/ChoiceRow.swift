// A setting with three choices, as a row that pushes a list of them. Not a
// Picker: a menu picker's label, and a navigation-link picker's value text,
// each only partly follow Dynamic Type — the audit found both — and this
// row is nothing but text the app sets the style of.
import SwiftUI

struct Choice: Identifiable, Hashable {
    let label: String
    let value: Double
    var id: Double { value }
}

struct ChoiceRow: View {
    let title: String
    let choices: [Choice]
    @Binding var selection: Double
    @Environment(\.colorScheme) private var scheme

    private var current: String { choices.first { $0.value == selection }?.label ?? "" }

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationLink {
            List(choices) { choice in
                Button {
                    selection = choice.value
                } label: {
                    HStack {
                        Text(choice.label).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        Spacer()
                        if choice.value == selection {
                            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(palette.ready)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(minHeight: Target.standard)
                }
                .accessibilityLabel(choice.label)
                .accessibilityAddTraits(choice.value == selection ? .isSelected : [])
            }
            .navigationTitle(title)
        } label: {
            HStack {
                Text(title).font(Type.bodyFont())
                Spacer()
                Text(current).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
            }
            .frame(minHeight: Target.standard)
        }
        .accessibilityLabel("\(title), \(current)")
    }
}
