import axios from 'axios'

const AUTH_URL = 'http://localhost:8001'
const WORKOUTS_URL = 'http://localhost:8002'
const ANALYTICS_URL = 'http://localhost:8003'

function makeClient(baseURL: string) {
  const client = axios.create({ baseURL })
  client.interceptors.request.use((config) => {
    const token = localStorage.getItem('access_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
  })
  return client
}

export const authClient = makeClient(AUTH_URL)
export const workoutsClient = makeClient(WORKOUTS_URL)
export const analyticsClient = makeClient(ANALYTICS_URL)
