//
//  RegisterView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

//TODO: Add users to database here

import SwiftUI

struct RegisterView: View{
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var loading: Bool = false
    @Environment(\.dismiss) var dismiss
    private let network = Network()
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
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
                            print(response.data!)
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
                    }
                    else{
                        Text("Create Account")
                            .padding(.vertical, 10)
                            .padding(.horizontal, 36)
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
