import SwiftUI

/// Searchable list of US states. Reused by onboarding and Settings.
struct StatePickerView: View {
    @Binding var selection: USState
    var onSelect: ((USState) -> Void)? = nil

    @State private var query = ""

    private var filtered: [USState] {
        guard !query.isEmpty else { return USState.all }
        return USState.all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.abbreviation.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List(filtered) { state in
            Button {
                selection = state
                onSelect?(state)
            } label: {
                HStack {
                    Text(state.name).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if state == selection {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Theme.brandPrimary)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .listRowBackground(Theme.surfaceElevated)
            .accessibilityAddTraits(state == selection ? [.isButton, .isSelected] : .isButton)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.surface)
        .searchable(text: $query, prompt: Strings.selectState)
    }
}
