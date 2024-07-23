#### Easycap Stream

Easycap Stream App is a Flutter application designed to interact with an EasyCAP USB device to stream and manage video files. It provides functionalities such as video playback, screen recording, and screen capture.

## Working
- **Video Playback**: Displays a list of video files found on the connected USB device and plays them upon selection.
- **Screen Recording and  Capture**: Initiates and stops screen recording and Capture when connected to an EasyCAP device.

## Requirements

- Flutter SDK
- Android Studio / Xcode (for iOS)
- EasyCAP USB device (specifically identified by VID: 0x534d, PID: 0x0021)
- Android / iOS device for testing with USB OTG support

## Getting Started

1. **Clone Repository**:

   ```bash
   git clone https://github.com/rohanworld/Easycap-Streamer.git
   cd easycap-stream-app
   ```

3. **Connect Device**:

   Connect your Android / iOS device with USB OTG support to test USB connectivity.

4. **Run Application**:

   ```bash
   flutter run
   ```

5. **Interact with the App**:

   - Connect your EasyCAP USB device via OTG
   - Explore video files and Use screen recording and screen capture functionalities as needed.
