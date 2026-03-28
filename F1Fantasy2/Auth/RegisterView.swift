///
///  RegisterView.swift
///  F1Fantasy2
///

import SwiftUI

/// A view that provides a user interface for registering a new account.
struct RegisterView: View{
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loading: Bool = false
    @Environment(\.dismiss) var dismiss
    private let network = Network()
    
    /// Validates the provided email string using a regular expression.
    ///
    /// The regex pattern checks for a standard email format.
    ///
    /// - Parameter email: The email address to validate.
    /// - Returns: `true` if the email matches the regex pattern; otherwise, `false`.
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    /// The main view body presenting the registration UI.
    var body: some View {
        VStack (spacing: 100){
            Spacer()
            Text("Register").font(.largeTitle).fontWeight(.bold)
            VStack(spacing: 13){
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(email.isEmpty ? .blue : (isValidEmail(email) ? .green : .red), lineWidth: 2)
                    }
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.blue, lineWidth: 2)
                    }
            }
            Spacer()
            HStack{
                Button{
                    loading = true
                    Task{
                        let response = await network.post(endpoint: "register", body: ["email": email, "password": password])
                        if response.success{
                            dismiss()
                            loading = false
                        }
                        else{
                            print(response.response)
                        }
                    }
                }label: {
                    if loading{
                        ProgressView()
                            .frame(width: 150, height: 36)
                    }
                    else{
                        Text("Create Account")
                            .frame(width: 150, height: 36)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidEmail(email) || password.count < 8 || email.isEmpty)
            }
        }.padding()
    }
}

#Preview {
    RegisterView()
}

