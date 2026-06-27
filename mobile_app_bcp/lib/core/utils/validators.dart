// validators.dart
class Validators {
  static String? validateDni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El documento es obligatorio';
    }
    if (value.trim().length != 8 || int.tryParse(value) == null) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }
    return null;
  }

  static String? validateCodigoEmpleado(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código de empleado es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'Código de empleado no válido';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }
}
