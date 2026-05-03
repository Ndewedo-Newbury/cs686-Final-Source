import { authClient } from './client'

export interface AuthResponse {
  access_token: string
}

export const register = (email: string, password: string) =>
  authClient.post<AuthResponse>('/api/v1/auth/register', { email, password })

export const login = (email: string, password: string) =>
  authClient.post<AuthResponse>('/api/v1/auth/login', { email, password })

export const getMe = () =>
  authClient.get<{ user_id: string }>('/api/v1/auth/me')
