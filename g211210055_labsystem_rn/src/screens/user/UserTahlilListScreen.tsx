import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import { FirebaseService } from '../../services/PostgresService';
import { TahlilModel, createTahlilModel } from '../../models/TahlilModel';
import UserBottomNavBar from '../../components/UserBottomNavBar';

const UserTahlilListScreen = () => {
  const navigation = useNavigation();
  const { isDarkMode } = useTheme();
  const [tahliller, setTahliller] = useState<TahlilModel[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [userTC, setUserTC] = useState('');

  const theme = isDarkMode ? Colors.dark : Colors.light;

  useEffect(() => {
    loadUserTC();
  }, []);

  useEffect(() => {
    if (userTC) {
      loadTahliller();
    }
  }, [userTC]);

  const loadUserTC = async () => {
    const tc = await AsyncStorage.getItem('user_tc');
    setUserTC(tc || '');
  };

  const loadTahliller = async () => {
    if (!userTC) return;

    setIsLoading(true);
    try {
      const dataList = await FirebaseService.getTahlillerByTC(userTC);
      const tahlillerList: TahlilModel[] = [];

      for (const data of dataList) {
        const detail = await FirebaseService.getTahlilById(data.id || '');
        if (detail) {
          tahlillerList.push(createTahlilModel(detail));
        }
      }

      // Tarihe göre sırala (yeni -> eski)
      tahlillerList.sort((a, b) => {
        const dateA = parseDate(a.reportDate);
        const dateB = parseDate(b.reportDate);
        if (!dateA && !dateB) return 0;
        if (!dateA) return 1;
        if (!dateB) return -1;
        return dateB.getTime() - dateA.getTime();
      });

      setTahliller(tahlillerList);
    } catch (error) {
      console.error('Load tahliller error:', error);
    } finally {
      setIsLoading(false);
      setRefreshing(false);
    }
  };

  const parseDate = (dateStr: string): Date | null => {
    try {
      const parts = dateStr.split('/');
      if (parts.length >= 3) {
        return new Date(
          parseInt(parts[2]),
          parseInt(parts[1]) - 1,
          parseInt(parts[0])
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadTahliller();
  };

  const renderTahlilItem = ({ item }: { item: TahlilModel }) => (
    <TouchableOpacity
      style={[styles.card, { backgroundColor: theme.surface }]}
      onPress={() => navigation.navigate('UserTahlilDetail' as never, { tahlilId: item.id } as never)}
    >
      <View style={styles.cardHeader}>
        <View style={styles.iconContainer}>
          <Text style={styles.iconText}>📋</Text>
        </View>
        <View style={styles.cardContent}>
          <Text style={[styles.cardTitle, { color: Colors.primary }]}>
            {item.fullName}
          </Text>
          {item.patientType && (
            <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>
              {item.patientType}
            </Text>
          )}
          <Text style={[styles.cardDate, { color: theme.textSecondary }]}>
            📅 {item.reportDate}
          </Text>
        </View>
        <Text style={[styles.chevron, { color: Colors.primary }]}>›</Text>
      </View>
      {item.serumTypes.length > 0 && (
        <View style={styles.serumContainer}>
          {item.serumTypes.slice(0, 4).map((serum, index) => (
            <View key={index} style={styles.serumTag}>
              <Text style={styles.serumText}>
                {serum.type}: {serum.value}
              </Text>
            </View>
          ))}
          {item.serumTypes.length > 4 && (
            <Text style={[styles.moreText, { color: theme.textSecondary }]}>
              +{item.serumTypes.length - 4} daha
            </Text>
          )}
        </View>
      )}
    </TouchableOpacity>
  );

  if (isLoading && tahliller.length === 0) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <FlatList
        data={tahliller}
        renderItem={renderTahlilItem}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📄</Text>
            <Text style={[styles.emptyText, { color: theme.textSecondary }]}>
              Henüz tahlil bulunmamaktadır
            </Text>
          </View>
        }
      />
      <UserBottomNavBar
        currentIndex={0}
        onTap={(index) => {
          if (index === 1) {
            navigation.navigate('UserProfile' as never);
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
  listContent: {
    padding: 16,
    paddingBottom: 80,
  },
  card: {
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: Colors.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    width: 60,
    height: 60,
    borderRadius: 14,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  iconText: {
    fontSize: 28,
  },
  cardContent: {
    flex: 1,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 6,
  },
  cardSubtitle: {
    fontSize: 13,
    marginBottom: 4,
  },
  cardDate: {
    fontSize: 14,
  },
  chevron: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  serumContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 16,
    gap: 8,
  },
  serumTag: {
    backgroundColor: Colors.secondary + '20',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: Colors.secondary + '50',
  },
  serumText: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.primary,
  },
  moreText: {
    fontSize: 12,
    fontStyle: 'italic',
    alignSelf: 'center',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
  },
  emptyIcon: {
    fontSize: 80,
    marginBottom: 20,
  },
  emptyText: {
    fontSize: 18,
  },
});

export default UserTahlilListScreen;

