extension EmailValidator on String {
  bool isValidEmail() {
    final validDomains = ['gmail.com', 'hotmail.com', 'icloud.com'];

    if (RegExp(
        r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(this)) {
      final emailParts = this.split('@');
      if (emailParts.length == 2) {
        final domain = emailParts[1].toLowerCase();
        return validDomains.contains(domain);
      }
    }
    return false;
  }
}
extension PhoneNumberValidator on String {
  bool isValidPhoneNumber() {
    return RegExp(r'^\+591[1-9][0-9]{7}$').hasMatch(this);
  }
}