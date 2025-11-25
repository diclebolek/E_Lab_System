import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import { FirebaseService } from '../../services/PostgresService';

const AdminLoginScreen = () => {
  const navigation = useNavigation();
  const { isDarkMode } = useTheme();
  const [tc, setTc] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

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
      const success = await FirebaseService.signInAsAdmin(tc.trim(), password.trim());
      setIsLoading(false);

      if (success) {
        navigation.navigate('AdminDashboard' as never);
      } else {
        Alert.alert('Hata', 'TC kimlik veya şifre hatalı!');
      }
    } catch (error: any) {
      setIsLoading(false);
      Alert.alert('Hata', `Giriş yapılırken bir hata oluştu: ${error.message}`);
    }
  };

  return (
    <View style={styles.container}>
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

        <TouchableOpacity
          style={styles.button}
          onPress={handleLogin}
          disabled={isLoading}
        >
          <LinearGradient
            colors={[Colors.primary, Colors.secondary]}
            style={styles.buttonGradient}
          >
            {isLoading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.buttonText}>Giriş Yap</Text>
            )}
          </LinearGradient>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
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
  button: {
    borderRadius: 12,
    overflow: 'hidden',
    marginTop: 10,
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
});

export default AdminLoginScreen;

