#ifndef WATERBOTTLEDISPLAY_H
#define WATERBOTTLEDISPLAY_H

#include <Arduino.h>

// Function declarations for display methods
void initializeDisplay();
void showConnectionStatus(int centerX);
void showStatusDisplay();
void clearDisplay();
void showWaterInfo();
void clearStatusDisplay();
void updateStatusDisplayLogic();
void setReminderLEDs(int reminderType);

// External variable declarations
extern bool isConnected;
extern bool timeSyncConfirmed;
extern int currentWater;
extern int waterGoal;
extern int currentReminderType;
extern bool lastConnectedState;
extern bool lastSynchedState;
extern unsigned long statusDisplayStart;
extern bool statusDisplayActive;
extern bool shouldShowStatus;
extern bool showReminderMessage;
extern const byte ledNone;
extern const byte ledNormal;
extern const byte ledImportant;

#endif 