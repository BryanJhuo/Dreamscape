//
//  AuthView.swift
//  Dreamscape
//
//  Created by 卓柏辰 on 2025/6/13.
//
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// MARK: - Main View
struct AuthView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var isLoginMode: Bool = true // Default to login mode, if user is not logged in

    var body: some View {
        ZStack {
            // Background
            // call Static Background
            //GeometryReader { geo in
            //    StarfieldBackground(width: geo.size.width, height: geo.size.height)
            //}
            // call Dynamic Background
            AnimatedStarfieldBackground(starCount: 72)
                .ignoresSafeArea()
            
            VStack {
                // Title
                Text("Welcome to Dreamscape")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .padding(.top, 80)
                
                Spacer()

                // Main Content
                ZStack {
                    if isLoginMode {
                        LogInView {
                            withAnimation(.easeInOut) {
                                isLoginMode = false
                            }
                        }
                        .environmentObject(appViewModel)
                        .transition(.move(edge: .trailing))
                    } else {
                        SignUpView {
                            withAnimation(.easeInOut) {
                                isLoginMode = true
                            }
                        }
                        .transition(.move(edge: .leading))
                    }
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // call Backend API to check if user is logged in
            isLoginMode = appViewModel.isLoggedIn
            // print("User is logged in: \(isLoginMode)")  
        }
    }
}


// MARK: - Login Sub View
struct LogInView: View {
    var switchToSignup: () -> Void
    @EnvironmentObject var appViewModel: AppViewModel 

    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            // Email Input
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .foregroundColor(.white)

            // Password Input
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .foregroundColor(.white)

            // Login Button
            Button(action: {
                // TODO: Handle login action
                FirebaseService.userLogin(mail: email, password: password) { success, error in
                    if success {
                        alertMessage = "Login successful!"
                        email = ""
                        password = ""
                    } else {
                        alertMessage = error?.localizedDescription ?? "Unknown error"
                    }
                    showAlert = true

                }
            }) {
                Text("Log In")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [Color.purple.opacity(0.8), Color.purple], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }

            // Switch to Signup
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.white.opacity(0.7))
                Button(action: switchToSignup) {
                    Text("Sign Up")
                        .foregroundColor(.purple)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .animation(nil, value: UUID())
        .alert("Notification", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
                if alertMessage == "Login successful!" {
                    appViewModel.isLoggedIn = true
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Signup Sub View
struct SignUpView: View  {
    var switchToLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Email Input
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .foregroundColor(.white)

            // Password Input
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .foregroundColor(.white)

            // Signup Button
            Button(action: {
                // TODO: Handle signup action
                FirebaseService.userRegister(mail: email, password: password) { success, error in
                    if success {
                        alertMessage = "Registration successful!"
                        email = ""
                        password = ""
                        let uid = Auth.auth().currentUser!.uid
                        let newUser = User(uid: uid, name: "User \(uid)", avatar: "", createdAt: Timestamp(date: Date()), likedArticles: [], savedArticles: [])
                        FirebaseService.createUser(user: newUser){ success, error in
                            if success{
                                alertMessage = "Create user successful!"
                            }else{
                                alertMessage = error?.localizedDescription ?? "Unknown error"
                            }
                        }
                    }else{
                        alertMessage = error?.localizedDescription ?? "Unknown error"
                    }
                    showAlert = true
                }
                    
            }) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [Color.purple.opacity(0.8), Color.purple], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }

            // Switch to Login
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.white.opacity(0.7))
                Button(action: switchToLogin) {
                    Text("Log In")
                        .foregroundColor(.purple)
                        .fontWeight(.bold)
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .animation(nil, value: UUID())
        .alert("Notification", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Starfield Background(Static)
struct StarfieldBackground: View {
    let starCount: Int
    let width: CGFloat
    let height: CGFloat

    // Precompute star data to avoid changing every redraw
    private let stars: [Star]

    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
    }

    init(starCount: Int = 60, width: CGFloat = 400, height: CGFloat = 800) {
        self.starCount = starCount
        self.width = width
        self.height = height
        self.stars = (0..<starCount).map { _ in
            Star(
                x: CGFloat.random(in: 0...width),
                y: CGFloat.random(in: 0...height),
                radius: CGFloat.random(in: 0.8...2.2),
                opacity: Double.random(in: 0.5...1.0)
            )
        }
    }

    var body: some View {
        ZStack {
            // Background Colors can be adjusted for aesthetic preference
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.black]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.radius * 2, height: star.radius * 2)
                    .position(x: star.x, y: star.y)
            }
        }
    }
}


// MARK: - Preview
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .preferredColorScheme(.dark)
            .environmentObject(AppViewModel()) // Provide AppViewModel for preview
    }
}
