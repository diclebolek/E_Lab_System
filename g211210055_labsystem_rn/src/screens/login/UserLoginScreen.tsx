import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LinearGradient } from 'expo-linear-gradient';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import { FirebaseService } from '../../services/PostgresService';

const UserLoginScreen = () => {
  const navigation = useNavigation();
  const { isDarkMode } = useTheme();
  const [isRegistering, setIsRegistering] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  
  // Form state
  const [tc, setTc] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [age, setAge] = useState('');
  const [emergencyContact, setEmergencyContact] = useState('');
  const [selectedGender, setSelectedGender] = useState<string>('');
  const [selectedBloodType, setSelectedBloodType] = useState<string>('');
  const [birthDate, setBirthDate] = useState<Date | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const theme = isDarkMode ? Colors.dark : Colors.light;

  const handleLogin = async () => {
    if (!tc.trim() || !password.trim()) {
      Alert.alert('Hata', 'TC kimlik ve şifre giriniz');
      return;
    }

    if (tc.length !== 11) {
      Alert.alert('Hata', 'TC kimlik numarası 11 haneli olmalıdır');
      return;
    }

    setIsLoading(true);
    try {
      const result = await FirebaseService.signInWithTC(tc.trim(), password);
      setIsLoading(false);

      if (result) {
        await AsyncStorage.setItem('user_tc', tc.trim());
        navigation.navigate('UserTahlilList' as never);
      } else {
        Alert.alert('Hata', 'TC kimlik veya şifre hatalı!');
      }
    } catch (error: any) {
      setIsLoading(false);
      Alert.alert('Hata', `Giriş yapılırken bir hata oluştu: ${error.message}`);
    }
  };

  const handleRegister = async () => {
    if (!tc.trim() || !password.trim()) {
      Alert.alert('Hata', 'TC kimlik ve şifre giriniz');
      return;
    }

    if (tc.length !== 11) {
      Alert.alert('Hata', 'TC kimlik numarası 11 haneli olmalıdır');
      return;
    }

    if (password.length < 6) {
      Alert.alert('Hata', 'Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (isRegistering) {
      if (!fullName.trim()) {
        Alert.alert('Hata', 'Ad soyad giriniz');
        return;
      }
      if (!selectedGender) {
        Alert.alert('Hata', 'Cinsiyet seçiniz');
        return;
      }
      if (!age.trim()) {
        Alert.alert('Hata', 'Yaş giriniz');
        return;
      }
      if (!selectedBloodType) {
        Alert.alert('Hata', 'Kan grubu seçiniz');
        return;
      }
      if (!emergencyContact.trim()) {
        Alert.alert('Hata', 'Yakın numarası giriniz');
        return;
      }
    }

    setIsLoading(true);
    try {
      let calculatedAge: number | undefined;
      if (birthDate) {
        const now = new Date();
        calculatedAge = now.getFullYear() - birthDate.getFullYear();
        if (now.getMonth() < birthDate.getMonth() ||
            (now.getMonth() === birthDate.getMonth() && now.getDate() < birthDate.getDate())) {
          calculatedAge--;
        }
      } else if (age.trim()) {
        calculatedAge = parseInt(age.trim());
      }

      const result = await FirebaseService.signUpWithTC(
        tc.trim(),
        password,
        {
          fullName: fullName.trim() || undefined,
          gender: selectedGender || undefined,
          age: calculatedAge,
          birthDate: birthDate || undefined,
          bloodType: selectedBloodType || undefined,
          emergencyContact: emergencyContact.trim() || undefined,
        }
      );

      setIsLoading(false);

      if (result) {
        await AsyncStorage.setItem('user_tc', tc.trim());
        Alert.alert('Başarılı', 'Kayıt başarılı!');
        setIsRegistering(false);
        navigation.navigate('UserTahlilList' as never);
      } else {
        Alert.alert('Hata', 'Kayıt başarısız! Bu TC kimlik zaten kayıtlı olabilir.');
      }
    } catch (error: any) {
      setIsLoading(false);
      Alert.alert('Hata', `Kayıt yapılırken bir hata oluştu: ${error.message}`);
    }
  };

  const onDateChange = (event: any, selectedDate?: Date) => {
    setShowDatePicker(false);
    if (selectedDate) {
      setBirthDate(selectedDate);
      const now = new Date();
      let calculatedAge = now.getFullYear() - selectedDate.getFullYear();
      if (now.getMonth() < selectedDate.getMonth() ||
          (now.getMonth() === selectedDate.getMonth() && now.getDate() < selectedDate.getDate())) {
        calculatedAge--;
      }
      setAge(calculatedAge.toString());
    }
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      <View style={styles.form}>
        <TextInput
          style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
          placeholder="TC Kimlik Numarası"
          placeholderTextColor={theme.textSecondary}
          value={tc}
          onChangeText={setTc}
          keyboardType="numeric"
          maxLength={11}
        />

        <TextInput
          style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
          placeholder="Şifre"
          placeholderTextColor={theme.textSecondary}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
        />

        {isRegistering && (
          <>
            <TextInput
              style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
              placeholder="Ad Soyad"
              placeholderTextColor={theme.textSecondary}
              value={fullName}
              onChangeText={setFullName}
            />

            <TouchableOpacity
              style={[styles.input, { backgroundColor: theme.surface }]}
              onPress={() => setShowDatePicker(true)}
            >
              <Text style={{ color: birthDate ? theme.text : theme.textSecondary }}>
                {birthDate
                  ? `${birthDate.getDate()}/${birthDate.getMonth() + 1}/${birthDate.getFullYear()}`
                  : 'Doğum Tarihi Seçiniz'}
              </Text>
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={birthDate || new Date()}
                mode="date"
                display="default"
                onChange={onDateChange}
                maximumDate={new Date()}
                minimumDate={new Date(1900, 0, 1)}
              />
            )}

            <TextInput
              style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
              placeholder="Yaş"
              placeholderTextColor={theme.textSecondary}
              value={age}
              onChangeText={setAge}
              keyboardType="numeric"
              editable={!birthDate}
            />

            <View style={[styles.pickerContainer, { backgroundColor: theme.surface }]}>
              <Text style={[styles.pickerLabel, { color: theme.textSecondary }]}>Cinsiyet</Text>
              <View style={styles.pickerRow}>
                {['Erkek', 'Kadın'].map((gender) => (
                  <TouchableOpacity
                    key={gender}
                    style={[
                      styles.pickerOption,
                      selectedGender === gender && styles.pickerOptionActive,
                    ]}
                    onPress={() => setSelectedGender(gender)}
                  >
                    <Text
                      style={[
                        styles.pickerOptionText,
                        selectedGender === gender && styles.pickerOptionTextActive,
                      ]}
                    >
                      {gender}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={[styles.pickerContainer, { backgroundColor: theme.surface }]}>
              <Text style={[styles.pickerLabel, { color: theme.textSecondary }]}>Kan Grubu</Text>
              <View style={styles.pickerRow}>
                {['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'].map((bloodType) => (
                  <TouchableOpacity
                    key={bloodType}
                    style={[
                      styles.pickerOption,
                      selectedBloodType === bloodType && styles.pickerOptionActive,
                    ]}
                    onPress={() => setSelectedBloodType(bloodType)}
                  >
                    <Text
                      style={[
                        styles.pickerOptionText,
                        selectedBloodType === bloodType && styles.pickerOptionTextActive,
                      ]}
                    >
                      {bloodType}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <TextInput
              style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
              placeholder="Yakın Numarası"
              placeholderTextColor={theme.textSecondary}
              value={emergencyContact}
              onChangeText={setEmergencyContact}
              keyboardType="phone-pad"
            />
          </>
        )}

        <TouchableOpacity
          style={styles.button}
          onPress={isRegistering ? handleRegister : handleLogin}
          disabled={isLoading}
        >
          <LinearGradient
            colors={[Colors.primary, Colors.secondary]}
            style={styles.buttonGradient}
          >
            {isLoading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.buttonText}>
                {isRegistering ? 'Kayıt Ol' : 'Giriş Yap'}
              </Text>
            )}
          </LinearGradient>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.switchButton}
          onPress={() => setIsRegistering(!isRegistering)}
        >
          <Text style={[styles.switchButtonText, { color: Colors.primary }]}>
            {isRegistering
              ? 'Zaten bir hesabınız var mı? Giriş yapın.'
              : 'Hesabınız yok mu? Kayıt olun.'}
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  form: {
    padding: 20,
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.light.border,
    borderRadius: 12,
    paddingHorizontal: 20,
    paddingVertical: 16,
    marginBottom: 20,
    fontSize: 16,
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: Colors.light.border,
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  pickerLabel: {
    fontSize: 14,
    marginBottom: 12,
  },
  pickerRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  pickerOption: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.light.border,
    backgroundColor: Colors.light.background,
  },
  pickerOptionActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  pickerOptionText: {
    fontSize: 14,
    color: Colors.light.text,
  },
  pickerOptionTextActive: {
    color: Colors.white,
    fontWeight: 'bold',
  },
  button: {
    borderRadius: 12,
    overflow: 'hidden',
    marginTop: 10,
    marginBottom: 20,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 5,
  },
  buttonGradient: {
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    color: Colors.white,
    fontSize: 18,
    fontWeight: 'bold',
    letterSpacing: 0.5,
  },
  switchButton: {
    alignItems: 'center',
    paddingVertical: 10,
  },
  switchButtonText: {
    fontSize: 14,
  },
});

export default UserLoginScreen;

