import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { StatusBar } from 'expo-status-bar';
import { ThemeProvider } from './src/providers/ThemeProvider';
import { useTheme } from './src/providers/ThemeProvider';
import HomeScreen from './src/screens/home/HomeScreen';
import UserLoginScreen from './src/screens/login/UserLoginScreen';
import AdminLoginScreen from './src/screens/login/AdminLoginScreen';
import UserTahlilListScreen from './src/screens/user/UserTahlilListScreen';
import UserTahlilDetailScreen from './src/screens/user/UserTahlilDetailScreen';
import UserProfileScreen from './src/screens/user/UserProfileScreen';
import AdminDashboardScreen from './src/screens/admin/AdminDashboardScreen';
import TahlilEkleScreen from './src/screens/admin/TahlilEkleScreen';
import TahlilListScreen from './src/screens/admin/TahlilListScreen';
import TahlilDetailScreen from './src/screens/admin/TahlilDetailScreen';
import KilavuzScreen from './src/screens/admin/KilavuzScreen';
import KilavuzListScreen from './src/screens/admin/KilavuzListScreen';
import AdminProfileScreen from './src/screens/admin/AdminProfileScreen';

const Stack = createNativeStackNavigator();

const AppContent = () => {
  const { isDarkMode } = useTheme();

  return (
    <>
      <StatusBar style={isDarkMode ? 'light' : 'dark'} />
      <NavigationContainer
        theme={{
          dark: isDarkMode,
          colors: {
            primary: '#0058A3',
            background: isDarkMode ? '#121212' : '#F8F9FA',
            card: isDarkMode ? '#1E1E1E' : '#FFFFFF',
            text: isDarkMode ? '#FFFFFF' : '#000000',
            border: isDarkMode ? '#333333' : '#E0E0E0',
            notification: '#0058A3',
          },
        }}
      >
        <Stack.Navigator
          initialRouteName="Home"
          screenOptions={{
            headerStyle: {
              backgroundColor: '#0058A3',
            },
            headerTintColor: '#FFFFFF',
            headerTitleStyle: {
              fontWeight: 'bold',
            },
          }}
        >
          <Stack.Screen
            name="Home"
            component={HomeScreen}
            options={{ headerShown: false }}
          />
          <Stack.Screen
            name="UserLogin"
            component={UserLoginScreen}
            options={{ title: 'Hasta Girişi' }}
          />
          <Stack.Screen
            name="AdminLogin"
            component={AdminLoginScreen}
            options={{ title: 'Doktor Girişi' }}
          />
          <Stack.Screen
            name="UserTahlilList"
            component={UserTahlilListScreen}
            options={{ title: 'Tahlil Listesi' }}
          />
          <Stack.Screen
            name="UserTahlilDetail"
            component={UserTahlilDetailScreen}
            options={{ title: 'Tahlil Detayı' }}
          />
          <Stack.Screen
            name="UserProfile"
            component={UserProfileScreen}
            options={{ title: 'Profil Yönetimi' }}
          />
          <Stack.Screen
            name="AdminDashboard"
            component={AdminDashboardScreen}
            options={{ title: 'Doktor Rapor Yönetim Paneli' }}
          />
          <Stack.Screen
            name="TahlilEkle"
            component={TahlilEkleScreen}
            options={{ title: 'Tahlil Ekle' }}
          />
          <Stack.Screen
            name="TahlilList"
            component={TahlilListScreen}
            options={{ title: 'Tahlil Listesi' }}
          />
          <Stack.Screen
            name="TahlilDetail"
            component={TahlilDetailScreen}
            options={{ title: 'Tahlil Detayı' }}
          />
          <Stack.Screen
            name="Kilavuz"
            component={KilavuzScreen}
            options={{ title: 'Kılavuz Oluştur' }}
          />
          <Stack.Screen
            name="KilavuzList"
            component={KilavuzListScreen}
            options={{ title: 'Kılavuz Listesi' }}
          />
          <Stack.Screen
            name="AdminProfile"
            component={AdminProfileScreen}
            options={{ title: 'Profil Ayarları' }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </>
  );
};

export default function App() {
  return (
    <ThemeProvider>
      <AppContent />
    </ThemeProvider>
  );
}
