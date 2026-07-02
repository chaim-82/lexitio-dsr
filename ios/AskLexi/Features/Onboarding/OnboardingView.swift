import SwiftUI

/// Three-screen onboarding: what Lexi is → information-vs-advice acknowledgment
/// → state selection. The disclaimer must be explicitly acknowledged before the
/// user can continue (recorded with a timestamp by `AppState.completeOnboarding`).
struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var step = 0
    @State private var acknowledged = false
    @State private var selectedState: USState = .newYork

    private let lastStep = 2

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $step) {
                introPage.tag(0)
                disclaimerPage.tag(1)
                statePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            footer
        }
        .background(BrandBackground())
    }

    // MARK: Pages

    private var introPage: some View {
        OnboardingPage(
            icon: "sparkles",
            title: Strings.onboard1Title,
            message: Strings.onboard1Body)
    }

    private var disclaimerPage: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingPage(
                icon: "checkmark.seal",
                title: Strings.onboard2Title,
                message: Strings.onboard2Body)
            // A button-styled checkbox rather than a Toggle: explicit tap target,
            // reliable under VoiceOver and UI testing (SwiftUI Toggles are not
            // consistently hittable via XCUITest).
            Button {
                acknowledged.toggle()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                    Image(systemName: acknowledged ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(acknowledged ? Theme.brandPrimary : Theme.textSecondary)
                    Text(Strings.onboard2Acknowledge)
                        .font(Typography.body)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .padding(.horizontal, Theme.Spacing.lg)
            .accessibilityIdentifier("acknowledgeDisclaimer")
            .accessibilityAddTraits(acknowledged ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint("Required to continue")
        }
    }

    private var statePage: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.sm) {
                Text(Strings.onboard3Title).font(Typography.title())
                    .foregroundStyle(Theme.textPrimary)
                Text(Strings.onboard3Body)
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)

            StatePickerView(selection: $selectedState)
        }
    }

    // MARK: Chrome

    private var header: some View {
        Wordmark(size: .small)
            .padding(.top, Theme.Spacing.md)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.sm) {
            PrimaryButton(
                title: step == lastStep ? Strings.getStarted : Strings.cont,
                isEnabled: canContinue
            ) {
                advance()
            }
            DisclaimerFooter()
        }
        .padding(Theme.Spacing.lg)
    }

    private var canContinue: Bool {
        switch step {
        case 1: return acknowledged
        default: return true
        }
    }

    private func advance() {
        if step < lastStep {
            withAnimation { step += 1 }
        } else {
            appState.completeOnboarding(state: selectedState)
        }
    }
}

/// A single centered onboarding page (icon + serif title + body).
private struct OnboardingPage: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: 0)
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Theme.brandAccent)
                .accessibilityHidden(true)
            Text(title)
                .font(Typography.display(30))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView()
        .environment(PreviewSupport.appState)
}
