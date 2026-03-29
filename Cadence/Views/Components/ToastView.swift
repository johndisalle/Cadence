import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    var undoAction: (() -> Void)?
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CadenceTheme.sage)

                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CadenceTheme.textPrimary)

                if let undoAction {
                    Divider()
                        .frame(height: 18)

                    Button("Undo") {
                        undoAction()
                        withAnimation(.spring(response: 0.3)) {
                            isShowing = false
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CadenceTheme.coral)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.3)) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Toast ViewModifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    var undoAction: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ToastView(
                    message: message,
                    icon: icon,
                    undoAction: undoAction,
                    isShowing: $isShowing
                )
                .padding(.bottom, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isShowing)
            }
    }
}

extension View {
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        icon: String = "checkmark.circle.fill",
        undoAction: (() -> Void)? = nil
    ) -> some View {
        modifier(ToastModifier(
            isShowing: isShowing,
            message: message,
            icon: icon,
            undoAction: undoAction
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack {
                    Button("Show Toast") { show = true }
                        .buttonStyle(.borderedProminent)
                }
            }
            .toast(isShowing: $show, message: "Logged!", icon: "checkmark.circle.fill") {
                print("Undo tapped")
            }
        }
    }
    return PreviewWrapper()
}
