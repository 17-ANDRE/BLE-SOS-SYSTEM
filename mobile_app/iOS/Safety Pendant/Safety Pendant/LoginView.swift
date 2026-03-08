//
//  LoginView.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-03-06.
//
import SwiftUI

// Account authentication display
struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    //show login text boxes for login or account creation
    var body: some View {
        VStack(spacing: 20) {
            if isSignUp {
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(.roundedBorder)
            }
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            //button for sign up
            Button(isSignUp ? "Sign Up" : "Sign In") {
                if isSignUp {
                    auth.signUp(email: email, password: password, fullName: fullName)
                } else {
                    auth.signIn(email: email, password: password)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        //button to toggle between Login and Sign up
            Button(isSignUp ? "Already have an account?" : "Create account") {
                isSignUp.toggle()
            }
        }
        .padding()
    }
}
