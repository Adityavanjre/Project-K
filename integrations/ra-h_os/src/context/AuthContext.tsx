"use client";

import { createContext, useContext, type ReactNode } from 'react';

interface AuthContextValue {
  status: 'unauthenticated';
  user: null;
  session: null;
  supabase: null;
  signIn: () => Promise<{ error: Error | null }>;
  signUp: () => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
}

const noopError = new Error('Authentication is not enabled in the open-source build.');

const AuthContext = createContext<AuthContextValue>({
  status: 'unauthenticated',
  user: null,
  session: null,
  supabase: null,
  signIn: async () => ({ error: noopError }),
  signUp: async () => ({ error: noopError }),
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  return <AuthContext.Provider value={useContext(AuthContext)}>{children}</AuthContext.Provider>;
}

export function useAuthContext(): AuthContextValue {
  return useContext(AuthContext);
}
