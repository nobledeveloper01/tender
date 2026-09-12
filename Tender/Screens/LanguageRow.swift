// Which language the denomination is said in. Each named in its own
// language, each 64 pt. Only languages whose clips are all recordings are
// offered — see `ClipPlayer.offered()` — so this list is English alone until
// the first language's twelve clips come back from a speaker.
import SwiftUI
import TenderDomain

struct LanguageRow: View {
    @Binding var selection: String
    @Environment(\.colorScheme) private var scheme

    private var current: Language { Language(rawValue: selection) ?? .en }

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationLink {
            List(ClipPlayer.offered(), id: \.self) { language in
                Button {
                    selection = language.rawValue
                } label: {
                    HStack {
                        Text(language.name).font(Type.bodyFont()).foregroundStyle(palette.textPrimary)
                        Spacer()
                        if language == current {
                            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(palette.ready)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(minHeight: Target.standard)
                }
                .accessibilityLabel(language.name)
                .accessibilityAddTraits(language == current ? .isSelected : [])
            }
            .navigationTitle(Strings.language)
        } label: {
            HStack {
                Text(Strings.language).font(Type.bodyFont())
                Spacer()
                Text(current.name).font(Type.bodyFont()).foregroundStyle(palette.textSecondary)
            }
            .frame(minHeight: Target.standard)
        }
        .accessibilityLabel("\(Strings.language), \(current.name)")
        .accessibilityHint(Strings.languageHint)
    }
}
