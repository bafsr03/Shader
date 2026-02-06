import SwiftUI
import AVFoundation

@Observable
class AudioManager {
    private var audioPlayer: AVAudioPlayer?
    var isPlaying = false
    var selectedSong: String = ""
    
    func playSong(_ songName: String) {
        selectedSong = songName
        
        // Stop current playback if any
        audioPlayer?.stop()
        
        // Try to load the audio file
        guard let url = Bundle.main.url(forResource: songName, withExtension: "mp3") else {
            print("Could not find \(songName).mp3 - will play when you add the file")
            return
        }
        
        do {
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and configure player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }
}
