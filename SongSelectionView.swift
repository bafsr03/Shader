import SwiftUI

struct SongSelectionView: View {
    @Binding var selectedSong: String?
    
    // Ocean cake inspired colors
    let creamBeige = Color(red: 0.96, green: 0.94, blue: 0.90)
    let softBlue = Color(red: 0.53, green: 0.71, blue: 0.82)
    let deepBlue = Color(red: 0.36, green: 0.54, blue: 0.66)
    
    let songs = [
        Song(id: "song1", title: "Turning Page"),
        Song(id: "song2", title: "Can't take my eyes off you"),
        Song(id: "song3", title: "La mujer perfecta")
    ]
    
    var body: some View {
        ZStack {
            // Minimalistic beige background
            creamBeige
                .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // Simple elegant title
                VStack(spacing: 8) {
                    Text("Elige una de estas canciones para acompañar esta dedicatoria.")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(deepBlue)
                        .tracking(2)
                }
                
                // Minimalistic song buttons
                VStack(spacing: 16) {
                    ForEach(songs) { song in
                        MinimalisticSongButton(song: song, colors: (softBlue, deepBlue)) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                selectedSong = song.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 60)
                
                Spacer()
                Spacer()
            }
        }
    }
}

struct Song: Identifiable {
    let id: String
    let title: String
}

struct MinimalisticSongButton: View {
    let song: Song
    let colors: (Color, Color)
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(song.title)
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                
                Spacer()
                
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [colors.0, colors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: colors.1.opacity(0.3), radius: 8, y: 4)
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    SongSelectionView(selectedSong: .constant(nil))
}
