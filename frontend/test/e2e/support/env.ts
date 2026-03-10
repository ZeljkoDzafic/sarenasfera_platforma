import fs from 'node:fs'
import path from 'node:path'

export function loadEnvFile(filePath: string): Record<string, string> {
  if (!fs.existsSync(filePath)) {
    return {}
  }

  const env: Record<string, string> = {}

  for (const rawLine of fs.readFileSync(filePath, 'utf8').split('\n')) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue

    const separatorIndex = line.indexOf('=')
    if (separatorIndex === -1) continue

    const key = line.slice(0, separatorIndex).trim()
    let value = line.slice(separatorIndex + 1).trim()

    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1)
    }

    env[key] = value
  }

  return env
}

export function loadWorkspaceEnv() {
  return loadEnvFile(path.resolve(__dirname, '../../../../.env'))
}
