import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

/// A contact the user explicitly handed to the app via the OS picker.
class PickedContact {
  const PickedContact({required this.name, this.phone});
  final String name;
  final String? phone;
}

class ContactPickerException implements Exception {}

/// Platform boundary for picking one contact (faked in tests).
///
/// Uses the system contact picker, which needs no contacts permission: the app
/// only receives the single contact the user selects.
abstract class ContactPicker {
  /// Returns null if the user cancelled. Throws [ContactPickerException] if
  /// the picker could not be shown.
  Future<PickedContact?> pick();
}

class NativeContactPicker implements ContactPicker {
  final _picker = FlutterNativeContactPicker();

  @override
  Future<PickedContact?> pick() async {
    try {
      final c = await _picker.selectContact();
      if (c == null) return null;
      final name = (c.fullName ?? '').trim();
      final phones = c.phoneNumbers ?? const <String>[];
      final phone =
          c.selectedPhoneNumber ?? (phones.isEmpty ? null : phones.first);
      if (name.isEmpty && (phone == null || phone.isEmpty)) return null;
      return PickedContact(name: name, phone: phone);
    } catch (_) {
      throw ContactPickerException();
    }
  }
}
