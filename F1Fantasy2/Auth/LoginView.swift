//
//  LoginView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/14/26.
//

import SwiftUI

struct LoginView: View{
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var incorrect: Bool = false
    @ObservedObject var userData: UserData
    @State var loading: Bool = false
    
    var body: some View {
        VStack (spacing: 100){
            Spacer()
            Text("Login").font(.largeTitle).fontWeight(.bold)
            VStack(spacing: 13){
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.blue, lineWidth: 2)
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
            HStack{
                if incorrect{
                    Text("Invalid username or password").foregroundColor(.red)
                }
            }.frame(height: 10)
            Spacer()
            HStack(spacing: 20){
                Button{
                    Task{
                        loading = true
                        let success = await userData.login(email: email, password: password)
                        if success{
                            loading = false
                        }
                        else{
                            loading = false
                            incorrect = true
                        }
                    }
                }label: {
                    if loading{
                        ProgressView()
                            .frame(width: 110, height: 36)
                    }
                    else{
                        Text("Login")
                            .frame(width: 110, height: 36)
                    }
                }.buttonStyle(.borderedProminent)
                NavigationLink {
                    RegisterView()
                }label: {
                    Text("Create Account")
                        .frame(width: 160, height: 36)
                }.buttonStyle(.bordered)
            }
        }.padding()
    }
}

#Preview {
    LoginView(userData: UserData())
}
