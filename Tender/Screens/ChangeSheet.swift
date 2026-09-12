// Paid and cost, two numbers, then the camera does the rest. Number pads,
// labelled, 64 pt rows; VoiceOver users type numbers in a numeric field as
// readily as anyone.
import SwiftUI

struct ChangeSheet: View {
    let reader: Reader
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var paid = ""
    @State private var cost = ""

    private var valid: Bool { Int(paid) != nil && Int(cost) != nil }

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            List {
                LabeledContent(Strings.paid) {
                    TextField("0", text: $paid).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .accessibilityLabel(Strings.paid).accessibilityIdentifier("paid")
                }
                .frame(minHeight: Target.standard)
                LabeledContent(Strings.cost) {
                    TextField("0", text: $cost).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .accessibilityLabel(Strings.cost).accessibilityIdentifier("cost")
                }
                .frame(minHeight: Target.standard)
                Button(Strings.start) {
                    reader.startChange(paid: Int(paid) ?? 0, cost: Int(cost) ?? 0)
                    dismiss()
                }
                .disabled(!valid)
                .frame(maxWidth: .infinity, minHeight: Target.standard)
                .fontWeight(.semibold)
            }
            .font(Type.bodyFont())
            .tint(palette.ready)
            .navigationTitle(Strings.checkChange)
        }
    }
}
