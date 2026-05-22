"use client";

import { useState, useEffect, useCallback } from 'react';

export function usePersistentState<T>(
  key: string,
  defaultValue: T
): [T, (value: T | ((prev: T) => T)) => void] {
  // Initialize with default value first
  const [state, setState] = useState<T>(defaultValue);
  
  // Load from localStorage after mount
  useEffect(() => {
    try {
      const item = window.localStorage.getItem(key);
      if (item !== null) {
        setState(JSON.parse(item));
      }
    } catch (error) {
      console.error(`Error loading ${key} from localStorage:`, error);
    }
  }, [key]);
  
  // Save to localStorage when state changes
  const setPersistentState = useCallback((value: T | ((prev: T) => T)) => {
    setState(prev => {
      const newValue = typeof value === 'function' 
        ? (value as (prev: T) => T)(prev)
        : value;
      
      try {
        window.localStorage.setItem(key, JSON.stringify(newValue));
      } catch (error) {
        console.error(`Error saving ${key} to localStorage:`, error);
      }
      
      return newValue;
    });
  }, [key]);
  
  return [state, setPersistentState];
}
