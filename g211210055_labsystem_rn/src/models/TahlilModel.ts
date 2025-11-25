export interface SerumType {
  type: string;
  value: string;
}

export interface TahlilModel {
  id: string;
  fullName: string;
  tcNumber: string;
  birthDate?: Date | null;
  age: number;
  gender: string;
  patientType: string;
  sampleType: string;
  serumTypes: SerumType[];
  reportDate: string;
}

export const createTahlilModel = (data: any): TahlilModel => {
  return {
    id: data.id?.toString() || '',
    fullName: data.fullName || '',
    tcNumber: data.tcNumber || '',
    birthDate: data.birthDate ? new Date(data.birthDate) : null,
    age: data.age || 0,
    gender: data.gender || '',
    patientType: data.patientType || '',
    sampleType: data.sampleType || '',
    serumTypes: (data.serumTypes || []).map((s: any) => ({
      type: s.type || '',
      value: s.value || '',
    })),
    reportDate: data.reportDate || '',
  };
};

