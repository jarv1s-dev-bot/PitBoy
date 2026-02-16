import SwiftUI

struct ContentView: View {
    @StateObject private var vm = PitBoyViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOU")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pitBoyMuted)

                        Text(vm.transcript.isEmpty ? "…" : vm.transcript)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.pitBoyPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Divider().overlay(Color.pitBoyMuted)

                        Text("JARVIS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pitBoyMuted)

                        Text(vm.responseText.isEmpty ? "Awaiting response…" : vm.responseText)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.pitBoyPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    Button(vm.isListening ? "WAIT" : "DICTATE") {
                        vm.toggleListening()
                    }
                    .buttonStyle(PitBoyButtonStyle(isActive: vm.isListening))

                    Button("SEND") {
                        Task { await vm.sendTranscript() }
                    }
                    .buttonStyle(PitBoyButtonStyle(isActive: false))
                    .disabled(vm.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
                }

                Text(vm.statusText)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.pitBoyMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)

            Scanlines()
                .allowsHitTesting(false)
        }
    }

    private var header: some View {
        HStack {
            Text("PIT•BOY COMMS")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.pitBoyPrimary)

            Spacer()

            Circle()
                .fill(vm.isListening ? Color.red : Color.pitBoyMuted)
                .frame(width: 8, height: 8)
        }
        .padding(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.pitBoyPrimary.opacity(0.8), lineWidth: 1)
        )
    }
}

private struct Scanlines: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineSpacing: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(Color.pitBoyPrimary.opacity(0.05)))
                    y += lineSpacing
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct PitBoyButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(isActive ? .black : .pitBoyPrimary)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isActive ? Color.pitBoyPrimary : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.pitBoyPrimary, lineWidth: 1)
            )
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private extension Color {
    static let pitBoyPrimary = Color(red: 0.56, green: 1.0, blue: 0.37)
    static let pitBoyMuted = Color(red: 0.35, green: 0.65, blue: 0.27)
}

#Preview {
    ContentView()
}
