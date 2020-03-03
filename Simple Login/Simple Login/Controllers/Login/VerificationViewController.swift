//
//  OtpViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 05/02/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit
import MBProgressHUD
import Toaster

extension VerificationViewController {
    enum VerificationMode {
        case otp(mfaKey: String), accountActivation(email: String, password: String)
    }
}

final class VerificationViewController: UIViewController, Storyboarded {
    @IBOutlet private weak var firstNumberLabel: UILabel!
    @IBOutlet private weak var secondNumberLabel: UILabel!
    @IBOutlet private weak var thirdNumberLabel: UILabel!
    @IBOutlet private weak var fourthNumberLabel: UILabel!
    @IBOutlet private weak var fifthNumberLabel: UILabel!
    @IBOutlet private weak var sixthNumberLabel: UILabel!
    
    @IBOutlet private weak var errorLabel: UILabel!
    
    @IBOutlet private weak var zeroButton: UIButton!
    @IBOutlet private weak var oneButton: UIButton!
    @IBOutlet private weak var twoButton: UIButton!
    @IBOutlet private weak var threeButton: UIButton!
    @IBOutlet private weak var fourButton: UIButton!
    @IBOutlet private weak var fiveButton: UIButton!
    @IBOutlet private weak var sixButton: UIButton!
    @IBOutlet private weak var sevenButton: UIButton!
    @IBOutlet private weak var eightButton: UIButton!
    @IBOutlet private weak var nineButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    
    @IBOutlet private var buttons: [UIButton]!
    
    var otpVerificationSuccesful: ((_ apiKey: String) -> Void)?
    var accountVerificationSuccesful: (() -> Void)?
    
    var mode: VerificationMode!
    
    deinit {
        print("VerificationViewController is deallocated")
        NotificationCenter.default.removeObserver(self, name: .applicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .applicationDidBecomeActive, object: nil)
    }
    
    private func setUpUI() {
        buttons.forEach { (button) in
            button.layer.cornerRadius = button.bounds.width/2
            button.backgroundColor = SLColor.textColor.withAlphaComponent(0.1)
        }
        
        errorLabel.alpha = 0
        
        switch mode {
        case .otp: title = "Enter OTP"
        case .accountActivation: title = "Enter activation code"
        case .none: title = nil
        }
    }
    
    @objc private func applicationDidBecomeActive() {
        guard let copiedText = UIPasteboard.general.string,
            copiedText.count == 6,
            let _ = Int(copiedText) else { return }
        
        showErrorLabel(false)
        
        firstNumberLabel.text = String(copiedText[0])
        secondNumberLabel.text = String(copiedText[1])
        thirdNumberLabel.text = String(copiedText[2])
        fourthNumberLabel.text = String(copiedText[3])
        fifthNumberLabel.text = String(copiedText[4])
        sixthNumberLabel.text = String(copiedText[5])
        
        verify(otpCode: copiedText)
    }
    
    @IBAction private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func verify(otpCode: String) {
        showErrorLabel(false)
        MBProgressHUD.showAdded(to: view, animated: true)
        
        switch mode {
        case .otp(let mfaKey):
            SLApiService.verifyMFA(mfaKey: mfaKey, mfaToken: otpCode) { [weak self] (apiKey, error) in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let error = error {
                    self.showErrorLabel(true, errorMessage: error.description)
                    self.reset()
                } else if let apiKey = apiKey {
                    self.dismiss(animated: true) {
                        self.otpVerificationSuccesful?(apiKey)
                    }
                }
            }
            
        case .accountActivation(let email, _):
            SLApiService.verifyEmail(email: email, code: otpCode) { [weak self] (error) in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let error = error {
                    switch error {
                    case .reactivationNeeded: self.showReactivateAlert(email: email)
                        
                    default:
                        self.showErrorLabel(true, errorMessage: error.description)
                    }
                    
                    self.reset()
                    
                } else {
                    self.dismiss(animated: true) {
                        self.accountVerificationSuccesful?()
                    }
                }
            }
            
        default: return
        }
        
    }
    
