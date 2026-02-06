import SwiftUI

struct DedicationApp: View {
    @State private var selectedSong: String? = nil
    @State private var audioManager = AudioManager()
    
    var body: some View {
        ZStack {
            if selectedSong == nil {
                // Song selection screen
                SongSelectionView(selectedSong: $selectedSong)
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Dedication slides with ripple reveal
                ContentView(audioManager: audioManager, onBackToSongSelection: {
                    withAnimation {
                        selectedSong = nil
                        audioManager.stop()
                    }
                })
                    .transition(.opacity)
                    .onAppear {
                        // Start playing the selected song
                        if let song = selectedSong {
                            audioManager.playSong(song)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: selectedSong)
    }
}

#Preview {
    DedicationApp()
}
