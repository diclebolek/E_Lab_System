import axios from 'axios';
import { DatabaseConfig } from '../config/databaseConfig';

// Not: React Native'de direkt PostgreSQL bağlantısı yapamayız
// Bu yüzden bir backend API servisi gerekir
// Bu servis, backend API'ye HTTP istekleri gönderir

class PostgresService {
  private static apiBaseUrl = DatabaseConfig.apiBaseUrl;

  // Kullanıcı girişi (TC ile)
  static async signInWithTC(tc: string, password: string): Promise<any> {
    try {
      const response = await axios.post(`${this.apiBaseUrl}/auth/signin`, {
        tc: tc.trim(),
        password: password.trim(),
      });
      return response.data;
    } catch (error: any) {
      console.error('Sign in error:', error);
      return null;
    }
  }

  // Kullanıcı kaydı
  static async signUpWithTC(
    tc: string,
    password: string,
    options?: {
      fullName?: string;
      gender?: string;
      age?: number;
      birthDate?: Date;
      bloodType?: string;
      emergencyContact?: string;
    }
  ): Promise<any> {
    try {
      const response = await axios.post(`${this.apiBaseUrl}/auth/signup`, {
        tc: tc.trim(),
        password: password.trim(),
        ...options,
      });
      return response.data;
    } catch (error: any) {
      console.error('Sign up error:', error);
      return null;
    }
  }

  // Admin girişi (TC ile)
  static async signInAsAdmin(tc: string, password: string): Promise<boolean> {
    try {
      const response = await axios.post(`${this.apiBaseUrl}/auth/admin/signin`, {
        tc: tc.trim(),
        password: password.trim(),
      });
      return response.data.success === true;
    } catch (error: any) {
      console.error('Admin sign in error:', error);
      return false;
    }
  }

  // Tahlil ekleme
  static async addTahlil(tahlilData: any): Promise<boolean> {
    try {
      const response = await axios.post(`${this.apiBaseUrl}/tahliller`, tahlilData);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Add tahlil error:', error);
      return false;
    }
  }

  // Tahlilleri getir (TC'ye göre)
  static async getTahlillerByTC(tc: string): Promise<any[]> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/tahliller?tc=${tc}`);
      return response.data || [];
    } catch (error: any) {
      console.error('Get tahliller error:', error);
      return [];
    }
  }

  // Tahlil detayı
  static async getTahlilById(id: string): Promise<any | null> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/tahliller/${id}`);
      return response.data || null;
    } catch (error: any) {
      console.error('Get tahlil error:', error);
      return null;
    }
  }

  // Tahlil güncelleme
  static async updateTahlil(id: string, updates: any): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/tahliller/${id}`, updates);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update tahlil error:', error);
      return false;
    }
  }

  // Tahlil silme
  static async deleteTahlil(id: string): Promise<boolean> {
    try {
      const response = await axios.delete(`${this.apiBaseUrl}/tahliller/${id}`);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Delete tahlil error:', error);
      return false;
    }
  }

  // Kılavuz ekleme
  static async addGuide(guideName: string, data: any[]): Promise<boolean> {
    try {
      const response = await axios.post(`${this.apiBaseUrl}/kilavuzlar`, {
        guideName,
        data,
      });
      return response.data.success === true;
    } catch (error: any) {
      console.error('Add guide error:', error);
      return false;
    }
  }

  // Kılavuzları getir
  static async getGuides(): Promise<any[]> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/kilavuzlar`);
      return response.data || [];
    } catch (error: any) {
      console.error('Get guides error:', error);
      return [];
    }
  }

  // Kılavuz getir
  static async getGuide(guideName: string): Promise<any | null> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/kilavuzlar/${encodeURIComponent(guideName)}`);
      return response.data || null;
    } catch (error: any) {
      console.error('Get guide error:', error);
      return null;
    }
  }

  // Kılavuz güncelle
  static async updateGuide(guideName: string, data: any[], newGuideName?: string): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/kilavuzlar/${encodeURIComponent(guideName)}`, {
        data,
        newGuideName,
      });
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update guide error:', error);
      return false;
    }
  }

  // Kılavuz sil
  static async deleteGuide(guideName: string): Promise<boolean> {
    try {
      const response = await axios.delete(`${this.apiBaseUrl}/kilavuzlar/${encodeURIComponent(guideName)}`);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Delete guide error:', error);
      return false;
    }
  }

  // Şifre güncelleme
  static async updatePassword(newPassword: string): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/user/password`, {
        password: newPassword.trim(),
      });
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update password error:', error);
      return false;
    }
  }

  // Kullanıcı bilgilerini getir
  static async getUserInfo(): Promise<any | null> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/user/info`);
      return response.data || null;
    } catch (error: any) {
      console.error('Get user info error:', error);
      return null;
    }
  }

  // Kullanıcı bilgilerini güncelle
  static async updateUserInfo(options: {
    fullName?: string;
    birthDate?: Date;
    age?: number;
    gender?: string;
    bloodType?: string;
    emergencyContact?: string;
  }): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/user/info`, options);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update user info error:', error);
      return false;
    }
  }

  // Hesap silme
  static async deleteAccount(): Promise<boolean> {
    try {
      const response = await axios.delete(`${this.apiBaseUrl}/user/account`);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Delete account error:', error);
      return false;
    }
  }

  // Çıkış yap
  static async signOut(): Promise<void> {
    try {
      await axios.post(`${this.apiBaseUrl}/auth/signout`);
    } catch (error: any) {
      console.error('Sign out error:', error);
    }
  }

  // Tüm tahlilleri getir (admin için)
  static async getAllTahliller(): Promise<any[]> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/admin/tahliller`);
      return response.data || [];
    } catch (error: any) {
      console.error('Get all tahliller error:', error);
      return [];
    }
  }

  // Admin bilgilerini getir
  static async getAdminInfo(): Promise<any | null> {
    try {
      const response = await axios.get(`${this.apiBaseUrl}/admin/info`);
      return response.data || null;
    } catch (error: any) {
      console.error('Get admin info error:', error);
      return null;
    }
  }

  // Admin bilgilerini güncelle
  static async updateAdminInfo(options: {
    email?: string;
    fullName?: string;
    tcNumber?: string;
  }): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/admin/info`, options);
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update admin info error:', error);
      return false;
    }
  }

  // Admin şifresini güncelle
  static async updateAdminPassword(newPassword: string): Promise<boolean> {
    try {
      const response = await axios.put(`${this.apiBaseUrl}/admin/password`, {
        password: newPassword.trim(),
      });
      return response.data.success === true;
    } catch (error: any) {
      console.error('Update admin password error:', error);
      return false;
    }
  }
}

// FirebaseService için geriye dönük uyumluluk
export const FirebaseService = PostgresService;

export default PostgresService;

