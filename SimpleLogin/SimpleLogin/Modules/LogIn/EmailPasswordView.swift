//
//  EmailPasswordView.swift
//  SimpleLogin
//
//  Created by Thanh-Nhon Nguyen on 03/08/2021.
//

import SwiftUI

struct EmailPasswordView: View {
    @State private var showPassword = false
    @State private var forgotPassword = false
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack {
            VStack(spacing: 10) {
                ZStack(alignment: .trailing) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.accentColor)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.trailing, 24)
                    }

                    Button(action: {
                        email = ""
                    }, label: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Color.gray)
                    })
                }

                if !forgotPassword {
                    Color.gray.opacity(0.2)
                        .frame(height: 1)
                        .padding(.horizontal, -16)

                    ZStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: "lock.circle")
                                .foregroundColor(.accentColor)
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.trailing, 24)
                            } else {
                                SecureField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.trailing, 24)
                            }
                        }

                        Button(action: {
                            showPassword.toggle()
                        }, label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(Color.gray)
                        })
                    }
                }
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 8.0)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            Button(action: logInOrResetPassword) {
                Text(forgotPassword ? "Reset password" : "Log in")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 4)
            .disabled(!forgotPassword && (email.isEmpty || password.isEmpty))

            Button(action: {
                withAnimation {
                    forgotPassword.toggle()
                }
            }, label: {
                Text(forgotPassword ? "Return to log in" : "Forgot password")
                    .font(.footnote)
            })

        }
    }

    private func logInOrResetPassword() {
        if forgotPassword {
            print("Reset password")
        } else {
            print("Log in")
        }
    }
}

struct EmailPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        EmailPasswordView(email: .constant(""), password: .constant(""))
    }
}
