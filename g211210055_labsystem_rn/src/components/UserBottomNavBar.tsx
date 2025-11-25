import React from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../utils/colors';

interface UserBottomNavBarProps {
  currentIndex: number;
  onTap: (index: number) => void;
}

const UserBottomNavBar: React.FC<UserBottomNavBarProps> = ({ currentIndex, onTap }) => {
  return (
    <View style={styles.container}>
      <LinearGradient
        colors={[Colors.primary, Colors.secondary]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        <TouchableOpacity
          style={[styles.navItem, currentIndex === 0 && styles.navItemActive]}
          onPress={() => onTap(0)}
        >
          <Text style={[styles.navIcon, currentIndex === 0 && styles.navIconActive]}>
            📄
          </Text>
          <View style={[styles.indicator, currentIndex === 0 && styles.indicatorActive]} />
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.navItem, currentIndex === 1 && styles.navItemActive]}
          onPress={() => onTap(1)}
        >
          <Text style={[styles.navIcon, currentIndex === 1 && styles.navIconActive]}>
            👤
          </Text>
          <View style={[styles.indicator, currentIndex === 1 && styles.indicatorActive]} />
        </TouchableOpacity>
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
    fontSize: 24,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  navIconActive: {
    fontSize: 26,
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

export default UserBottomNavBar;

