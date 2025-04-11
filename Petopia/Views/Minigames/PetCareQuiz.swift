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
            return themeColor.opacity(0.2)
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
            return themeColor
        }
        
        return .clear
    }
    
    private func loadQuestions() {
        // Get questions based on pet type
        switch viewModel.pet.type {
        case .cat:
            loadCatQuestions()
        case .chicken:
            loadChickenQuestions()
        case .cow:
            loadCowQuestions()
        case .pig:
            loadPigQuestions()
        case .sheep:
            loadSheepQuestions()
        }
    }
    
    private func loadCatQuestions() {
        questions = [
            QuizQuestion(
                question: "How often should you brush a cat's teeth?",
                options: ["Daily", "Weekly", "Monthly", "Never"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What is a sign that a cat might be sick?",
                options: ["Excessive meowing", "Changes in appetite", "Increased playfulness", "Sleeping more than usual"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What nutrient is especially important for cats?",
                options: ["Carbohydrates", "Fiber", "Taurine", "Vitamin C"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "How often should an indoor cat be vaccinated?",
                options: ["Every year", "Every 2-3 years", "Only as a kitten", "Never"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "Which of these human foods is toxic to cats?",
                options: ["Chicken", "Onions", "Rice", "Apples"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What's a healthy way to keep a cat mentally stimulated?",
                options: ["Interactive toys", "Leaving them alone", "Playing loud music", "Bright flashing lights"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "How much water should a cat drink daily?",
                options: ["3-4 ounces", "5-10 ounces", "12-15 ounces", "None if eating wet food"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What's the average lifespan of an indoor cat?",
                options: ["5-7 years", "8-10 years", "13-17 years", "20+ years"],
                correctAnswerIndex: 2
            )
        ]
    }
    
    private func loadChickenQuestions() {
        questions = [
            QuizQuestion(
                question: "What should chickens have constant access to?",
                options: ["Treats", "Fresh water", "Other chickens", "Toys"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What is a sign that a chicken might be sick?",
                options: ["Reduced egg production", "Active foraging", "Bright red comb", "Increased appetite"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "How often should a chicken coop be cleaned?",
                options: ["Daily", "Weekly", "Monthly", "Yearly"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What's a good treat for chickens?",
                options: ["Chocolate", "Avocado", "Mealworms", "Coffee grounds"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "How much space does each chicken need in a coop?",
                options: ["1-2 square feet", "3-5 square feet", "7-10 square feet", "15+ square feet"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "Which is a sign of a healthy chicken?",
                options: ["Dull feathers", "Clear, bright eyes", "Labored breathing", "Pale comb"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What should make up the majority of a chicken's diet?",
                options: ["Seeds", "Commercial chicken feed", "Table scraps", "Fruit"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How often do chickens need grit in their diet?",
                options: ["Never", "Weekly", "Monthly", "Daily access"],
                correctAnswerIndex: 3
            )
        ]
    }
    
    private func loadCowQuestions() {
        questions = [
            QuizQuestion(
                question: "How much water does a cow drink daily?",
                options: ["1-5 gallons", "8-10 gallons", "20-30 gallons", "40+ gallons"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's a sign of a healthy cow?",
                options: ["Bright, alert eyes", "Labored breathing", "Limited movement", "Reduced appetite"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "How often should a cow's hooves be checked?",
                options: ["Daily", "Weekly", "Monthly", "Yearly"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What food is ideal for cows?",
                options: ["Pure grain", "High-quality hay/grass", "Mostly corn", "Primarily fruits"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How much space does a cow need at minimum?",
                options: ["20 square feet", "50-100 square feet", "1-2 acres", "5+ acres"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What temperature range is comfortable for cows?",
                options: ["20-75°F", "40-60°F", "75-90°F", "90-100°F"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "How should cows be approached?",
                options: ["Quickly from behind", "Calmly from the side", "With loud noises", "Only at feeding time"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What's important for a cow's shelter?",
                options: ["Completely enclosed", "Good ventilation", "Small and cozy", "Heated year-round"],
                correctAnswerIndex: 1
            )
        ]
    }
    
    private func loadPigQuestions() {
        questions = [
            QuizQuestion(
                question: "What's the ideal temperature range for pigs?",
                options: ["45-75°F", "80-90°F", "90-100°F", "Below 45°F"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What's a sign of a healthy pig?",
                options: ["Wet cough", "Bright, active eyes", "Limited movement", "Dry, flaky skin"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "What should always be provided for pigs?",
                options: ["Mud baths", "Fresh water", "Heating lamps", "Dietary supplements"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How often should a pig's living area be cleaned?",
                options: ["Daily", "Weekly", "Monthly", "Every few months"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What's a healthy treat for pigs?",
                options: ["Chocolate", "Avocados", "Strawberries", "Onions"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "How much space does a medium-sized pig need?",
                options: ["10 square feet", "50-100 square feet", "200+ square feet", "1+ acre"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's the best bedding material for pigs?",
                options: ["Cedar shavings", "Straw", "Cat litter", "Sand"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How can you tell if a pig is too hot?",
                options: ["Curling up in a ball", "Panting heavily", "Energetic behavior", "Increased appetite"],
                correctAnswerIndex: 1
            )
        ]
    }
    
    private func loadSheepQuestions() {
        questions = [
            QuizQuestion(
                question: "How often should sheep be sheared?",
                options: ["Monthly", "Twice yearly", "Once yearly", "Every other year"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What is a sign that a sheep might be sick?",
                options: ["Reduced appetite", "Bright eyes", "Active movement", "Regular bleating"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What should sheep always have access to?",
                options: ["Grain feed", "Fresh water", "Salt licks", "Shade and shelter"],
                correctAnswerIndex: 3
            ),
            QuizQuestion(
                question: "How much grazing space does each sheep need?",
                options: ["50 square feet", "100-200 square feet", "1/4-1/2 acre", "1+ acre"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's the most common health issue in sheep?",
                options: ["Foot rot", "Ear infections", "Tooth decay", "Eye problems"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "When should lambs be weaned?",
                options: ["2-3 weeks", "1-2 months", "3-4 months", "6+ months"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What should form the majority of a sheep's diet?",
                options: ["Grain", "Grass/hay", "Fruits", "Vegetables"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How can you tell a sheep's approximate age?",
                options: ["By wool color", "By checking their teeth", "By their size", "By horn length"],
                correctAnswerIndex: 1
            )
        ]
    }
    
    private func loadGenericQuestions() {
        // Original questions as fallback
        questions = [
            QuizQuestion(
                question: "How often should you brush a pet's teeth?",
                options: ["Daily", "Weekly", "Monthly", "Never"],
                correctAnswerIndex: 0
            ),
            QuizQuestion(
                question: "What is a sign that a pet might be sick?",
                options: ["Excessive vocalization", "Changes in appetite", "Increased playfulness", "Sleeping more than usual"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How much exercise does an average pet need daily?",
                options: ["None", "15-30 minutes", "1-2 hours", "4+ hours"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's the most important nutrient for pets?",
                options: ["Carbohydrates", "Protein", "Fat", "Fiber"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How often should you replace your pet's water?",
                options: ["Once a week", "Every few days", "Daily", "Only when empty"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's the best way to introduce a new food to your pet?",
                options: ["Switch immediately", "Mix gradually with old food", "Alternate days", "Let them choose"],
                correctAnswerIndex: 1
            ),
            QuizQuestion(
                question: "How often should pets visit a veterinarian?",
                options: ["Only when sick", "Every few years", "Annually", "Monthly"],
                correctAnswerIndex: 2
            ),
            QuizQuestion(
                question: "What's most important for maintaining pet health?",
                options: ["Expensive food", "Regular grooming", "Preventative care", "Lots of toys"],
                correctAnswerIndex: 2
            )
        ]
    }
    
    // Theme color based on pet type
    private var themeColor: Color {
        switch viewModel.pet.type {
        case .cat:
            return .blue
        case .chicken:
            return .yellow
        case .cow:
            return .brown
        case .pig:
            return .pink
        case .sheep:
            return .mint
        }
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
                cooldownMinutes: 60,
                petType: .cat
            )
        )
    }
}
