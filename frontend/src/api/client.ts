import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? 'https://dev-api.cs686.live'

function makeClient(baseURL: string) {
  const client = axios.create({ baseURL })
  client.interceptors.request.use((config) => {
    const token = localStorage.getItem('access_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
  })
  return client
}

export const authClient = makeClient(API_BASE)
export const workoutsClient = makeClient(API_BASE)
export const analyticsClient = makeClient(API_BASE)
