import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/firebase_service.dart';

class UserLoginScreen extends StatefulWidget {
  final bool startWithRegister;

  const UserLoginScreen({super.key, this.startWithRegister = false});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  late bool _isRegistering;
  bool _isLoading = false;
  String? _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _isRegistering = widget.startWithRegister;
  }

  @override
  void dispose() {
    _tcController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await FirebaseService.signInWithTC(
      _tcController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result != null) {
        // TC numarasını sakla
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_tc', _tcController.text.trim());
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/user-tahlil-list');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TC kimlik veya şifre hatalı!')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Yaşı hesapla (doğum tarihinden)
    int? age;
    if (_selectedBirthDate != null) {
      final now = DateTime.now();
      age = now.year - _selectedBirthDate!.year;
      if (now.month < _selectedBirthDate!.month ||
          (now.month == _selectedBirthDate!.month &&
              now.day < _selectedBirthDate!.day)) {
        age--;
      }
    } else if (_ageController.text.isNotEmpty) {
      age = int.tryParse(_ageController.text.trim());
    }

    final result = await FirebaseService.signUpWithTC(
      _tcController.text.trim(),
      _passwordController.text,
      fullName: _fullNameController.text.trim().isEmpty
          ? null
          : _fullNameController.text.trim(),
      gender: _selectedGender,
      age: age,
      birthDate: _selectedBirthDate,
      bloodType: _selectedBloodType,
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result != null) {
        // TC numarasını sakla
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_tc', _tcController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kayıt başarılı!')));
          setState(() => _isRegistering = false);
          Navigator.pushReplacementNamed(context, '/user-tahlil-list');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt başarısız! Bu TC kimlik zaten kayıtlı olabilir.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        // Doğum tarihinden yaşı hesapla
        final now = DateTime.now();
        int calculatedAge = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          calculatedAge--;
        }
        _ageController.text = calculatedAge.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _tcController,
            decoration: const InputDecoration(
              labelText: 'TC Kimlik Numarası',
              prefixIcon: Icon(Icons.badge),
            ),
            keyboardType: TextInputType.number,
            maxLength: 11,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'TC kimlik numarası giriniz';
              }
              if (value.length != 11) {
                return 'TC kimlik numarası 11 haneli olmalıdır';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre giriniz';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır';
              }
              return null;
            },
          ),
          // Kayıt modunda gösterilecek ek alanlar
          if (_isRegistering) ...[
            const SizedBox(height: 20),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ad soyad giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Cinsiyet',
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Cinsiyet seçiniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Doğum Tarihi',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0058A3),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                      : 'Doğum tarihi seçiniz',
                  style: TextStyle(
                    color: _selectedBirthDate != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Yaş',
                prefixIcon: Icon(Icons.cake),
                helperText: 'Doğum tarihi seçildiğinde otomatik hesaplanır',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Yaş giriniz';
                }
                final age = int.tryParse(value);
                if (age == null || age < 0 || age > 150) {
                  return 'Geçerli bir yaş giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedBloodType,
              decoration: const InputDecoration(
                labelText: 'Kan Grubu',
                prefixIcon: Icon(Icons.bloodtype),
              ),
              items: const [
                DropdownMenuItem(value: 'A+', child: Text('A+')),
                DropdownMenuItem(value: 'A-', child: Text('A-')),
                DropdownMenuItem(value: 'B+', child: Text('B+')),
                DropdownMenuItem(value: 'B-', child: Text('B-')),
                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                DropdownMenuItem(value: '0+', child: Text('0+')),
                DropdownMenuItem(value: '0-', child: Text('0-')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBloodType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kan grubu seçiniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Yakın Numarası',
                prefixIcon: Icon(Icons.phone),
                helperText: 'Acil durumlarda aranacak telefon numarası',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Yakın numarası giriniz';
                }
                // Basit telefon numarası kontrolü
                if (value.length < 10) {
                  return 'Geçerli bir telefon numarası giriniz';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0058A3), Color(0xFF00A8E8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0058A3).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_isRegistering ? _handleRegister : _handleLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isRegistering ? 'Kayıt Ol' : 'Giriş Yap',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() => _isRegistering = !_isRegistering);
            },
            child: Text(
              _isRegistering
                  ? 'Zaten bir hesabınız var mı? Giriş yapın.'
                  : 'Hesabınız yok mu? Kayıt olun.',
              style: const TextStyle(color: Color(0xFF0058A3)),
            ),
          ),
        ],
      ),
    );
  }
}