    private func showErrorLabel(_ show: Bool, errorMessage: String? = nil) {
        if show {
            errorLabel.text = errorMessage
            errorLabel.alpha = 1
            errorLabel.shake()
        } else {
            if errorLabel.alpha == 0 { return }
            
            UIView.animate(withDuration: 0.35) { [unowned self] in
                self.errorLabel.alpha = 0
            }
        }
    }
    
    private func showReactivateAlert(email: String) {
        let alert = UIAlertController(title: "Wrong code too many times", message: "Resend a new activation code for \"\(email)\"", preferredStyle: .alert)
        
        let resendAction = UIAlertAction(title: "Resend me new code", style: .default) { [unowned self] (_) in
            self.reactivate(email: email)
        }
        alert.addAction(resendAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func reactivate(email: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        SLApiService.reactivate(email: email) { [weak self] (error) in
            guard let self = self else { return }
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let error = error {
                self.showErrorLabel(true, errorMessage: error.description)
            } else {
                Toast.displayLongly(message: "Check your inbox for new activation code")
            }
        }
    }
}

// MARK: - Button actions
extension VerificationViewController {
    private func addNumber(_ number: String) {
        if firstNumberLabel.text == "-" {
            firstNumberLabel.text = number
            showErrorLabel(false)
        } else if secondNumberLabel.text == "-" {
            secondNumberLabel.text = number
        } else if thirdNumberLabel.text == "-" {
            thirdNumberLabel.text = number
        } else if fourthNumberLabel.text == "-" {
            fourthNumberLabel.text = number
        } else if fifthNumberLabel.text == "-" {
            fifthNumberLabel.text = number
        } else if sixthNumberLabel.text == "-" {
            sixthNumberLabel.text = number
            var otpCode = ""
            otpCode += firstNumberLabel.text ?? ""
            otpCode += secondNumberLabel.text ?? ""
            otpCode += thirdNumberLabel.text ?? ""
            otpCode += fourthNumberLabel.text ?? ""
            otpCode += fifthNumberLabel.text ?? ""
            otpCode += sixthNumberLabel.text ?? ""
            
            verify(otpCode: otpCode)
        }
    }
    
    private func deleteLastNumber() {
        if sixthNumberLabel.text != "-" {
            sixthNumberLabel.text = "-"
        } else if fifthNumberLabel.text != "-" {
            fifthNumberLabel.text = "-"
        } else if fourthNumberLabel.text != "-" {
            fourthNumberLabel.text = "-"
        } else if thirdNumberLabel.text != "-" {
            thirdNumberLabel.text = "-"
        } else if secondNumberLabel.text != "-" {
            secondNumberLabel.text = "-"
        } else if firstNumberLabel.text != "-" {
            firstNumberLabel.text = "-"
        }
    }
    
    private func reset() {
        firstNumberLabel.text = "-"
        secondNumberLabel.text = "-"
        thirdNumberLabel.text = "-"
        fourthNumberLabel.text = "-"
        fifthNumberLabel.text = "-"
        sixthNumberLabel.text = "-"
    }
    
    @IBAction private func deleteButtonTapped() {
        deleteLastNumber()
    }
    
    @IBAction private func zeroButtonTapped() {
        addNumber("0")
    }
    
    @IBAction private func oneButtonTapped() {
        addNumber("1")
    }
    
    @IBAction private func twoButtonTapped() {
        addNumber("2")
    }
    
    @IBAction private func threeButtonTapped() {
        addNumber("3")
    }
    
    @IBAction private func fourButtonTapped() {
        addNumber("4")
    }
    
    @IBAction private func fiveButtonTapped() {
        addNumber("5")
    }
    
    @IBAction private func sixButtonTapped() {
        addNumber("6")
    }
    
    @IBAction private func sevenButtonTapped() {
        addNumber("7")
    }
    
    @IBAction private func eightButtonTapped() {
        addNumber("8")
    }
    
    @IBAction private func nineButtonTapped() {
        addNumber("9")
    }
}