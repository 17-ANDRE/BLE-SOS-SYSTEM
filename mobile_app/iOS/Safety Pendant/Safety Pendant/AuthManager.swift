//
//  AuthManager.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-03-05.
//
import FirebaseAuth    //To handle account creation and user login
import FirebaseFirestore //For cloud database storage
import Combine //To update UI
import FirebaseMessaging //handle receiving and sending push notifications

//Authentication class
class AuthManager: ObservableObject {
    
    static let shared = AuthManager()
    
    @Published var user: FirebaseAuth.User? // Is user logged in?
    private let db = Firestore.firestore() //firebase database reference
    
    init() {
        self.user = Auth.auth().currentUser //check if the user has already logged in
    }
    //function call for account creation and profile save
    func signUp(email: String, password: String, fullName: String) {
        //create a new account
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            //check if sign up failed
            if let error = error {
                print("Sign up error: \(error.localizedDescription)")
                return
            }
            //check if new account is valid
            guard let user = result?.user else {
                print("No user returned")
                return
            }
            print("User created: \(user.uid)")
            //save the profile to database
            Messaging.messaging().token { token, error in
                //check if FCM token failed
                if let error = error {
                    print("❌ FCM token error: \(error.localizedDescription)")
                }
                
                print("FCM token received: \(token ?? "NIL")")
                self.db.collection("users").document(user.uid).setData([
                    "fullName": fullName,
                    "email": email,
                    "fcmToken": token ?? "",   // token when APN is implemented
                    "createdAt": FieldValue.serverTimestamp()
                ])
                //update UI to logged-in state
                DispatchQueue.main.async {
                    self.user = user
                }
            }
        }
    }
    //function call to sign in if profile exists
    func signIn(email: String, password: String) {
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            guard let user = result?.user else { return }
            self.user = user
            
            // Refresh token on every sign-in
            Messaging.messaging().token { token, _ in
                guard let token = token else { return }
                self.saveFCMToken(token)
            }
        }
    }
    //function call to log out
    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }
    
    //function call to save FCM Token
    func saveFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "fcmToken": token
        ])
    }
}
