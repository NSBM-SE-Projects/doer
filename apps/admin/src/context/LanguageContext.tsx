import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { type LangCode, t as translate } from '../i18n/translations';

interface LanguageContextType {
  lang: LangCode;
  setLang: (lang: LangCode) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType>({
  lang: 'en',
  setLang: () => {},
  t: (key) => key,
});

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<LangCode>(() => {
    return (localStorage.getItem('admin_language') as LangCode) ?? 'en';
  });

  useEffect(() => {
    localStorage.setItem('admin_language', lang);
    // Set html lang attribute for accessibility
    document.documentElement.lang = lang;
  }, [lang]);

  const setLang = (newLang: LangCode) => setLangState(newLang);
  const t = (key: string) => translate(key, lang);

  return (
    <LanguageContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  return useContext(LanguageContext);
}
