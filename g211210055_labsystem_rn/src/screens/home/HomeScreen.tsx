import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useNavigation } from '@react-navigation/native';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import UserLoginScreen from '../login/UserLoginScreen';
import AdminLoginScreen from '../login/AdminLoginScreen';

const { width } = Dimensions.get('window');

const HomeScreen = () => {
  const navigation = useNavigation();
  const { isDarkMode } = useTheme();
  const [activeTab, setActiveTab] = useState(0); // 0: Doktor, 1: Hasta

  const theme = isDarkMode ? Colors.dark : Colors.light;

  return (
    <LinearGradient
      colors={[Colors.primary, Colors.secondary, theme.background]}
      locations={[0, 0.3, 0.3]}
      style={styles.container}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.content}>
          {/* Logo/Icon */}
          <View style={styles.logoContainer}>
            <LinearGradient
              colors={[Colors.primary, Colors.secondary]}
              style={styles.logoCircle}
            >
              <Text style={styles.logoIcon}>🔬</Text>
            </LinearGradient>
          </View>

          {/* Başlık */}
          <View style={styles.titleContainer}>
            <Text style={styles.title}>E-Laboratuvar</Text>
            <Text style={styles.title}>Sistemi</Text>
          </View>

          <View style={styles.welcomeContainer}>
            <Text style={styles.welcomeText}>Hoşgeldiniz</Text>
          </View>

          {/* Tab Bar */}
          <View style={styles.tabContainer}>
            <TouchableOpacity
              style={[styles.tab, activeTab === 0 && styles.activeTab]}
              onPress={() => setActiveTab(0)}
            >
              <Text style={[styles.tabIcon, activeTab === 0 && styles.activeTabText]}>
                🏥
              </Text>
              <Text style={[styles.tabText, activeTab === 0 && styles.activeTabText]}>
                Doktor Girişi
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.tab, activeTab === 1 && styles.activeTab]}
              onPress={() => setActiveTab(1)}
            >
              <Text style={[styles.tabIcon, activeTab === 1 && styles.activeTabText]}>
                👤
              </Text>
              <Text style={[styles.tabText, activeTab === 1 && styles.activeTabText]}>
                Hasta Girişi
              </Text>
            </TouchableOpacity>
          </View>

          {/* Tab Content */}
          <View style={styles.tabContent}>
            {activeTab === 0 ? <AdminLoginScreen /> : <UserLoginScreen />}
          </View>
        </View>
      </ScrollView>
    </LinearGradient>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
    paddingHorizontal: 20,
  },
  logoContainer: {
    marginBottom: 30,
  },
  logoCircle: {
    width: 140,
    height: 140,
    borderRadius: 70,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 10,
  },
  logoIcon: {
    fontSize: 80,
  },
  titleContainer: {
    alignItems: 'center',
    marginBottom: 12,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#007BBF',
    letterSpacing: 1.2,
  },
  welcomeContainer: {
    paddingHorizontal: 24,
    paddingVertical: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 20,
    marginBottom: 10,
  },
  welcomeText: {
    fontSize: 18,
    color: Colors.white,
    fontWeight: '500',
  },
  tabContainer: {
    flexDirection: 'row',
    marginHorizontal: 20,
    marginTop: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderRadius: 12,
    padding: 4,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
  },
  activeTab: {
    backgroundColor: Colors.primary,
  },
  tabIcon: {
    fontSize: 24,
    marginRight: 8,
  },
  tabText: {
    fontSize: 16,
    fontWeight: '500',
    color: Colors.black,
  },
  activeTabText: {
    color: Colors.white,
    fontWeight: 'bold',
  },
  tabContent: {
    width: '100%',
    maxWidth: 500,
    marginTop: 8,
  },
});

export default HomeScreen;

