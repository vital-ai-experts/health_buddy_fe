import SwiftUI
import ThemeKit

/// Reusable AI Insight Card component with edit functionality
struct AboutMeCardView<Content: View>: View {
    let title: String
    let subtitle: String
    let onEdit: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header with title and edit button
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.Palette.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.Palette.textSecondary)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.Palette.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            // Card content
            content()
        }
        .padding(24)
        .background(Color.Palette.surfaceElevated)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .shadow(color: Color.Palette.textPrimary.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ScrollView {
        AboutMeCardView(
            title: "目标",
            subtitle: "The Core Drivers",
            onEdit: { print("Edit tapped") }
        ) {
            Text("Sample content")
        }
        .padding()
    }
    .background(Color.Palette.bgBase)
}
