//
//  JoinLeagueView.swift
//  F1Fantasy2
//
//  Created by Chase Roach on 3/20/26.
//

import SwiftUI

struct JoinLeague: Codable, Identifiable, Hashable {
    var id: Int
    var name: String
    var code: Int
}

struct JoinLeagueView: View{
    @State private var code: String = ""
    @State private var incorrect: Bool = false
    @ObservedObject var userData: UserData
    @State var loading: Bool = false
    @State var showName: Bool = false
    @State var league: JoinLeague?
    
    var body: some View {
        NavigationStack{
            VStack (spacing: 100){
                Spacer()
                Text("Join League").font(.largeTitle).fontWeight(.bold)
                VStack(spacing: 13){
                    HStack(spacing: 10) {
                        ForEach(0..<4) { i in
                            ZStack {
                                Rectangle()
                                    .frame(width: 50, height: 60)
                                    .cornerRadius(8)
                                    .foregroundColor(.gray.opacity(0.2))
                                
                                Text(code.count > i ? String(code[code.index(code.startIndex, offsetBy: i)]) : "")
                                    .font(.title)
                            }
                        }
                    }
                    .overlay(
                        TextField("", text: $code)
                            .keyboardType(.numberPad)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                    )
                    .onChange(of: code) { newValue in
                        code = String(newValue.filter { $0.isNumber }.prefix(4))
                        if code.count == 4{
                            findLeague(showError: false)
                        }
                    }
                }
                HStack{
                    if incorrect{
                        Text("League not found").foregroundColor(.red)
                    }
                }.frame(height: 10)
                Spacer()
                HStack(spacing: 20){
                    Button{
                        findLeague()
                    }label: {
                        if loading{
                            ProgressView()
                                .frame(width: 110, height: 36)
                        }
                        else{
                            Text("Join")
                                .frame(width: 110, height: 36)
                        }
                    }.buttonStyle(.borderedProminent)
                    NavigationLink {
                        RegisterView()
                    }label: {
                        Text("Create League")
                            .frame(width: 160, height: 36)
                    }.buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationDestination(item: $league) { league in
                createNameView(league: league, userData: userData)
            }
        }
    }
    func findLeague(showError: Bool = true){
        loading = true
        Task{
            let network = Network()
            let response = await network.get(endpoint: "findLeague", queryItems: [URLQueryItem(name: "leagueCode", value: code)])
            if response.success{
                do{
                    let joinLeague: [JoinLeague] = try JSONDecoder().decode([JoinLeague].self, from: response.data!)
                    if let league = joinLeague.first{
                        self.league = league
                        loading = false
                    }
                    else{
                        incorrect = true && showError;
                        loading = false;
                    }
                }
                catch {
                    print("Error decoding: \(error)")
                }
            }
            else{
                incorrect = true && showError;
                loading = false;
            }
        }
    }
}

struct createNameView: View{
    @State var name = ""
    @State var incorrect = false
    @State var loading = false
    var league: JoinLeague
    @ObservedObject var userData: UserData
    
    var body: some View{
        VStack (spacing: 100){
            Spacer()
            Text("\(league.name)").font(.largeTitle).fontWeight(.bold)
            VStack(spacing: 13){
                TextField("Username", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.blue, lineWidth: 2)
                    }
                Text("Your username is visible to others and unique to each league.").font(Font.caption.italic())
            }
            HStack{
                if incorrect{
                    Text("Name already taken").foregroundColor(.red)
                }
            }.frame(height: 10)
            Spacer()
            HStack{
                Button{
                    Task{
                        loading = true
                        let network = Network()
                        let response = await network.post(endpoint: "joinLeague", body: ["league_id" : league.id, "username" : name, "token" : userData.token])
                        if response.success{
                            _ = await userData.load()
                        }
                        else{
                            incorrect = true
                            loading = false
                        }
                    }

                }label: {
                    if loading{
                        ProgressView()
                            .frame(width: 150, height: 36)
                    }
                    else{
                        Text("Join League")
                            .frame(width: 150, height: 36)
                    }
                }.disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    JoinLeagueView(userData: UserData())
}
