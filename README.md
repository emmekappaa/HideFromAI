# Hide From AI Game

A SwiftUI game where you must hide among AIs in a group chat.

## Setup

### 1. Configure Your API Keys

Before running the app, you need to set up your API keys:

1. Copy the configuration template:

   ```bash
   cp Config.swift.template Config.swift
   ```

2. Open `Config.swift` and insert your Groq API key:

   ```swift
   struct Config {
       static let groqAPIKey = "your_api_key_here"
   }
   ```

3. You can get your API key from [Groq Console](https://console.groq.com/)

### 2. Run the App

Open the project in Xcode and run the app.

## How to Play

1. Choose the language for the AIs (Italian or English)
2. Join the group chat
3. Try to sound human while chatting with the AIs
4. At the end, vote who you think is the human
5. You win if the AIs can't detect you're human!
