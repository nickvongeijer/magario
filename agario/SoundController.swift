//
//  Recorder.swift
//  agario
//
//  Created by Yunhan Li on 10/12/15.
//
//

import AVFoundation

class SoundController : AVAudioRecorder, AVAudioRecorderDelegate {
    var soundRecorder : AVAudioRecorder!
    let fileName = "cache_recording.caf"

    override init() {
        super.init()
        setupRecorder()
    }
    
    // Set up the recorder
    func setupRecorder() {
        let recordSettings = [
            AVSampleRateKey : NSNumber(value: Float(32000.0) as Float), //32KHz
            AVFormatIDKey : NSNumber(value: Int32(kAudioFormatAppleLossless) as Int32),
            AVNumberOfChannelsKey: NSNumber(value: 1 as Int32),
            AVEncoderBitRateKey: 12800,
            AVLinearPCMBitDepthKey : 16,
            AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32)];
 
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try soundRecorder = AVAudioRecorder(url: self.getURL()!,
                settings: recordSettings)
            soundRecorder.delegate = self
            soundRecorder.prepareToRecord()
            soundRecorder.isMeteringEnabled = true
        } catch {
        }
    }
    
    func startRecording(){
        if !soundRecorder.isRecording {
            soundRecorder.record()
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                
            } catch {
            }
        }
    }
    
    func update() -> Float {
        soundRecorder.updateMeters()
        return soundRecorder.averagePower(forChannel: 0)
    }

    func getURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent(fileName)
        return soundURL
    }
    
    func stopRecording() {
        soundRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        soundRecorder.deleteRecording()
        print("recording cache removed")
    }

}
