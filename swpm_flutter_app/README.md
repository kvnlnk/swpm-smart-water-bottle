# Smart Water Bottle Flutter App for Android
Cross-platform mobile application for the Smart Water Bottle system, built with Flutter. Currently focused on Android development. This app allows users to track their water intake automatically, set daily goals, and receive reminders to stay hydrated by interacting with the Smart Water Bottle hardware via Bluetooth Low Energy (BLE).

## Features
- **User Authentication**: Secure login and registration using Supabase.
- **Water Intake Tracking**: Automatically logs water intake using the Smart Water Bottle's flow sensor.
- **Daily Goals**: Set and track daily water intake goals.
- **Daily Summaries**: View daily summaries of water intake.
- **Statistics**: Visualize water intake data with charts.
- **Bluetooth Communication**: Connect to the Smart Water Bottle hardware via BLE for real-time data synchronization.


## Installation and Usage
### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio) or any preferred IDE for Flutter
- [Supabase Account](https://supabase.com/) for backend services
### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/kvnlnk/swpm-smart-water-bottle.git
   cd swpm-smart-water-bottle/swpm_flutter_app
   ```

   ```bash
   flutter pub get
   ```

2. Update the `.env` file:
   - Create a `.env` file in the root of the project.
   - Add your Supabase URL and API key, your Service and characteristic UUIDs and your API URL:
    ```bash
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    API_BASE_URL=your_api_base_url
    SERVICE_UUID=your_service_uuid
    CHARACTERISTIC_UUID=your_characteristic_uuid
    ```

3. Ensure you have an Android device or emulator set up for testing.

   - If you are using an emulator, ensure it has Bluetooth capabilities enabled.
   - If you are using a physical device, enable USB debugging and connect it to your computer.

4. Run the app:
   ```bash
   flutter run
   ```