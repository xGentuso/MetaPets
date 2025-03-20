//
//  PetCareQuiz.swift
//  Petopia
//
//  Created for Petopia minigames system
//

import SwiftUI

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    
    var correctAnswer: String {
        options[correctAnswerIndex]
    }
}

struct PetCareQuiz: View {
    @ObservedObject var viewModel: PetViewModel
    let game: Minigame
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int?
    @State private var isAnswerCorrect = false
    @State private var score = 0
    @State private var timeRemaining = 0
    @State private var gameState: GameState = .notStarted
    @State private var earnedCoins = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum GameState {
        case notStarted, playing, reviewing, gameOver
    }
    
    var body: some View {
        VStack {
            // Game header
            VStack(spacing: 4) {
                Text(game.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(game.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            // Game stats
            HStack(spacing: 24) {
                VStack {
                    Text("Question")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentQuestionIndex + 1)/\(questions.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(timeRemaining)s")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(timeRemaining < 10 ? .red : .primary)
                }
            }
            .padding()
            
            if gameState == .notStarted {
                VStack(spacing: 20) {
                    Text("Test your pet care knowledge!")
                        .font(.headline)
                    
                    Button("Start Quiz") {
                        startQuiz()
                    }
                    .padding()
                    .frame(minWidth: 120)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if gameState == .playing || gameState == .reviewing, currentQuestionIndex < questions.count {
                VStack(alignment: .leading, spacing: 20) {
                    // Question
                    Text(questions[currentQuestionIndex].question)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    
                    // Answer options
                    ForEach(0..<questions[currentQuestionIndex].options.count, id: \.self) { index in
                        Button {
                            if gameState == .playing {
                                answerSelected(index)
                            }
                        } label: {
                            HStack {
                                Text(questions[currentQuestionIndex].options[index])
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if gameState == .reviewing {
                                    if index == questions[currentQuestionIndex].correctAnswerIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if index == selectedAnswerIndex {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .background(answerBackground(for: index))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(answerBorder(for: index), lineWidth: 2)
                            )
                        }
                        .disabled(gameState == .reviewing)
                    }
                    
                    if gameState == .reviewing {
                        Button(currentQuestionIndex < questions.count - 1 ? "Next Question" : "Finish Quiz") {
                            if currentQuestionIndex < questions.count - 1 {
                                currentQuestionIndex += 1
                                selectedAnswerIndex = nil
                                gameState = .playing
                                resetTimer()
                            } else {
                                endQuiz()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                    }
                }
                .padding()
            } else if gameState == .gameOver {
                VStack(spacing: 12) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your Score: \(score)/\(questions.count * 10)")
                        .font(.headline)
                    
                    Text("You earned \(earnedCoins) coins!")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .frame(minWidth: 120)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                .padding()
            }
        }
        .onAppear {
            loadQuestions()
        }
        .onReceive(timer) { _ in
            if gameState == .playing && timeRemaining > 0 {
                timeRemaining -= 1
                
                if timeRemaining == 0 {
                    // Time ran out
                    reviewAnswer(nil)
                }
            }
        }
    }
    
    private func answerBackground(for index: Int) -> Color {
        if gameState == .reviewing {
            if index == questions[currentQuestionIndex].correctAnswerIndex {
                return Color.green.opacity(0.2)
            } else if index == selectedAnswerIndex {
                return Color.red.opacity(0.2)
            }
        } else if selectedAnswerIndex == index {
            return Color.blue.opacity(0.2)
        }
        
        return Color.secondary.opacity(0.1)
    }
    
    private func answerBorder(for index: Int) -> Color {
        if gameState == .reviewing {
            if index == questions[currentQuestionIndex].correctAnswerIndex {
                return .green
            } else if index == selectedAnswerIndex {
                return .red
            }
            return .clear
        } else if selectedAnswerIndex == index {
            return .blue
        }
        
        return .clear
    }
    
    private func loadQuestions() {
        // In a real app, you might load these from a data source
        questions = [
            QuizQuestion(
                question: "How often should you brush a dog's teeth?",
                options: ["Daily", "Weekly", "Monthly", "Never"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What is a sign that a cat might be sick?",
                options: ["Excessive meowing", "Changes in appetite", "Increased playfulness", "Sleeping more than usual"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How often should you clean a pet's water bowl?",
                options: ["Monthly", "Weekly", "Daily", "When it looks dirty"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "Which of these foods is toxic to dogs?",
                options: ["Carrots", "Peanut butter", "Chocolate", "Rice"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "How often should cats visit the vet for checkups?",
                options: ["Only when sick", "Every 5 years", "Every other year", "At least once a year"],
                correctAnswerIndex: 3
            ),
            QuizQuestion(
                question: "What is the ideal temperature range for most pet reptiles?",
                options: ["60-70°F", "70-85°F", "85-100°F", "It depends on the species"],
                correctAnswerIndex: 3
            ),
            QuizQuestion(
                question: "How often should you trim a dog's nails?",
                options: ["Never", "Every 1-2 months", "Once a year", "Every week"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What's the best way to introduce a new pet to your home?",
                options: ["Immediately let them explore everything", "Keep them in a small area at first", "Introduce them to all your other pets right away", "Leave them alone for the first day"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How much exercise does an average adult dog need daily?",
                options: ["None, they exercise themselves", "5-10 minutes", "30-60 minutes", "4-5 hours"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "Which of these is NOT a sign of a healthy bird?",
                options: ["Bright eyes", "Clean feathers", "Labored breathing", "Active behavior"],
                correctAnswerIndex: 2
            )
        ]
    }
    
    private func startQuiz() {
        shuffleQuestions()
        currentQuestionIndex = 0
        score = 0
        gameState = .playing
        resetTimer()
    }
    
    private func shuffleQuestions() {
        questions.shuffle()
        
        // Limit number of questions based on difficulty
        let questionCount: Int
        switch game.difficulty {
        case .easy: questionCount = 5
        case .medium: questionCount = 7
        case .hard: questionCount = 10
        }
        
        if questions.count > questionCount {
            questions = Array(questions.prefix(questionCount))
        }
    }
    
    private func resetTimer() {
        switch game.difficulty {
        case .easy: timeRemaining = 30
        case .medium: timeRemaining = 20
        case .hard: timeRemaining = 15
        }
    }
    
    private func answerSelected(_ index: Int) {
        selectedAnswerIndex = index
        reviewAnswer(index)
    }
    
    private func reviewAnswer(_ index: Int?) {
        gameState = .reviewing
        
        if let index = index, index == questions[currentQuestionIndex].correctAnswerIndex {
            isAnswerCorrect = true
            
            // Award points based on time remaining
            let timeBonus = Int(Double(timeRemaining) / 5.0)
            let questionPoints = 10 + timeBonus
            score += questionPoints
        } else {
            isAnswerCorrect = false
        }
    }
    
    private func endQuiz() {
        gameState = .gameOver
        
        // Record the game played for cooldown
        viewModel.recordMinigamePlayed(game)
        
        // Award currency based on score
        let maxScore = questions.count * 15 // Max possible score
        earnedCoins = calculateReward(score: score, maxScore: maxScore)
        viewModel.awardMinigameReward(minigame: game, score: score, maxScore: maxScore)
    }
    
    private func calculateReward(score: Int, maxScore: Int) -> Int {
        let baseReward = game.possibleReward
        let percentage = min(1.0, Double(score) / Double(maxScore))
        return Int(Double(baseReward) * percentage)
    }
}

struct PetCareQuiz_Previews: PreviewProvider {
    static var previews: some View {
        PetCareQuiz(
            viewModel: PetViewModel(),
            game: Minigame(
                name: "Pet Care Quiz",
                description: "Test your pet care knowledge and earn rewards!",
                difficulty: .medium,
                type: .petCare,
                rewardAmount: 20,
                imageName: "game_quiz",
                cooldownMinutes: 60
            )
        )
    }
}
