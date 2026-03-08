//
//  AuthManager.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-03-05.
//
import FirebaseAuth    //To handle account creation and user login
import FirebaseFirestore //For cloud database storage
import Combine //To update UI

//Authentication class
class AuthManager: ObservableObject {
        
    @Published var user: FirebaseAuth.User? // Is user logged in?
    private let db = Firestore.firestore() //firebase database reference

    init() {
        self.user = Auth.auth().currentUser //check if the user has already logged in
    }
    //function call for account creation and profile save
    func signUp(email: String, password: String, fullName: String) {
        //create a new account
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            //check if new account is valid
            if let user = result?.user {
                //save the profile to database
                self.db.collection("users").document(user.uid).setData([
                    "fullName": fullName,
                    "email": email,
                    "fcmToken": "",
                    "createdAt": FieldValue.serverTimestamp() //timestamp for notification
                ])
                self.user = user //update UI to logged-in state
            }
        }
    }
    //function call to sign in if profile exists
    func signIn(email: String, password: String) {

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            self.user = result?.user
        }
    }
    //function call to log out
    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }
}
