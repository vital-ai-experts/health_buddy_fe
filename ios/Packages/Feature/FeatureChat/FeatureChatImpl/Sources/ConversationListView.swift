import SwiftUI
import DomainChat
import LibraryServiceLoader

struct ConversationListView: View {
    @StateObject private var viewModel: ConversationListViewModel

    init() {
        let chatService = ServiceManager.shared.resolve(ChatService.self)
        _viewModel = StateObject(wrappedValue: ConversationListViewModel(chatService: chatService))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView("Loading conversations...")
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No conversations yet")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("Start a new conversation to begin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        NavigationLink(destination: ChatView()) {
                            Label("New Chat", systemImage: "plus.message")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(destination: ChatView(conversationId: conversation.id)) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                    .refreshable {
                        await viewModel.loadConversations()
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ChatView()) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.loadConversations()
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = viewModel.conversations[index]
            Task {
                await viewModel.deleteConversation(id: conversation.id)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title ?? "New Conversation")
                .font(.headline)

            HStack {
                Text(formatDate(conversation.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple formatting - just extract date and time
        // Format: "2024-11-05T14:30:00"
        let components = dateString.split(separator: "T")
        if components.count >= 2 {
            let date = String(components[0])
            let time = String(components[1].prefix(5)) // Get HH:mm
            return "\(date) \(time)"
        }
        return dateString
    }
}

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            conversations = try await chatService.getConversations(limit: 50, offset: nil)
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteConversation(id: String) async {
        do {
            try await chatService.deleteConversation(id: id)
            conversations.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
}
