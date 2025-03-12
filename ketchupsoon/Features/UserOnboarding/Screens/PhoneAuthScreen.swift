import SwiftUI

struct PhoneAuthScreen: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    
    var body: some View {
        ZStack {
            // Background tap gesture to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Verify Your")
                            .font(.custom("SpaceGrotesk-Bold", size: 24))
                            .foregroundColor(.white)
                        Text("Number 📱")
                            .font(.custom("SpaceGrotesk-Bold", size: 24))
                            .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                    }
                    
                    Text(viewModel.showVerificationView ? 
                         "Enter the verification code sent to your phone" :
                         "We'll send a code to verify your phone number")
                        .font(.custom("SpaceGrotesk-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 24)
                
                // Form fields
                if viewModel.showVerificationView {
                    VerificationCodeView()
                        .environmentObject(viewModel)
                } else {
                    PhoneInputView()
                        .environmentObject(viewModel)
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 12) {
                    Button {
                        if viewModel.showVerificationView {
                            // Go back to phone input
                            viewModel.showVerificationView = false
                            viewModel.verificationCode = ""
                        } else {
                            viewModel.previousStep()
                        }
                    } label: {
                        Text("Back")
                            .font(.custom("SpaceGrotesk-Regular", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                    }
                    
                    Button {
                        if viewModel.showVerificationView {
                            viewModel.verifyCode()
                        } else {
                            viewModel.requestVerificationCode()
                        }
                    } label: {
                        HStack {
                            if viewModel.isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(viewModel.showVerificationView ? "Verify Code" : "Send Code")
                                .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                    Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.3)), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isVerifying)
                }
                .padding(.top, 24)
            }
            .padding(20)
        }
        .alert(isPresented: $viewModel.showingError) {
            Alert(
                title: Text("Authentication Error"),
                message: Text(viewModel.authError?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Phone input view
struct PhoneInputView: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Phone number field
            VStack(alignment: .leading, spacing: 6) {
                Text("phone number")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    // Country code prefix
                    Text("+1")
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                    
                    Divider()
                        .frame(width: 1)
                        .background(Color.white.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    // Phone number input
                    TextField("(555) 555-5555", text: $viewModel.formattedPhoneNumber)
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white)
                        .keyboardType(.phonePad)
                        .focused($isInputFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isInputFocused = true
                            }
                        }
                        .onChange(of: viewModel.formattedPhoneNumber) { _, newValue in
                            viewModel.formattedPhoneNumber = viewModel.formatPhoneNumber(newValue)
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                                .font(.headline)
                                .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                            }
                        }
                }
                .frame(height: 45)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Privacy info
            Text("We'll send a text with a verification code. Message and data rates may apply. This helps us verify your identity and keep your account secure.")
                .font(.custom("SpaceGrotesk-Regular", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.leading)
        }
    }
}

// Verification code view
struct VerificationCodeView: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Verification code field
            VStack(alignment: .leading, spacing: 8) {
                Text("verification code")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    Spacer()
                    
                    // Main hidden text field
                    TextField("", text: $viewModel.verificationCode)
                        .keyboardType(.numberPad)
                        .focused($isInputFocused)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        .onChange(of: viewModel.verificationCode) { _, value in
                            // Limit to 6 digits
                            if value.count > 6 {
                                viewModel.verificationCode = String(value.prefix(6))
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                                .font(.headline)
                                .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                            }
                        }
                    
                    // Digit display boxes
                    ForEach(0..<6, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 50)
                            
                            if index < viewModel.verificationCode.count {
                                let digit = Array(viewModel.verificationCode)[index]
                                Text(String(digit))
                                    .font(.custom("SpaceGrotesk-SemiBold", size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            isInputFocused = true
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            
            // Info
            Text("Enter the 6-digit code sent to +1 \(viewModel.formattedPhoneNumber)")
                .font(.custom("SpaceGrotesk-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            // Resend code button
            Button {
                viewModel.requestVerificationCode()
            } label: {
                Text("Resend Code")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                    .padding(.vertical, 8)
            }
            .disabled(viewModel.isVerifying)
        }
        .onAppear {
            // Focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
} 
