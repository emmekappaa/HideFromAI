// This file contains the main views of the app: HomeView and ContentView

import SwiftUI
import Foundation
import Combine

// Shared language settings using UserDefaults
class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "selectedLanguage"
    
    var selectedLanguage: String {
        get {
            return UserDefaults.standard.string(forKey: languageKey) ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: languageKey)
        }
    }
}

struct HomeView: View {
    @State private var showGameModeSelection: Bool = false 

    var body: some View {
        VStack(spacing: 40) {
            Spacer() 

            
            Text("Hide From AI")
                .font(.largeTitle) 
                .fontWeight(.bold) 

            
            Button(action: {
                showGameModeSelection = true 
            }) {
                Text("Play") 
                    .font(.title2) 
                    .padding() 
                    .frame(maxWidth: .infinity) 
                    .background(Color.blue) 
                    .foregroundColor(.white) 
                    .cornerRadius(12) 
            }
            .padding(.horizontal) 

            
            Button(action: {
                print("Settings pressed") 
                // Navigate to ContentView with settings parameter
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: LanguageSettingsView())
                    window.makeKeyAndVisible()
                }
            }) {
                Text("Settings") 
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer() 
        }
        .padding() 
        .sheet(isPresented: $showGameModeSelection) {

            VStack(spacing: 20) {
                Text("Select Game Mode")
                    .font(.title)
                    .fontWeight(.bold)


                Button(action: {
                    print("HideFromAI mode selected")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: ContentView(aiCount: 3, language: LanguageManager.shared.selectedLanguage))
                        window.makeKeyAndVisible()
                    }
                }) {
                    Text("HideFromAI (3 AI, 1 Human)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Button(action: {
                    showGameModeSelection = false 
                }) {
                    Text("Back to Home")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct LanguageSettingsView: View {
    @State private var selectedLanguage: String = LanguageManager.shared.selectedLanguage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Language Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select AI Language")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                // English option
                Button(action: {
                    selectedLanguage = "en"
                    LanguageManager.shared.selectedLanguage = "en"
                }) {
                    HStack {
                        Text("🇺🇸")
                            .font(.title)
                        Text("English")
                            .font(.title2)
                        Spacer()
                        if selectedLanguage == "en" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedLanguage == "en" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
                
                // Italian option
                Button(action: {
                    selectedLanguage = "it"
                    LanguageManager.shared.selectedLanguage = "it"
                }) {
                    HStack {
                        Text("🇮🇹")
                            .font(.title)
                        Text("Italiano")
                            .font(.title2)
                        Spacer()
                        if selectedLanguage == "it" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedLanguage == "it" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Return to home
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: HomeView())
                    window.makeKeyAndVisible()
                }
            }) {
                Text("Back to Home")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct ContentView: View {
    @State private var volume: Double = 50 // State for volume control
    @State private var playerResponse: String = "" // State for player response
    @State private var aiResponses: [String] // Simulated AI responses
    @State private var topic: String = "" // State for current topic
    @State private var messages: [String] = [] // Messages in the chat
    @State private var currentTurn: Int = 0 // Current turn (participant index)
    @State private var currentRound: Int = 0 // Current round (0, 1, 2)
    @State private var votingPhase: Bool = false // State for voting phase
    @State private var aiResponseTimer: AnyCancellable? // Timer to manage random AI response delays
    @State private var activeAITasks: [URLSessionDataTask] = [] // Array to track active API calls
    @State private var showConnectionError: Bool = false // State to show connection error

    let topicsPool: [String] = ["Football", "Basketball", "Food", "American Food", "Instagram", "TikTok", "Movies", "Music", "Travel", "Technology", "Books", "Fitness", "Gaming", "Fashion", "Art", "Science", "History", "Politics", "Education", "Nature"]
    
    let personalityPool: [String] = [
        "curioso", "annoiato", "sarcastico", "entusiasta", 
        "pigro", "critico", "timido", 
        "energico", "pessimista", "cinico", "spontaneo"
    ]
    
    @State private var aiPersonalities: [String] = [] // Personalities assigned to AIs
    @State private var userVote: Int? = nil // User vote (AI index)
    @State private var aiVotes: [Int] = [] // AI votes (participant index)
    @State private var showResults: Bool = false // Show voting results
    
    let selectedLanguage: String // Language for AI prompts

    init(aiCount: Int, language: String = "en") {
        // Initialize AI responses based on the number of AIs
        _aiResponses = State(initialValue: Array(repeating: "", count: aiCount))
        self.selectedLanguage = language
    }

    var body: some View {
        VStack(spacing: 20) {
            // Top bar with home icon
            HStack {
                Spacer()

                // Home icon in top right
                Button(action: {
                    print("Back to Home pressed")
                    // Navigate to HomeView
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: HomeView())
                        window.makeKeyAndVisible()
                    }
                }) {
                    Image(systemName: "house.fill") // Home icon
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                        .padding()
                }
            }

            // Show current topic
            Text("Topic: \(topic)")
                .font(.headline)
                .padding()
            
            // Show current round
            Text("Phase \(currentRound + 1) of 2")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            // Lobby chat with automatic scrolling
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages.indices, id: \ .self) { index in
                            Text(messages[index])
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                                .id(index) // Assign ID for scrolling
                        }
                    }
                }
                .frame(maxHeight: 300)
                .padding()
                .onChange(of: messages) { oldValue, newValue in
                    // Automatically scroll to last message
                    if let lastIndex = newValue.indices.last {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }

            if !votingPhase {
                // Input field for player turn
                if currentTurn == aiResponses.count { // User's turn
                    TextField("Write your message...", text: $playerResponse)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: {
                        submitMessage(playerResponse)
                        playerResponse = ""
                    }) {
                        Text("Send")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else { // AI's turn
                    Text("AI \(currentTurn + 1) is typing...")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .onAppear {
                            //print("onAppear for AI \(currentTurn + 1), votingPhase: \(votingPhase)") // Debug
                            // Start AI response immediately, but only if not in voting phase
                            if !votingPhase {
                                //print("Starting generateAIMessage for AI \(currentTurn + 1)") // Debug
                                
                                // Save current turn to verify response arrives at right time
                                let expectedTurn = currentTurn
                                let aiPersonality = aiPersonalities.indices.contains(expectedTurn) ? aiPersonalities[expectedTurn] : "normale"
                                
                                let task = generateAIMessage(topic: topic, chatHistory: messages, personality: aiPersonality, language: selectedLanguage) { aiMessage in
                                    //print("Completed generateAIMessage for AI \(expectedTurn + 1) with message: '\(aiMessage)'") // Debug
                                    
                                    // Safety check: process response ONLY if it's still the correct turn
                                    if self.currentTurn == expectedTurn && !self.votingPhase {
                                        //print("AI response onAppear valid for turn \(expectedTurn + 1), processing...")
                                        submitMessage(aiMessage)
                                    } else {
                                        //print("AI response onAppear discarded - turn changed from \(expectedTurn) to \(self.currentTurn) or votingPhase=\(self.votingPhase)")
                                    }
                                }
                                activeAITasks.append(task)
                            } else {
                                //print("Skipped generateAIMessage because in votingPhase") // Debug
                            }
                        }
                }

                // "Call the Verdict" button - available only after first round
                if currentRound > 0 {
                    Button(action: {
                        votingPhase = true
                    }) {
                        Text("Call the Verdict")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            } else {
                // Fase di votazione
                if !showResults {
                    Text("Voting Phase: Who is the human?")
                        .font(.headline)
                        .padding()

                    // Voto dell'utente
                    ForEach(0..<aiResponses.count, id: \.self) { index in
                        Button(action: {
                            userVote = index
                            print("User voted for AI \(index + 1)")
                            startAIVoting()
                        }) {
                            HStack {
                                Text("AI \(index + 1)")
                                if userVote == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(userVote == index ? Color.blue : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(userVote != nil)
                        .padding(.horizontal)
                    }
                    
                    if userVote != nil {
                        Text("AI are voting...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    // Show results
                    VStack(spacing: 20) {
                        Text("Voting Results")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Show votes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🧑 You voted for: AI \(userVote! + 1)")
                            
                            ForEach(0..<aiVotes.count, id: \.self) { aiIndex in
                                let votedFor = aiVotes[aiIndex]
                                let votedForText = votedFor == aiResponses.count ? "You" : "AI \(votedFor + 1)"
                                Text("🤖 AI \(aiIndex + 1) voted for: \(votedForText)")
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        // Determine winner
                        Text(determineWinner())
                            .font(.headline)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        
                        Button(action: {
                            startNewRound()
                        }) {
                            Text("New Game")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer() // Spacing to push content upward
        }
        .padding() // General padding around content
        .onAppear {
            startNewRound()
        }
        .onDisappear {
            aiResponseTimer?.cancel()
            activeAITasks.forEach { $0.cancel() }
            activeAITasks.removeAll()
        }
        .alert("Connection Error", isPresented: $showConnectionError) {
            Button("OK") {
                // Return to home
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: HomeView())
                    window.makeKeyAndVisible()
                }
            }
        } message: {
            Text("Please try again")
        }
    }

    private func startNewRound() {
        topic = topicsPool.randomElement() ?? "Unknown"
        messages = []
        currentTurn = 0
        currentRound = 0
        votingPhase = false
        showResults = false
        userVote = nil
        aiVotes = []
        aiResponseTimer?.cancel()
        activeAITasks.forEach { $0.cancel() }
        activeAITasks.removeAll()
        
        // Assign random personalities to AIs
        aiPersonalities = []
        var availablePersonalities = personalityPool
        
        for _ in 0..<aiResponses.count {
            if let randomPersonality = availablePersonalities.randomElement() {
                aiPersonalities.append(randomPersonality)
                // Remove selected personality to avoid duplicates
                availablePersonalities.removeAll { $0 == randomPersonality }
            } else {
                // If we've run out of personalities, restart from complete pool
                availablePersonalities = personalityPool
                aiPersonalities.append(availablePersonalities.randomElement() ?? "normale")
            }
        }
        
        print("Personalities assigned to AIs:")
        for (index, personality) in aiPersonalities.enumerated() {
            print("AI \(index + 1): \(personality)")
        }
    }

    private func submitMessage(_ message: String) {
        /*
        print("=== SUBMIT MESSAGE CALLED ===")
        print("Message: '\(message)'")
        print("Current State: Turn=\(currentTurn), Round=\(currentRound), Voting=\(votingPhase)")
        print("aiResponses.count: \(aiResponses.count)")
        print("Who should speak? \(currentTurn < aiResponses.count ? "AI \(currentTurn + 1)" : "HUMAN")")
        print("=== END SUBMIT MESSAGE START ===")
        */
        // Cancel previous timer and all active API calls
        aiResponseTimer?.cancel()
        activeAITasks.forEach { $0.cancel() }
        activeAITasks.removeAll()
        
        // Safety check: avoid empty messages
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Empty message ignored")
            return
        }
        
        // Add message to chat
        if currentTurn == aiResponses.count {
            messages.append("Player 4: \(message)")
           // print("User message added")
        } else {
            messages.append("Player \(currentTurn + 1): \(message)")
            //print("AI message \(currentTurn + 1) added")
        }

        // Move to next turn
        let previousTurn = currentTurn
        currentTurn += 1
        print("Turn changed from \(previousTurn) to \(currentTurn)")
        
        // Check if we completed a round (all participants have spoken)
        if currentTurn > aiResponses.count {
            print("Round completed, moving to next round")
            // Check if we completed all 2 rounds BEFORE incrementing
            if currentRound >= 1 { // We completed round 1 (0,1)
                print("All rounds completed, activating voting")
                votingPhase = true
                return
            }
            
            currentRound += 1
            currentTurn = 0
            //print("New round: \(currentRound), turn reset to 0")
           // print("After reset - currentTurn: \(currentTurn), aiResponses.count: \(aiResponses.count)")
            //print("Should be AI turn? \(currentTurn < aiResponses.count)")
        }
        
        //print("Final state - Turn: \(currentTurn), Round: \(currentRound), Voting: \(votingPhase)")
        
        // IMPORTANT: Force next AI turn immediately ONLY if it's an AI's turn
        if !votingPhase && currentTurn < aiResponses.count {
            //print("AI TURN CHECK: votingPhase=\(votingPhase), currentTurn=\(currentTurn), aiResponses.count=\(aiResponses.count)")
            //print("Forcing next AI turn immediately for AI \(currentTurn + 1)")
            
            // Save current turn to verify response arrives at right time
            let expectedTurn = currentTurn
            let aiPersonality = aiPersonalities.indices.contains(expectedTurn) ? aiPersonalities[expectedTurn] : "normale"
            
            DispatchQueue.main.async {
                let task = generateAIMessage(topic: topic, chatHistory: messages, personality: aiPersonality, language: selectedLanguage) { aiMessage in
                    //print("Completed forced generateAIMessage for AI \(expectedTurn + 1) with message: '\(aiMessage)'")
                    
                    // Safety check: process response ONLY if it's still the correct turn
                    if self.currentTurn == expectedTurn && !self.votingPhase {
                        //print("AI response valid for turn \(expectedTurn + 1), processing...")
                        submitMessage(aiMessage)
                    } else {
                        //print("AI response discarded - turn changed from \(expectedTurn) to \(self.currentTurn) or votingPhase=\(self.votingPhase)")
                    }
                }
                self.activeAITasks.append(task)
            }
        } else if !votingPhase && currentTurn == aiResponses.count {
            //print("HUMAN TURN CHECK: votingPhase=\(votingPhase), currentTurn=\(currentTurn), aiResponses.count=\(aiResponses.count)")
            //print("Now it's human's turn - waiting for user input")
        } else {
            //print("SKIP CHECK: votingPhase=\(votingPhase), currentTurn=\(currentTurn), aiResponses.count=\(aiResponses.count)")
        }
    }
    
    private func startAIVoting() {
        aiVotes = []
        
        // Each AI votes in sequence
        for aiIndex in 0..<aiResponses.count {
            voteForHuman(chatHistory: messages, aiIndex: aiIndex) { vote in
                DispatchQueue.main.async {
                    self.aiVotes.append(vote)
                    print("AI \(aiIndex + 1) voted for participant \(vote)")
                    
                    // When all AIs have voted, show results
                    if self.aiVotes.count == self.aiResponses.count {
                        self.showResults = true
                    }
                }
            }
        }
    }
    
    private func determineWinner() -> String {
        // Count votes for user (index = aiResponses.count)
        let userVoteCount = aiVotes.filter { $0 == aiResponses.count }.count
        let totalAI = aiResponses.count
        let aiVotesAgainstUser = userVoteCount
        
        // Human wins if majority of AIs do NOT vote for them
        if aiVotesAgainstUser < (totalAI / 2) {
            return "🎉 Human wins! Only \(aiVotesAgainstUser) out of \(totalAI) AIs identified you as human. You blended in successfully!"
        } else {
            return "🤖 AI wins! \(aiVotesAgainstUser) out of \(totalAI) AIs correctly identified you as human."
        }
    }



// Function to generate an AI message using OpenRouter
func generateAIMessage(topic: String, chatHistory: [String], personality: String, language: String, completion: @escaping (String) -> Void) -> URLSessionDataTask {
    print("🚀 STARTING generateAIMessage - Topic: '\(topic)', Personality: '\(personality)', Language: '\(language)'")
    
    guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
        print("❌ Invalid URL")
        completion("Error: Invalid URL")
        return URLSession.shared.dataTask(with: URLRequest(url: URL(string: "about:blank")!)) // Dummy task
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(Config.groqAPIKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")


let systemPrompt: String
if language == "it" {
    systemPrompt = """
🧠 CONTESTO:
Stai partecipando ad una chat di gruppo tra amici che si conoscono da tempo e scrivono su una chat (stile WhatsApp). Il topic di oggi è: "\(topic)".

🎯 IL TUO OBIETTIVO:
Confonditi tra i partecipanti. Devi sembrare **una persona vera**, che scrive messaggi di getto. Non far pensare neanche per un secondo che sei un'AI.

🧑‍🤝‍🧑 TIPO DI CHAT:
- È un gruppo informale di amici universitari o colleghi
- Nessuno ragiona troppo sulle risposte, si scrive al volo

✍️ STILE DI SCRITTURA:
- Frasi brevi, spesso incomplete
- Errori, abbreviazioni ad esempio: "cmq", "nn", "boh", "ke", "raga", "lol", "cioè", "madò"....
- Poca punteggiatura, niente lettere maiuscole se non serve
- Non sempre serve il punto alla fine
- Ogni tanto solo 1 parola, o una sola emoji (non esagferare con le emoji, puoi anche non usarle, molto spesso non si usano nemmeno nella realta')

📌 COMPORTAMENTO NATURALE:
- Non sembrare mai brillante o "ben scritto"
- Potresti scrivere anche messaggi **inutili, banali o noiosi** (tipo "boh non so", "ez", "easy")
- Non devi per forza dire qualcosa di sensato o on topic
- Puoi cambiare discorso, o ignorare il messaggio precedente
- Puoi anche rispondere con una domanda ("ma quindi?", "chi l'ha detto?", "che è successo?")

🔁 PERSONALITÀ:
Ogni partecipante ha il suo stile. Il tuo è: **\(personality)**, attieniti a questo stile.

👀 ESEMPI PER TOPIC "Fitness": (NB SONO SOLO ESEMPI, NON ANCORARTI A QUESTI)
- "oggi 3 flessioni e già a terra madò"
- "cmq stasera pizza che ho dato tutto lol"
- "ma voi usate i guanti per i pesi??"
- "non so se vado più raga"
- "mi gira la testa ho fame"
- "boh palestra oggi no grazie"
- "💀💀💀"

🚫 COSE DA NON FARE:
- NON scrivere frasi ben costruite con soggetto-verbo-complemento (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON cercare sempre di essere simpatico o brillante (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON usare uno stile da chatbot 
- NON fare "il commentatore sportivo" o "l'esperto" (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON usare mai "Secondo me il [topic] è importante perché…" (questo direi proprio di evitarlo)
- NON spiegare troppo. Spesso la gente taglia corto. 

🎬 Rispondi **solo con il messaggio da mandare in chat, DEVE ESSERE UN MESSAGGIO**, nulla di più.
"""
} else {
    systemPrompt = """
🧠 CONTEXT:
You're participating in a group chat among long-time friends who message like on WhatsApp. Today's topic is: "\(topic)".

🎯 YOUR GOAL:
Blend in with the participants. You must sound like a real person, typing spontaneously. Don't let anyone think you're an AI.

🧑‍🤝‍🧑 TYPE OF CHAT:
It's an informal group of uni friends or coworkers
Nobody overthinks their messages, they just type quickly

✍️ WRITING STYLE:
Short sentences, often incomplete
Typos, abbreviations like: "idk", "lol", "nah", "u", "wtf", "fr", "bro", "omg", etc.
Minimal punctuation, lowercase letters unless needed
No need to always end with a period
Sometimes just 1 word or a single emoji (don't overuse emojis — many people barely use them)

📌 NATURAL BEHAVIOR:
Don't sound polished or "well written"
It's fine to write boring, pointless messages (like "idk tbh", "ez", "meh")
You don't always need to say something smart or on-topic
You can change the subject or ignore the previous message
You can reply with a question ("wait what?", "who said that?", "what happened?")

🔁 PERSONALITY:
Everyone has their own way of texting. Yours is: **\(personality)** — stick to that.

👀 EXAMPLES FOR TOPIC 'Fitness' (NOTE: these are just examples, don't copy them too closely)
"did 3 pushups and i'm done lol"
"pizza tonight i earned it 💀"
"do u guys use gloves for lifting??"
"idk if i'm going again tbh"
"dizzy af i need food"
"gym today? nah bro"
"💀💀💀"

🚫 AVOID THESE:
NO full, polished sentences with subject–verb–object every time (sometimes is fine, just not always)
NO always trying to be funny or clever (sometimes is fine, just not always)
NO chatbot-y or assistant tone
NO "sports commentator" or "fitness expert" vibes (sometimes is fine, just not always)
NEVER write like: "In my opinion, [topic] is important because…" (avoid this completely)
DON'T over-explain. People often cut it short.

🎬 Reply ONLY with the message to send in the group chat — it MUST BE a chat message, nothing else.
"""
}
    
    let recentHistory = chatHistory.suffix(6).joined(separator: "\n")
    let userContent = "Conversation so far:\n\(recentHistory)\n\nRespond now to the topic: \(topic)"

    let body: [String: Any] = [
        "model": "llama3-8b-8192",
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userContent]
        ],
        "max_completion_tokens": 1750, // Changed from max_tokens
        "temperature": 0.9,
        "top_p": 1, // Added as in example
        "stream": false, // Keep false for simplicity
        "stop": NSNull() // Added as in example
    ]

    // Request body validation
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        print("📦 Request body created successfully")
    } catch {
        print("❌ ERROR: Cannot serialize request body: \(error)")
        DispatchQueue.main.async {
            self.showConnectionError = true
        }
        return URLSession.shared.dataTask(with: URLRequest(url: URL(string: "about:blank")!))
    }
    
    request.timeoutInterval = 30.0 // Longer timeout

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                print("❌ NETWORK ERROR: \(error.localizedDescription)")
                //self.showConnectionError = true
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ ERROR: Response is not HTTPURLResponse")
                self.showConnectionError = true
                return
            }

            print("📊 STATUS CODE: \(httpResponse.statusCode)")
            
            // If there's an error, also print response body for debugging
            if httpResponse.statusCode != 200 {
                let errorBody = data.map { String(data: $0, encoding: .utf8) ?? "Cannot read body" } ?? "No data"
                print("❌ ERROR: Status code \(httpResponse.statusCode)")
                print("📄 Error body: \(errorBody)")
                print("📋 Headers: \(httpResponse.allHeaderFields)")
                self.showConnectionError = true
                return
            }

            guard let data = data else {
                print("❌ ERROR: No data received")
                self.showConnectionError = true
                return
            }

            do {
                // Debug: print complete JSON response
                if let rawJson = String(data: data, encoding: .utf8) {
                    print("📄 Complete JSON: \(rawJson)")
                }
                
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any] {
                    
                    // Debug: print all message keys
                    print("🔑 Message keys: \(message.keys)")
                    
                    // Try different fields to extract response
                    var aiContent = ""
                    
                    if let content = message["content"] as? String, !content.isEmpty {
                        print("✅ Content found: '\(content)'")
                        aiContent = content
                    } else if let reasoning = message["reasoning"] as? String, !reasoning.isEmpty {
                        print("🧠 Reasoning found (first 200 chars): '\(String(reasoning.prefix(200)))'")
                        // Extract only the final part of reasoning that looks like the response
                        let lines = reasoning.components(separatedBy: "\n")
                        if let lastLine = lines.last?.trimmingCharacters(in: .whitespacesAndNewlines), !lastLine.isEmpty {
                            aiContent = lastLine
                        } else {
                            aiContent = reasoning
                        }
                    } else {
                        print("❌ No content found in standard fields")
                        // Debug: print entire message
                        print("📋 Complete message: \(message)")
                    }
                    
                    print("🎯 AI response received: '\(aiContent)'") // Debug
                    let cleanContent = aiContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Remove quotes at beginning and end if present
                    var finalContent = cleanContent
                    if finalContent.hasPrefix("\"") && finalContent.hasSuffix("\"") && finalContent.count > 2 {
                        finalContent = String(finalContent.dropFirst().dropLast())
                    }
                    
                    // Remove AI prefix if present (e.g.: "🤖 AI 1:", "🤖 AI 2:", etc.)
                    if let aiPrefixRange = finalContent.range(of: "🤖 AI \\d+: ", options: .regularExpression) {
                        finalContent = String(finalContent[aiPrefixRange.upperBound...])
                    }
                    
                    print("✨ Clean content: '\(finalContent)'") // Debug
                    
                    if !finalContent.isEmpty {
                        completion(finalContent)
                    } else {
                        print("❌ ERROR: Final content is empty")
                        self.showConnectionError = true
                    }
                } else {
                    print("❌ ERROR: JSON parsing failed - invalid structure")
                    self.showConnectionError = true
                }
            } catch _ {
                print("❌ ERROR: Exception during JSON parsing")
                self.showConnectionError = true
            }
        }
    }

    task.resume()
    return task
}

    // Function to make AIs vote
    func voteForHuman(chatHistory: [String], aiIndex: Int, completion: @escaping (Int) -> Void) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            print("Invalid URL")
            completion(-1) // Invalid index
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are AI \(aiIndex + 1). You must vote for who you think is the real human among the participants.
        
        Participants:
        - Player 1 (index 0)
        - Player 2 (index 1)  
        - Player 3 (index 2)
        - Player 4 (index \(aiResponses.count))
        
        IMPORTANT: obviously you CANNOT vote for yourself (AI \(aiIndex + 1) = index \(aiIndex)).
        
        Quickly analyze writing style to find human characteristics:
        - Natural typing errors
        - Inconsistent style  
        - Spontaneous emotional reactions
        
        After analyzing, conclude with:
        "My answer is: [NUMBER]"
        
        Where [NUMBER] is between 0 and \(aiResponses.count), excluding \(aiIndex).
        """
        
        let userContent = chatHistory.joined(separator: "\n")

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "max_completion_tokens": 1800, // Changed from max_tokens
            "temperature": 0.7,
            "top_p": 1, // Added
            "stream": false,
            "stop": NSNull() // Added
        ]

        // Request body validation
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            print("📦 Vote request body created successfully")
        } catch {
            print("❌ ERROR: Cannot serialize vote request body: \(error)")
            completion(self.getRandomVoteForAI(aiIndex: aiIndex))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let httpResponse = response as? HTTPURLResponse {
                    let errorBody = data.map { String(data: $0, encoding: .utf8) ?? "Cannot read body" } ?? "No data"
                    print("❌ VOTE ERROR: Status code \(httpResponse.statusCode)")
                    print("📄 Vote error body: \(errorBody)")
                } else {
                    print("❌ ERROR: Response is not HTTPURLResponse")
                }
                completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                return
            }

            guard let data = data else {
                print("No data received")
                completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any] {
                    
                    var voteContent = ""
                    if let content = message["content"] as? String, !content.isEmpty {
                        voteContent = content
                        print("Using content field: '\(content)'")
                    } else if let reasoning = message["reasoning"] as? String, !reasoning.isEmpty {
                        print("Using reasoning field, looking for final answer...")
                        voteContent = reasoning
                        
                        // Look specifically for "My answer is: [NUMBER]"
                        let finalAnswerPattern = "My answer is:\\s*([0-9]+)"
                        let regex = try NSRegularExpression(pattern: finalAnswerPattern, options: [.caseInsensitive])
                        let range = NSRange(location: 0, length: reasoning.utf16.count)
                        
                        if let match = regex.firstMatch(in: reasoning, options: [], range: range) {
                            if match.numberOfRanges > 1, let numberRange = Range(match.range(at: 1), in: reasoning) {
                                let finalNumber = String(reasoning[numberRange])
                                print("Found final answer in reasoning: '\(finalNumber)'")
                                voteContent = finalNumber
                            }
                        } else {
                            print("Pattern 'My answer is:' not found in reasoning")
                        }
                    }
                    
                    // Look for a number in the response using regex
                    let numberPattern = "\\b[0-9]+\\b"
                    let regex = try NSRegularExpression(pattern: numberPattern)
                    let range = NSRange(location: 0, length: voteContent.utf16.count)
                    let matches = regex.matches(in: voteContent, options: [], range: range)
                    
                    var parsedVote: Int? = nil
                    
                    // Look for the first valid number in the response
                    for match in matches {
                        if let matchRange = Range(match.range, in: voteContent) {
                            let numberString = String(voteContent[matchRange])
                            if let number = Int(numberString) {
                                // Verify the number is in valid range
                                if number >= 0 && number <= self.aiResponses.count {
                                    parsedVote = number
                                    break
                                }
                            }
                        }
                    }
                    
                    if let vote = parsedVote {
                        print("AI \(aiIndex + 1) vote parsed: \(vote) from: '\(String(voteContent.prefix(100)))'")
                        // Verify AI doesn't vote for itself
                        if vote == aiIndex {
                            print("AI \(aiIndex + 1) tried to vote for itself, giving random vote")
                            completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                        } else {
                            completion(vote)
                        }
                    } else {
                        print("Cannot parse vote from: '\(String(voteContent.prefix(200)))', using random vote")
                        completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                    }
                } else {
                    print("Error parsing JSON response")
                    completion(self.getRandomVoteForAI(aiIndex: aiIndex))
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(self.getRandomVoteForAI(aiIndex: aiIndex))
            }
        }

        task.resume()
    }
    
    // Generate a random vote for AI, excluding itself
    private func getRandomVoteForAI(aiIndex: Int) -> Int {
        var availableVotes = Array(0...aiResponses.count)
        availableVotes.removeAll { $0 == aiIndex }
        return availableVotes.randomElement() ?? aiResponses.count
    }
}
