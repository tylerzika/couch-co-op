import SwiftUI
import MathLibSwift

struct ContentView: View {
    @State private var firstNumber: Int32 = 10
    @State private var secondNumber: Int32 = 5
    @State private var result: Int32 = 0
    @State private var operation: String = "+"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Math Library")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .padding()

                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        Text("\(firstNumber)")
                            .font(.system(size: 36, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text(operation)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("\(secondNumber)")
                            .font(.system(size: 36, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .background(Color(.darkGray))
                    .cornerRadius(10)

                    Text("= \(result)")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding()

                VStack(spacing: 15) {
                    Button(action: { performOperation("+") }) {
                        Text("Add")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { performOperation("-") }) {
                        Text("Subtract")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { performOperation("×") }) {
                        Text("Multiply")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { performOperation("÷") }) {
                        Text("Divide")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
        }
    }

    private func performOperation(_ op: String) {
        operation = op
        
        switch op {
        case "+":
            result = MathLib.add(firstNumber, secondNumber)
        case "-":
            result = MathLib.subtract(firstNumber, secondNumber)
        case "×":
            result = MathLib.multiply(firstNumber, secondNumber)
        case "÷":
            result = MathLib.divide(firstNumber, secondNumber)
        default:
            result = 0
        }
    }
}

#Preview {
    ContentView()
}
