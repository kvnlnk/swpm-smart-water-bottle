#include "WaterBottleDisplay.h"
#include <TFT_eSPI.h>

// Display Constants
const int SCREEN_COLOR = TFT_BLACK;
const int TEXT_COLOR = TFT_WHITE;
const unsigned long STATUS_DISPLAY_DURATION = 5000;

// TFT_eSPI Object for Display
TFT_eSPI tft = TFT_eSPI();

void initializeDisplay() {
  tft.init();
  tft.setRotation(0);
  
  // Initialize status display (device starts disconnected, so show status)
  shouldShowStatus = true;
  statusDisplayActive = true;
  showStatusDisplay();
}

void setReminderLEDs(int reminderType) {
  // Store current reminder type for display
  currentReminderType = reminderType;
  
  digitalWrite(ledNone, LOW);
  digitalWrite(ledNormal, LOW);
  digitalWrite(ledImportant, LOW);
  
  // Set LEDs based on the reminder type
  // 0 = None, 1 = Normal, 2 = Important, 3 = Off
  switch (reminderType) {
    case 0:
      digitalWrite(ledNone, HIGH);
      break;
    case 1:
      digitalWrite(ledNormal, HIGH);
      break;
    case 2:
      digitalWrite(ledImportant, HIGH);
      break;
    case 3:
      // LEDs are already turned off
      break;
    default:
      Serial.println("Unknown DrinkReminderType: " + String(reminderType));
      break;
  }
}

void showConnectionStatus(int centerX) {
  // BLE Status
  String bleText;
  if (isConnected) {
    tft.setTextColor(TFT_GREEN);
    bleText = "BT: Connected";
  } else {
    tft.setTextColor(TFT_RED);
    bleText = "BT: Waiting...";
  }
  
  // Center BLE status text using 12 pixels per character
  int bleWidth = bleText.length() * 12; 
  tft.setCursor(centerX - (bleWidth / 2), 120);
  tft.println(bleText);
  
  // Sync Status
  String syncText;
  if (timeSyncConfirmed) {
    tft.setTextColor(TFT_GREEN);
    syncText = "Sync: Confirmed";
  } else {
    tft.setTextColor(TFT_YELLOW);
    syncText = "Sync: Waiting...";
  }

  // Center Sync status text using 12 pixels per character
  int syncWidth = syncText.length() * 12;
  tft.setCursor(centerX - (syncWidth / 2), 140);
  tft.println(syncText);
}

void showStatusDisplay() {
  tft.fillScreen(SCREEN_COLOR);
  tft.setTextColor(TEXT_COLOR);
  
  int displayWidth = 240;
  int centerX = displayWidth / 2;
  
  // Center the title text
  tft.setTextSize(2);
  String title = "Smart Water Bottle";
  int titleWidth = title.length() * 12; 
  tft.setCursor(centerX - (titleWidth / 2), 90);
  tft.println(title);

  showConnectionStatus(centerX);  
}

void clearDisplay() {
  tft.fillScreen(SCREEN_COLOR);
  digitalWrite(ledNone, LOW);
  digitalWrite(ledNormal, LOW);
  digitalWrite(ledImportant, LOW);
  showReminderMessage = false;
}

void showWaterInfo() {
  tft.fillScreen(SCREEN_COLOR);
  tft.setTextColor(TEXT_COLOR);
  
  int displayWidth = 240;
  int centerX = displayWidth / 2;
  
  // Center the title text
  tft.setTextSize(2);
  String title = "Smart Water Bottle";
  int titleWidth = title.length() * 12; 
  tft.setCursor(centerX - (titleWidth / 2), 90);
  tft.println(title);
  
  // Water information
  tft.setTextSize(2);
  tft.setTextColor(TFT_WHITE);

  // Show current water amount and goal / calculate text width to center it
  char buf[32];
  snprintf(buf, sizeof(buf), "%.1f L / %.1f L", currentWater / 1000.0, waterGoal / 1000.0);
  String waterText = String(buf);
  int waterTextWidth = waterText.length() * 12; 
  tft.setCursor(centerX - (waterTextWidth / 2), 120);
  tft.println(waterText);
  
  const char* message = "";
  uint16_t reminderTextColor = TFT_WHITE;
  
  // Show text based on current reminder type
  switch (currentReminderType) {
    case 0: {
        message = "Alles Super!";
        reminderTextColor = TFT_GREEN;
        break;
      }
      case 1: {
        message = "Trink Etwas!";
        reminderTextColor = TFT_YELLOW;
        break;
      }
      case 2: {
        message = "Jetzt trinken!";
        reminderTextColor = TFT_RED;
        break;
      }
    case 3: {
      clearDisplay();
      break;
    }
  }

  // Show goal reached message if current water is greater than or equal to the goal
  if (currentWater >= waterGoal && currentReminderType != 3) {
    reminderTextColor = TFT_GREEN;
    message = "Ziel erreicht!";
  } 

  if (strlen(message) > 0) {
    tft.setTextColor(reminderTextColor);
    int reminderWidth = tft.textWidth(message); 
    int reminderY = 150;
    tft.setCursor(centerX - (reminderWidth / 2), reminderY);
    tft.println(message);
  }
}

void clearStatusDisplay() {
  statusDisplayActive = false;
  // Show water info instead of blank screen
  showWaterInfo();
}

void updateStatusDisplayLogic() {
  bool connectedAndSynced = isConnected && timeSyncConfirmed;
  bool disconnectedOrNotSynced = !isConnected || !timeSyncConfirmed;
  
  // Check if connection/sync state changed
  if (isConnected != lastConnectedState || timeSyncConfirmed != lastSynchedState) {
    if (connectedAndSynced) {
      // Connected and synced: show status for 5 seconds
      shouldShowStatus = true;
      statusDisplayStart = millis();
      statusDisplayActive = true;
      showStatusDisplay();
    } else if (disconnectedOrNotSynced) {
      // Not connected or not synced: show status continuously
      shouldShowStatus = true;
      statusDisplayActive = true;
      showStatusDisplay();
    }
    
    lastConnectedState = isConnected;
    lastSynchedState = timeSyncConfirmed;
  }
  
  // Handle timeout for connected & synced state
  if (connectedAndSynced && statusDisplayActive) {
    if (millis() - statusDisplayStart >= STATUS_DISPLAY_DURATION) {
      clearStatusDisplay(); 
    }
  }
  
  // Keep showing status if disconnected or not synced
  if (disconnectedOrNotSynced && !statusDisplayActive) {
    shouldShowStatus = true;
    statusDisplayActive = true;
    showStatusDisplay();
  }

  // If showing water info and connected+synced were shown, update water info when reminder changes
  static int lastReminderType = -1;
  if (connectedAndSynced && !statusDisplayActive && currentReminderType != lastReminderType) {
    showWaterInfo();
    lastReminderType = currentReminderType;
  }
}