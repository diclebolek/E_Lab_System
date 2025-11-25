import React from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../utils/colors';

interface AdminBottomNavBarProps {
  currentIndex: number;
  onTap: (index: number) => void;
}

const AdminBottomNavBar: React.FC<AdminBottomNavBarProps> = ({ currentIndex, onTap }) => {
  const navItems = [
    { icon: '➕', label: 'Kılavuz' },
    { icon: '📋', label: 'Kılavuzlar' },
    { icon: '🏠', label: 'Ana Sayfa' },
    { icon: '➕', label: 'Tahlil' },
    { icon: '📄', label: 'Tahliller' },
  ];

  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[Colors.primary, Colors.secondary]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        {navItems.map((item, index) => (
          <TouchableOpacity
            key={index}
            style={[styles.navItem, currentIndex === index && styles.navItemActive]}
            onPress={() => onTap(index)}
          >
            <Text style={[styles.navIcon, currentIndex === index && styles.navIconActive]}>
              {item.icon}
            </Text>
            <View style={[styles.indicator, currentIndex === index && styles.indicatorActive]} />
          </TouchableOpacity>
        ))}
      </LinearGradient>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 60,
    shadowColor: Colors.black,
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 10,
  },
  gradient: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },
  navItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    height: 50,
    marginHorizontal: 4,
    borderRadius: 12,
  },
  navItemActive: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  navIcon: {
    fontSize: 20,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  navIconActive: {
    fontSize: 22,
    color: Colors.white,
  },
  indicator: {
    width: 0,
    height: 3,
    borderRadius: 2,
    marginTop: 4,
  },
  indicatorActive: {
    width: 6,
    backgroundColor: Colors.white,
  },
});

export default AdminBottomNavBar;

