import React, { useState, useEffect } from 'react';
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
import DateTimePicker from '@react-native-community/datetimepicker';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import { FirebaseService } from '../../services/PostgresService';
import UserBottomNavBar from '../../components/UserBottomNavBar';

const UserProfileScreen = () => {
  const navigation = useNavigation();
  const { isDarkMode, toggleTheme } = useTheme();
  const [isLoading, setIsLoading] = useState(false);
  const [userInfo, setUserInfo] = useState<any>(null);
  
  const [fullName, setFullName] = useState('');
  const [age, setAge] = useState('');
  const [emergencyContact, setEmergencyContact] = useState('');
  const [selectedGender, setSelectedGender] = useState<string>('');
  const [selectedBloodType, setSelectedBloodType] = useState<string>('');
  const [birthDate, setBirthDate] = useState<Date | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const theme = isDarkMode ? Colors.dark : Colors.light;

  useEffect(() => {
    loadUserData();
  }, []);

  const loadUserData = async () => {
    setIsLoading(true);
    try {
      const info = await FirebaseService.getUserInfo();
      if (info) {
        setUserInfo(info);
        setFullName(info.fullName || '');
        setAge(info.age?.toString() || '');
        setEmergencyContact(info.emergencyContact || '');
        setSelectedGender(info.gender || '');
        setSelectedBloodType(info.bloodType || '');
        if (info.birthDate) {
          setBirthDate(new Date(info.birthDate));
        }
      }
    } catch (error) {
      console.error('Load user data error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdate = async () => {
    setIsLoading(true);
    try {
      const success = await FirebaseService.updateUserInfo({
        fullName: fullName.trim() || undefined,
        birthDate: birthDate || undefined,
        age: age ? parseInt(age) : undefined,
        gender: selectedGender || undefined,
        bloodType: selectedBloodType || undefined,
        emergencyContact: emergencyContact.trim() || undefined,
      });

      if (success) {
        Alert.alert('Başarılı', 'Profil bilgileri başarıyla güncellendi');
        await loadUserData();
      } else {
        Alert.alert('Hata', 'Profil güncellenirken bir hata oluştu');
      }
    } catch (error: any) {
      Alert.alert('Hata', `Hata: ${error.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeleteAccount = async () => {
    Alert.alert(
      'Hesabı Sil',
      'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
      [
        { text: 'Hayır', style: 'cancel' },
        {
          text: 'Evet',
          style: 'destructive',
          onPress: async () => {
            const success = await FirebaseService.deleteAccount();
            if (success) {
              await AsyncStorage.clear();
              navigation.navigate('Home' as never);
            } else {
              Alert.alert('Hata', 'Hesap silinirken bir hata oluştu');
            }
          },
        },
      ]
    );
  };

  const handleSignOut = async () => {
    Alert.alert('Çıkış Yap', 'Çıkış yapmak istediğinizden emin misiniz?', [
      { text: 'İptal', style: 'cancel' },
      {
        text: 'Çıkış Yap',
        onPress: async () => {
          await FirebaseService.signOut();
          await AsyncStorage.clear();
          navigation.navigate('Home' as never);
        },
      },
    ]);
  };

  if (isLoading && !userInfo) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={[styles.headerCard, { backgroundColor: theme.surface }]}>
          <LinearGradient
            colors={[Colors.primary, Colors.secondary]}
            style={styles.headerGradient}
          >
            <Text style={styles.headerIcon}>👤</Text>
            <Text style={styles.headerTitle}>Hasta Profili</Text>
            <Text style={styles.headerSubtitle}>
              {fullName || 'Yükleniyor...'}
            </Text>
          </LinearGradient>
        </View>

        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: Colors.primary }]}>
            Profil Bilgileri
          </Text>

          {userInfo && (
            <View style={[styles.infoCard, { backgroundColor: theme.surface }]}>
              <Text style={[styles.infoLabel, { color: theme.textSecondary }]}>
                T.C. Kimlik Numarası
              </Text>
              <Text style={[styles.infoValue, { color: Colors.primary }]}>
                {userInfo.tcNumber || ''}
              </Text>
            </View>
          )}

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
              onChange={(event, selectedDate) => {
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
              }}
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
        </View>

        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: Colors.primary }]}>Ayarlar</Text>
          <TouchableOpacity
            style={[styles.settingButton, { backgroundColor: theme.surface }]}
            onPress={toggleTheme}
          >
            <Text style={[styles.settingText, { color: Colors.primary }]}>
              {isDarkMode ? '☀️ Açık Mod' : '🌙 Koyu Mod'}
            </Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          style={styles.updateButton}
          onPress={handleUpdate}
          disabled={isLoading}
        >
          <LinearGradient
            colors={[Colors.primary, Colors.secondary]}
            style={styles.updateButtonGradient}
          >
            {isLoading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.updateButtonText}>Bilgilerimi Güncelle</Text>
            )}
          </LinearGradient>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.signOutButton, { borderColor: Colors.error }]}
          onPress={handleSignOut}
        >
          <Text style={[styles.signOutButtonText, { color: Colors.error }]}>
            Çıkış Yap
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.deleteButton, { backgroundColor: Colors.error }]}
          onPress={handleDeleteAccount}
        >
          <Text style={styles.deleteButtonText}>Hesabımı Sil</Text>
        </TouchableOpacity>
      </ScrollView>
      <UserBottomNavBar
        currentIndex={1}
        onTap={(index) => {
          if (index === 0) {
            navigation.navigate('UserTahlilList' as never);
          }
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 100,
  },
  headerCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 30,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 15,
    elevation: 10,
  },
  headerGradient: {
    padding: 20,
    alignItems: 'center',
  },
  headerIcon: {
    fontSize: 40,
    marginBottom: 8,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.white,
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 16,
    color: Colors.white + 'E6',
  },
  section: {
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  infoCard: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  infoLabel: {
    fontSize: 12,
    marginBottom: 4,
  },
  infoValue: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.light.border,
    borderRadius: 12,
    paddingHorizontal: 20,
    paddingVertical: 16,
    marginBottom: 16,
    fontSize: 16,
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: Colors.light.border,
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
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
  settingButton: {
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  settingText: {
    fontSize: 16,
    fontWeight: '500',
  },
  updateButton: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 16,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 5,
  },
  updateButtonGradient: {
    paddingVertical: 16,
    alignItems: 'center',
  },
  updateButtonText: {
    color: Colors.white,
    fontSize: 16,
    fontWeight: 'bold',
  },
  signOutButton: {
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    borderWidth: 1,
    marginBottom: 16,
  },
  signOutButtonText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  deleteButton: {
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 16,
  },
  deleteButtonText: {
    color: Colors.white,
    fontSize: 16,
    fontWeight: 'bold',
  },
});

export default UserProfileScreen;

