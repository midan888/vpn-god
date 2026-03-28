import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var code = ""

    var isEmailValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    var isCodeValid: Bool {
        code.count == 6
    }
}
