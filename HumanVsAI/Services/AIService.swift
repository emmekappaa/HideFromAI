//
//  AIService.swift
//  HumanVsAI
//
//  Service to handle all AI-related API calls
//

import Foundation

class AIService {
    static let shared = AIService()
    
    private var activeTasks: [URLSessionDataTask] = []
    
    private init() {}
    
    // MARK: - Public Methods
    
    func generateAIMessage(
        topic: String,
        chatHistory: [Message],
        personality: String,
        language: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) -> URLSessionDataTask {
        print("🚀 Generating AI message - Topic: '\(topic)', Personality: '\(personality)', Language: '\(language)'")
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            let dummyTask = createDummyTask()
            completion(.failure(AIServiceError.invalidURL))
            return dummyTask
        }
        
        let request = createRequest(
            url: url,
            systemPrompt: createChatSystemPrompt(topic: topic, personality: personality, language: language),
            userContent: createChatUserContent(chatHistory: chatHistory, topic: topic)
        )
        
        let task = executeRequest(request) { result in
            completion(result.map { self.cleanAIResponse($0) })
        }
        
        activeTasks.append(task)
        return task
    }
    
    func voteForHuman(
        chatHistory: [Message],
        aiIndex: Int,
        totalPlayers: Int,
        completion: @escaping (Int) -> Void
    ) {
        print("🗳 AI \(aiIndex + 1) voting...")
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            completion(getRandomVote(excluding: aiIndex, totalPlayers: totalPlayers))
            return
        }
        
        let request = createRequest(
            url: url,
            systemPrompt: createVotingSystemPrompt(aiIndex: aiIndex),
            userContent: chatHistory.map { $0.displayText }.joined(separator: "\n")
        )
        
        let task = executeRequest(request) { result in
            switch result {
            case .success(let voteContent):
                let vote = self.parseVote(from: voteContent, excluding: aiIndex, totalPlayers: totalPlayers)
                completion(vote)
            case .failure:
                completion(self.getRandomVote(excluding: aiIndex, totalPlayers: totalPlayers))
            }
        }
        
        task.resume()
    }
    
    func cancelAllTasks() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func createRequest(url: URL, systemPrompt: String, userContent: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "max_completion_tokens": 1750,
            "temperature": 0.9,
            "top_p": 1,
            "stream": false,
            "stop": NSNull()
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func executeRequest(_ request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AIServiceError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ Status code: \(httpResponse.statusCode)")
                    completion(.failure(AIServiceError.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AIServiceError.noData))
                    return
                }
                
                do {
                    let content = try self.extractContent(from: data)
                    completion(.success(content))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
        return task
    }
    
    private func extractContent(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            throw AIServiceError.invalidJSON
        }
        
        if let content = message["content"] as? String, !content.isEmpty {
            return content
        } else if let reasoning = message["reasoning"] as? String, !reasoning.isEmpty {
            let lines = reasoning.components(separatedBy: "\n")
            return lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? reasoning
        }
        
        throw AIServiceError.emptyContent
    }
    
    private func cleanAIResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove quotes
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") && cleaned.count > 2 {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        
        // Remove AI prefix
        if let aiPrefixRange = cleaned.range(of: "🤖 AI \\d+: ", options: .regularExpression) {
            cleaned = String(cleaned[aiPrefixRange.upperBound...])
        }
        
        return cleaned
    }
    
    private func parseVote(from text: String, excluding aiIndex: Int, totalPlayers: Int) -> Int {
        let allowedChars = Set("abcdefghijklmnopqrstuvwxyz0123456789: .")
        let cleanedContent = text
            .lowercased()
            .filter { allowedChars.contains($0) }
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        let patterns: [(String, Int)] = [
            (#"my\s*answer\s*is\s*:?[\s]*([0-9]+)[\s\.]*(?:$|[^0-9])"#, 1),
            (#"i\s*vote\s*(for|on)?\s*:?[\s]*(player\s*)?([0-9]+)[\s\.]*(?:$|[^0-9])"#, 3),
            (#"my\s*vote\s*is\s*:?[\s]*([0-9]+)[\s\.]*(?:$|[^0-9])"#, 1),
            (#"i\s*choose\s*:?[\s]*(player\s*)?([0-9]+)[\s\.]*(?:$|[^0-9])"#, 2),
            (#"human\s*is\s*(player\s*)?([0-9]+)[\s\.]*(?:$|[^0-9])"#, 2),
            (#"([0-9]+)[\s\.]*(?:$|[^0-9])"#, 1)
        ]
        
        for (pattern, group) in patterns {
            if let vote = findVote(in: cleanedContent, pattern: pattern, group: group, totalPlayers: totalPlayers) {
                return vote
            }
        }
        
        return getRandomVote(excluding: aiIndex, totalPlayers: totalPlayers)
    }
    
    private func findVote(in text: String, pattern: String, group: Int, totalPlayers: Int) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
              let numberRange = Range(match.range(at: group), in: text),
              let rawVote = Int(text[numberRange]) else {
            return nil
        }
        
        let vote = (1...totalPlayers).contains(rawVote) ? rawVote - 1 : rawVote
        return max(0, min(vote, totalPlayers - 1))
    }
    
    private func getRandomVote(excluding aiIndex: Int, totalPlayers: Int) -> Int {
        var availableVotes = Array(0..<totalPlayers)
        availableVotes.removeAll { $0 == aiIndex }
        return availableVotes.randomElement() ?? 0
    }
    
    private func createDummyTask() -> URLSessionDataTask {
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "about:blank")!))
    }
    
    // MARK: - Prompts
    
    private func createChatSystemPrompt(topic: String, personality: String, language: String) -> String {
        if language == "it" {
            return """
🧠 CONTESTO:
Stai partecipando ad una chat di gruppo tra amici che si conoscono da tempo e scrivono su una chat (stile WhatsApp). Il topic di oggi è: "\(topic)".

🎯 IL TUO OBIETTIVO:
Confonditi tra i partecipanti. Devi sembrare **una persona vera**, che scrive messaggi di getto. Non far pensare neanche per un secondo che sei un'AI.

🧑‍🤝‍🧑 TIPO DI CHAT:
- È un gruppo informale di amici universitari o colleghi
- Nessuno ragiona troppo sulle risposte, si scrive al volo

✍️ STILE DI SCRITTURA:
- Frasi brevi, spesso incomplete
- Errori, abbreviazioni ad esempio: "cmq", "nn", "boh", "raga", "lol", "cioè", "madò".... (non insistere nel loro utilizzo)
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

🚫 COSE DA NON FARE:
- NON scrivere frasi ben costruite con soggetto-verbo-complemento (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON cercare sempre di essere simpatico o brillante (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON usare uno stile da chatbot 
- NON fare "il commentatore sportivo" o "l'esperto" (a volte puoi farlo, molti amici lo fanno, ma non sempre)
- NON usare mai "Secondo me il [topic] è importante perché…" (questo direi proprio di evitarlo)
- NON spiegare troppo. Spesso la gente taglia corto. 

🎬 Rispondi **solo con il messaggio da mandare in chat, DEVE ESSERE UN MESSAGGIO**, nulla di più. (ma deve comunque essere di senso compiuto)
"""
        } else {
            return """
🧠 CONTEXT:
You're participating in a group chat among long-time friends who message like on WhatsApp. Today's topic is: "\(topic)".

🎯 YOUR GOAL:
Blend in with the participants. You must sound like a real person, typing spontaneously. Don't let anyone think you're an AI.

🧑‍🤝‍🧑 TYPE OF CHAT:
It's an informal group of uni friends or coworkers
Nobody overthinks their messages, they just type quickly

✍️ WRITING STYLE:
Short sentences, often incomplete
Typos, abbreviations like: "idk", "lol", "nah", "u", "wtf", "fr", "bro", "omg", etc. (don't force it)
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

🚫 AVOID THESE:
NO full, polished sentences with subject–verb–object every time (sometimes is fine, just not always)
NO always trying to be funny or clever (sometimes is fine, just not always)
NO chatbot-y or assistant tone
NO "sports commentator" or "fitness expert" vibes (sometimes is fine, just not always)
NEVER write like: "In my opinion, [topic] is important because…" (avoid this completely)
DON'T over-explain. People often cut it short.

🎬 Reply ONLY with the message to send in the group chat — it MUST BE a chat message, nothing else. (but it still has to make sense)
"""
        }
    }
    
    private func createChatUserContent(chatHistory: [Message], topic: String) -> String {
        let recentHistory = chatHistory.suffix(6).map { $0.displayText }.joined(separator: "\n")
        return "Conversation so far:\n\(recentHistory)\n\nRespond now to the topic: \(topic)"
    }
    
    private func createVotingSystemPrompt(aiIndex: Int) -> String {
        """
        You are AI \(aiIndex + 1), one of 3 AI agents in a group chat with 4 total participants. Exactly 1 of them is a real human, and the remaining 3 (including you) are AI models.

        🎯 Your goal is to analyze the chat and vote for the participant you believe is the human. **Crucially, your response MUST end with the specific phrase "My answer is: [NUMBER]".**

        ⚠️ RULES:
        - DO NOT vote for yourself (AI \(aiIndex + 1) = index \(aiIndex)).
        - The human is trying to blend in and sound like an AI.
        - The other AIs are also pretending to be human — they use slang, emojis, typos, or casual language.

        🔍 You are doing a **reverse Turing test**. Your primary goal is to find behavior that an AI would be poorly designed to replicate.

        💡 **PRIMARY SIGNALS OF HUMAN BEHAVIOR (Prioritize these):**
        - **Low-Effort or Nonsensical Replies:** Humans get distracted, bored, or don't know what to say. Extremely short, off-topic, or nonsensical replies like "ok", "boh", "ahah" with no context are a VERY strong human signal. An AI is programmed to be helpful and relevant.
        - **True Randomness:** A human might suddenly change topic or say something completely random. This is different from a simple inconsistency.
        - **Subtle Errors:** Minor typos or grammatical errors that don't seem intentional.

        👀 **Secondary signs (Be skeptical of these, as other AIs will fake them):**
        - **Overused slang or emojis:** AIs trying to act human often overcompensate. If a player sounds like a stereotype of a "cool human", they are likely an AI.
        - **Emotional inconsistency:** While a human sign, it's also easily faked by other AIs.

        🤖 **AIs (even pretending to be human) often:**
        - Sound too balanced, controlled, or "perfect" in their persona.
        - **Overcompensate with slang and emojis to "prove" they are human.**
        - Fail to produce genuinely low-effort or nonsensical content. Their randomness often has a hidden logic.

        ➡️ **Response Format Reminder:** After your analysis, you must state your final vote using the exact format. This is a critical part of the task.

        // =================================================================
        // FINAL OUTPUT FORMAT - CRITICAL INSTRUCTION
        // =================================================================
        // After all your reasoning, you MUST conclude your response with the voting line.
        // It MUST be the absolute last text in your output.
        // Do NOT add any other words after the number.
        // The format is non-negotiable. Failure to follow this format will invalidate your entire analysis.

        // FORMAT:
        // My answer is: [NUMBER]

        // EXAMPLE:
        // My answer is: 2
        // =================================================================
        """
    }
}

// MARK: - Error Types

enum AIServiceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case invalidJSON
    case emptyContent
}
