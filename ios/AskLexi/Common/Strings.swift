import Foundation

/// All user-visible copy, centralized for localization-readiness. Views must
/// reference these rather than inline literals.
///
/// UPL note: nothing here may claim legal *advice* or an attorney-client
/// relationship. Copy consistently says "legal information."
enum Strings {

    // MARK: Brand / global
    static let appName = "Lexi"
    static let uplFooter = "Lexi provides legal information, not legal advice."
    static let uplShort = "Legal information, not legal advice."

    // MARK: Common actions
    static let cont = "Continue"
    static let cancel = "Cancel"
    static let done = "Done"
    static let retry = "Try Again"
    static let save = "Save"
    static let copy = "Copy"
    static let copied = "Copied"
    static let share = "Share"
    static let close = "Close"
    static let notNow = "Not now"
    static let getStarted = "Get Started"

    // MARK: Onboarding
    static let onboard1Title = "Meet Lexi"
    static let onboard1Body = "Lexi is your AI legal strategist and educator. Ask about your rights, your options, and the deadlines that matter — explained in plain language."
    static let onboard2Title = "Information, not advice"
    static let onboard2Body = "Lexi explains the law and helps you understand documents and deadlines. Lexi is not a lawyer and does not provide legal advice or create an attorney-client relationship. For advice about your situation, you can connect with a licensed attorney from within the app."
    static let onboard2Acknowledge = "I understand Lexi provides legal information, not legal advice."
    static let onboard3Title = "Where are you?"
    static let onboard3Body = "Your state determines which rules and deadlines apply. You can change this later in Settings."
    static let selectState = "Select your state"

    // MARK: Auth
    static let signInTitle = "Sign in to Lexi"
    static let signInSubtitle = "Save your conversations and pick up where you left off."
    static let emailPlaceholder = "you@example.com"
    static let continueWithEmail = "Continue with Email"
    static let sendMagicLink = "Email me a sign-in link"
    static let magicLinkSentTitle = "Check your email"
    static func magicLinkSentBody(_ email: String) -> String {
        "We sent a secure sign-in link to \(email). Tap it on this device to continue."
    }
    static let signInWithApple = "Sign in with Apple"
    static let orDivider = "or"
    static let openMailApp = "Open Mail"
    static let invalidEmail = "Please enter a valid email address."

    // MARK: Home
    static func homeGreeting(_ name: String?) -> String {
        if let name, !name.isEmpty { return "Hi \(name)" }
        return "Hi there"
    }
    static let homePrompt = "What can Lexi help you understand today?"
    static let askLexi = "Ask Lexi"
    static let askAnything = "Ask Lexi anything…"
    static let featuredDepositTitle = "Get your security deposit back"
    static let featuredDepositSubtitle = "A guided walkthrough for tenants — rights, deadlines, and a ready-to-send demand letter."
    static let startDepositFlow = "Start"
    static let recentConversations = "Recent"
    static let quickTopics = "Quick topics"
    static let topicEviction = "Eviction"
    static let topicRepairs = "Repairs"
    static let topicLeaseReview = "Lease review"
    static let topicSmallClaims = "Small claims"
    static let emptyConversationsTitle = "No conversations yet"
    static let emptyConversationsBody = "Ask Lexi a question to get started."

    // MARK: Chat
    static let chatInputPlaceholder = "Message Lexi…"
    static let talkToLawyer = "Talk to a lawyer"
    static let lexiThinking = "Lexi is thinking…"
    static let followUps = "You might also ask"
    static let newConversation = "New conversation"
    static let chatSendError = "Lexi couldn't respond just now. Check your connection and try again."
    static let chatEmptyTitle = "Ask Lexi anything"
    static let chatEmptyBody = "Describe your situation in your own words. Lexi will explain your options."

    // MARK: Security deposit flow
    static let depositTitle = "Security Deposit"
    static let depositIntro = "Answer a few questions and Lexi will summarize your rights, calculate the key deadline, and draft a demand letter you can send."
    static let depositState = "State"
    static let depositMoveOut = "Move-out date"
    static let depositAmount = "Deposit amount"
    static let depositItemization = "Did you receive an itemized list of deductions?"
    static let depositItemizationYes = "Yes"
    static let depositItemizationNo = "No"
    static let depositDaysElapsedNote = "We'll calculate days elapsed from your move-out date."
    static let depositGenerate = "Generate my summary"
    static let depositRightsTitle = "Your rights"
    static let depositDeadlineTitle = "The deadline that matters"
    static let depositLetterTitle = "Demand letter draft"
    static let depositCopyLetter = "Copy letter"
    static let depositShareLetter = "Share letter"
    static let depositAmountPlaceholder = "$0"
    static let depositReviewWithLawyer = "Have a lawyer review this"

    // MARK: Attorney handoff / marketplace
    static let handoffTitle = "Talk to a lawyer"
    static let handoffIntro = "Tell us a bit about your issue. Licensed attorneys will respond with flat-fee quotes — you choose whether to hire anyone."
    static let handoffIssueLabel = "What do you need help with?"
    static let handoffIssuePlaceholder = "Briefly describe your situation…"
    static let handoffBudgetLabel = "Budget (optional)"
    static let handoffSubmit = "Request quotes"
    static let handoffConfirmTitle = "Request sent"
    static let handoffConfirmBody = "Licensed attorneys will review your request and respond with flat-fee quotes. We'll notify you when quotes arrive. Lexi and Lexitio are not law firms."
    static let handoffBackHome = "Back to Home"

    // MARK: Settings
    static let settingsTitle = "Settings"
    static let settingsAccount = "Account"
    static let settingsSubscription = "Subscription"
    static let settingsJurisdiction = "State / jurisdiction"
    static let settingsLegal = "Legal"
    static let legalTerms = "Terms of Service"
    static let legalPrivacy = "Privacy Policy"
    static let legalDisclaimer = "Legal disclaimer"
    static let settingsSignOut = "Sign out"
    static let settingsDeleteAccount = "Delete account"
    static let deleteConfirmTitle = "Delete your account?"
    static let deleteConfirmBody = "This permanently deletes your account, conversations, and drafts. This can't be undone."
    static let deleteConfirmAction = "Delete account"
    static let subscriptionFreeTitle = "Lexi Free"
    static let subscriptionFreeBody = "You're on the free plan."
    static let subscriptionManage = "Manage subscription"
    static let currentPlan = "Current plan"

    // MARK: Paywall
    static let paywallTitle = "Upgrade your Lexi"
    static let paywallSubtitle = "Go deeper with more questions, saved history, and document drafting."
    static let planPlus = "Lexi+"
    static let planPro = "Lexi Pro"
    static let paywallRestore = "Restore purchases"
    static let paywallComingSoon = "Memberships are coming soon. You have full access to Lexi Free today."
    static let paywallContinueFree = "Continue with Lexi Free"

    // MARK: Generic states
    static let loading = "Loading…"
    static let genericErrorTitle = "Something went wrong"
    static let genericErrorBody = "Please try again in a moment."
    static let offlineTitle = "You're offline"
    static let offlineBody = "Reconnect to the internet to continue."

    // MARK: Accessibility
    static func a11yJurisdiction(_ name: String) -> String { "Jurisdiction: \(name)" }
    static let a11yLexiMessage = "Lexi's message"
    static let a11yYourMessage = "Your message"
    static let a11ySendMessage = "Send message"
}
