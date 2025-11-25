import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { Colors } from '../../utils/colors';
import { useTheme } from '../../providers/ThemeProvider';
import { FirebaseService } from '../../services/PostgresService';
import { TahlilModel, createTahlilModel } from '../../models/TahlilModel';

const UserTahlilDetailScreen = () => {
  const route = useRoute();
  const { isDarkMode } = useTheme();
  const [tahlil, setTahlil] = useState<TahlilModel | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const { tahlilId } = route.params as { tahlilId: string };

  const theme = isDarkMode ? Colors.dark : Colors.light;

  useEffect(() => {
    loadTahlil();
  }, [tahlilId]);

  const loadTahlil = async () => {
    setIsLoading(true);
    try {
      const data = await FirebaseService.getTahlilById(tahlilId);
      if (data) {
        setTahlil(createTahlilModel(data));
      }
    } catch (error) {
      console.error('Load tahlil error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  if (!tahlil) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <Text style={[styles.errorText, { color: theme.text }]}>
          Tahlil bulunamadı
        </Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: theme.background }]}
      contentContainerStyle={styles.content}
    >
      <View style={[styles.card, { backgroundColor: theme.surface }]}>
        <Text style={[styles.title, { color: Colors.primary }]}>
          {tahlil.fullName}
        </Text>
        <View style={styles.infoRow}>
          <Text style={[styles.label, { color: theme.textSecondary }]}>TC Kimlik:</Text>
          <Text style={[styles.value, { color: theme.text }]}>{tahlil.tcNumber}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={[styles.label, { color: theme.textSecondary }]}>Yaş:</Text>
          <Text style={[styles.value, { color: theme.text }]}>{tahlil.age}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={[styles.label, { color: theme.textSecondary }]}>Cinsiyet:</Text>
          <Text style={[styles.value, { color: theme.text }]}>{tahlil.gender}</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={[styles.label, { color: theme.textSecondary }]}>Rapor Tarihi:</Text>
          <Text style={[styles.value, { color: theme.text }]}>{tahlil.reportDate}</Text>
        </View>
      </View>

      {tahlil.serumTypes.length > 0 && (
        <View style={[styles.card, { backgroundColor: theme.surface }]}>
          <Text style={[styles.sectionTitle, { color: Colors.primary }]}>
            Serum Değerleri
          </Text>
          {tahlil.serumTypes.map((serum, index) => (
            <View key={index} style={styles.serumRow}>
              <Text style={[styles.serumType, { color: theme.text }]}>
                {serum.type}:
              </Text>
              <Text style={[styles.serumValue, { color: theme.text }]}>
                {serum.value} mg/dl
              </Text>
            </View>
          ))}
        </View>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    padding: 16,
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
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  label: {
    fontSize: 14,
  },
  value: {
    fontSize: 16,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  serumRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: Colors.light.border,
  },
  serumType: {
    fontSize: 16,
    fontWeight: '600',
  },
  serumValue: {
    fontSize: 16,
  },
  errorText: {
    fontSize: 18,
    textAlign: 'center',
    marginTop: 40,
  },
});

export default UserTahlilDetailScreen;

