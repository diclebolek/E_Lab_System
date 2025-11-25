import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import AdminBottomNavBar from '../../components/AdminBottomNavBar';

const AdminDashboardScreen = () => {
  const { isDarkMode } = useTheme();
  const [fullName, setFullName] = useState('');
  const [tc, setTc] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [age, setAge] = useState(0);
  const [gender, setGender] = useState('');
  const [serumValues, setSerumValues] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);

  const theme = isDarkMode ? Colors.dark : Colors.light;
  const serumTypes = ['IgG', 'IgG1', 'IgG2', 'IgG3', 'IgG4', 'IgA', 'IgA1', 'IgA2', 'IgM'];

  const handleEvaluate = () => {
    // Değerlendirme mantığı buraya eklenecek
    console.log('Değerlendirme yapılıyor...');
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <LinearGradient
            colors={[Colors.primary, Colors.secondary]}
            style={styles.headerGradient}
          >
            <Text style={styles.headerTitle}>Hızlı Değerlendirme</Text>
          </LinearGradient>
        </View>

        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>
            Hasta Bilgileri
          </Text>
          <TextInput
            style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
            placeholder="Ad Soyad"
            placeholderTextColor={theme.textSecondary}
            value={fullName}
            onChangeText={setFullName}
          />
          <TextInput
            style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
            placeholder="TC Kimlik No"
            placeholderTextColor={theme.textSecondary}
            value={tc}
            onChangeText={setTc}
            keyboardType="numeric"
          />
          <TextInput
            style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
            placeholder="Doğum Tarihi (GG/AA/YYYY)"
            placeholderTextColor={theme.textSecondary}
            value={birthDate}
            onChangeText={(text) => {
              setBirthDate(text);
              if (text.length === 10) {
                // Yaş hesaplama mantığı
              }
            }}
          />
          <Text style={[styles.ageText, { color: Colors.primary }]}>
            Yaş (Yıl): {age}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>
            Serum Değerleri
          </Text>
          {serumTypes.map((type) => (
            <TextInput
              key={type}
              style={[styles.input, { backgroundColor: theme.surface, color: theme.text }]}
              placeholder={type}
              placeholderTextColor={theme.textSecondary}
              value={serumValues[type] || ''}
              onChangeText={(value) =>
                setSerumValues({ ...serumValues, [type]: value })
              }
              keyboardType="numeric"
            />
          ))}
        </View>

        <TouchableOpacity
          style={styles.evaluateButton}
          onPress={handleEvaluate}
          disabled={isLoading}
        >
          <LinearGradient
            colors={['#4CAF50', '#45A049']}
            style={styles.evaluateButtonGradient}
          >
            {isLoading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.evaluateButtonText}>Değerlendir</Text>
            )}
          </LinearGradient>
        </TouchableOpacity>
      </ScrollView>
      <AdminBottomNavBar
        currentIndex={2}
        onTap={(index) => {
          console.log('Navigate to:', index);
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
    paddingBottom: 80,
  },
  header: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 20,
  },
  headerGradient: {
    padding: 16,
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.white,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
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
  ageText: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  evaluateButton: {
    borderRadius: 12,
    overflow: 'hidden',
    marginTop: 20,
  },
  evaluateButtonGradient: {
    paddingVertical: 16,
    alignItems: 'center',
  },
  evaluateButtonText: {
    color: Colors.white,
    fontSize: 18,
    fontWeight: 'bold',
  },
});

export default AdminDashboardScreen;

