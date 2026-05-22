"use client";

import { useEffect } from 'react';
import { usePersistentState } from './usePersistentState';

export type Theme = 'dark' | 'light';

function getInitialTheme(): Theme {
  if (typeof document === 'undefined') {
    return 'dark';
  }

  return document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
}

export function useTheme(): [Theme, () => void] {
  const [theme, setTheme] = usePersistentState<Theme>('ui.theme', getInitialTheme());

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'dark' ? 'light' : 'dark'));
  };

  return [theme, toggleTheme];
}
